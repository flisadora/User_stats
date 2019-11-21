#!/bin/bash

# Função para contar o numero de utilizadores
function countUsers() {
    if [ ! -z $group ]; then # Verifica se string $group não é vazia
        groupUsers=($(grep "$group:" /etc/group | cut -d ":" -f 4)) # Procura no ficheiro /etc/group os utilizadores que pertecem ao grupo
        IFS=',' read -r -a users <<<"$groupUsers"                   # Faz split da string groupUsers por ',' e cria array na var users
    else                   # Caso não haja filtragem por grupo, fazer lista dos utilizadores presentes no output do comando last
        if [ $soId -eq 0 ]; then
            users=($(last | awk '{print $1'} | sed 'N;$!P;$!D;$d' | sort -u))
        else
            users=($(last | awk '{print $1'} | head -n -2 | sort -u))
        fi
        # Remover os utilizadores da lista
        users=(${users[@]/"shutdown"/})
        users=(${users[@]/"reboot"/})
        users=(${users[@]/"root"/})
        users=(${users[@]/"_mbsetupuser"/})
    fi
    # Caso haja filtragem por grupo, remover utilizadores que não pertencem ao grupo da lista
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

# Função para contar o numero de sessoes para os utilizadores
function detailSessions() {
    for i in "${users[@]}"; do # para cada utilizador
        # seleciona coluna do tempo (array)
        if [ $soId -eq 0 ]; then
            time=($(last | grep $i | awk '{print $9}'))
            time=(${time[@]/"in"/})
        else
            if [ ${#dSince} -ne 0 ] && [ ${#dUntil} -ne 0 ]; then # filtragem pelo periodo temporal
                time=($(last -s "$dSince" -t "$dUntil" -f "$file" | grep $i | awk '{print $10}'))
            elif [ ${#dSince} -ne 0 ]; then
                time=($(last -s "$dSince" -f "$file" | grep $i | awk '{print $10}'))
            elif [ ${#dUntil} -ne 0 ]; then
                time=($(last -t "$dUntil" -f "$file" | grep $i | awk '{print $10}'))
            else
                time=($(last -f "$file" | grep $i | awk '{print $10}'))
            fi
            time=(${time[@]/"no"/})
        fi
        if [ ${#time[@]} -gt 0 ]; then # verifica se há registos para esse utilizador
            echo -n "$i "
            min=1000000000
            max=0
            timeSum=0
            for t in "${time[@]}"; do # percorre tempos de sessao, calcula tempo em minutos e determina tempo minimo e maximo
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
            echo "$timeSum $max $min"
        fi
    done
}

function dateConversion() {
    if [ $soId -eq 0 ]; then
        #IFS=' ' read -ra dateAux <<<"$dateStr"
        dateStr+=":00"
        dateStr=$(date -jf "%b %d %T" "$dateStr" "+%Y-%m-%d_%H:%M" | sed 's/_/ /')
    else
        dateStr=$(date -d "$dateStr" "+%Y-%m-%d %H:%M")
    fi
}

# main()

# Identifica qual SO esta a correr entre MAC->"Darwin" e Linux->"Linux"
if [ "$(uname)" == "Darwin" ]; then
    soId=0 # under Mac OS X platform
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    soId=1 # under GNU/Linux platform
fi

# processa argumentos
args=("$@")
group=""
regex=""
dSince=""
dUntil=""
file="/var/log/wtmp"
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
        ;;
    esac
done

countUsers
detailSessions
