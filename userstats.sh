#!/bin/bash

# Função para contar o numero de utilizadores
function countUsers() {
    if [ ! -z $group ]; then # Verifica se string $group nao e vazia
        groupUsers=($(grep "$group:" /etc/group | cut -d ":" -f 4)) # Procura no ficheiro /etc/group os utilizadores que pertecem ao grupo
        IFS=',' read -r -a users <<<"$groupUsers"                   # Faz split da string groupUsers por ',' e cria array na var users
    else                   # Caso nao haja filtragem por grupo, fazer lista dos utilizadores presentes no output do comando last
        if [ $soId -eq 0 ]; then # Percorrer utilizadores devolvidos pelo comando last e devolver array com estes sem repeticoes
            users=($(last -f "$file" | awk '{print $1}' | sed 'N;$!P;$!D;$d' | sort -u))
        else
            users=($(last -f "$file" | awk '{print $1}' | head -n -2 | sort -u))
        fi
        # Remover alguns utilizadores da lista
        users=(${users[@]/"shutdown"/})
        users=(${users[@]/"reboot"/})
        users=(${users[@]/"root"/})
        users=(${users[@]/"_mbsetupuser"/})
    fi
    # Caso haja filtragem por utilizadores, remover utilizadores que nao pertencem ao grupo da lista
    if [ ! -z $regex ]; then
        for i in $users; do
            case "$i" in
            $regex) ;;

            *)
                users=(${users[@]/"$i"/})
                ;;
            esac
        done
    fi
}

# Funcao para contar o numero de sessoes para os utilizadores
function detailSessions() {
    nSessions=0
    for i in "${users[@]}"; do # para cada utilizador
        # Selecionar coluna do tempo (array)
        if [ $soId -eq 0 ]; then # iOS
            time=($(last | grep $i | awk '{print $9}'))
            time=(${time[@]/"in"/})
        else # Linux
            if [ ${#dSince} -ne 0 ] && [ ${#dUntil} -ne 0 ]; then # Filtrar pelo periodo temporal
                time=($(last -s "$dSince" -t "$dUntil" -f "$file" | grep $i | awk '{print $10}'))
            elif [ ${#dSince} -ne 0 ]; then
                time=($(last -s "$dSince" -f "$file" | grep $i | awk '{print $10}'))
            elif [ ${#dUntil} -ne 0 ]; then
                time=($(last -t "$dUntil" -f "$file" | grep $i | awk '{print $10}'))
            else
                time=($(last -f "$file" | grep $i | awk '{print $10}'))
            fi
            time=(${time[@]/"no"/}) # Ignorar sessao atual (sem duracao atribuida)
            time=(${time[@]/"in"/})
            time=(${time[@]/"logged"/})
            time=(${time[@]/"down"/})
        fi
        if [ ${#time[@]} -gt 0 ]; then # Verificar se há registos para esse utilizador
            output+="$i"
            min=1000000000
            max=0
            timeSum=0
            for t in "${time[@]}"; do # Percorrer tempos de sessao, calcular tempo em minutos e determinar tempos minimo e maximo
                nSessions=$((nSessions + 1))
                hour=$(echo $t | sed 's/(//' | sed 's/)//' | cut -d ":" -f 1)
                minute=$(echo $t | sed 's/(//' | sed 's/)//' | cut -d ":" -f 2)
                timeAux=$((10#$hour * 60 + 10#$minute)) # 10# para quando operados tem zero a esquerda nao dar erro
                ((timeSum = $timeSum + $timeAux))
                if [ $timeAux -lt $min ]; then
                    ((min = $timeAux))
                fi
                if [ $timeAux -gt $max ]; then
                    ((max = $timeAux))
                fi
            done
            output+="\t$nSessions\t$timeSum\t$max\t$min\n"
        fi
    done
}

function dateConversion() {
    # Converter de data no formato "MES(3 primeiros caracteres) DD HH:MM" em "AAAA-MM-DD HH:MM"
    if [ $soId -eq 0 ]; then
        dateStr+=":00"
        dateStr=$(date -jf "%b %d %T" "$dateStr" "+%Y-%m-%d_%H:%M" | sed 's/_/ /')
    else
        dateStr=$(date -d "$dateStr" "+%Y-%m-%d %H:%M")
    fi
}

# main()

# Identificar qual SO esta a correr entre MAC->"Darwin" e Linux->"Linux"
if [ "$(uname)" == "Darwin" ]; then
    soId=0
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    soId=1
fi

# Inicializar as variaveis
args=("$@")
output=""
group=""
regex=""
dSince=""
dUntil=""
nSessions=0
file="/var/log/wtmp"
sortFilter=""

# Processar os argumentos
for ((a = 0; a < $#; a++)); do
    case ${args[a]} in
    "-g")
        group=${args[a + 1]}
        ;;
    "-u")
        regex=${args[a + 1]}
        ;;
    "-s")
        dateStr=${args[a + 1]}
        dateConversion
        dSince=$dateStr
        ;;
    "-e")
        dateStr=${args[a + 1]}
        dateConversion
        dUntil=$dateStr
        ;;
    "-f")
        file=${args[a + 1]}
        if [ ! -f $file ]; then
            echo "ERROR! The file $file does not exist!"
            exit
        fi
        ;;
    "-r")
        sortFilter+=" -r"
        ;;
    "-n")
        if [ ${#sortFilter} -le 9 ]; then
            sortFilter+=" -k2 -n"
        else
            echo "ERROR! Only one sort type accepted"
            exit
        fi
        ;;
    "-t")
        if [ ${#sortFilter} -le 9 ]; then
            sortFilter+=" -k3 -n"
        else
            echo "ERROR! Only one sort type accepted"
            exit
        fi
        ;;
    "-a")
        if [ ${#sortFilter} -le 9 ]; then
            sortFilter+=" -k4 -n"
        else
            echo "ERROR! Only one sort type accepted"
            exit
        fi
        ;;
    "-i")
        if [ ${#sortFilter} -le 9 ]; then
            sortFilter+=" -k5 -n"
        else
            echo "ERROR! Only one sort type accepted"
            exit
        fi
        ;;
    *) # Validacao das opcoes (se chegou aqui e comeca por "-" e porque e invalida)
        if [[ ${args[a]} == -* ]]; then
            echo "ERROR! ${args[a]} is not an option!"
            echo "The valid options are..."
            echo -e "\t-g <group>"
            echo -e "\t\tFilter by group"
            echo -e "\t-u <user>"
            echo -e "\t\tFilter by user"
            echo -e "\t-s <dateSince>"
            echo -e "\t\tGet data since a certain date"
            echo -e "\t\teg. \"Sep 19 10:00\""
            echo -e "\t-e <dateUntil>"
            echo -e "\t\tGet data until a certain date"
            echo -e "\t-f <file>"
            echo -e "\t\tGet data from a specific file"
            echo -e "\t-r"
            echo -e "\t\tSort the output in reverse order"
            echo -e "\t-n"
            echo -e "\t\tSort the output by number of sessions"
            echo -e "\t-t"
            echo -e "\t\tSort the output by total time"
            echo -e "\t-a"
            echo -e "\t\tSort the output by maximum time"
            echo -e "\t-i"
            echo -e "\t\tSort the output by minimum time"
            exit
        fi
        ;;
    esac
done

# Invocar as funcoes
countUsers
detailSessions

# Output
if [ ${#output} -gt 0 ]; then
    echo -e "${output::-2}" | sort $sortFilter
else
    echo "There is no data to show matching the given options."
fi
