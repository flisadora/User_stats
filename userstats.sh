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
        sessions=$(echo -n "$(last $filters | awk '{print $1}' | grep $i | wc -l) ") # conta o numero de sessoes
        echo $sessions
        if [ $sessions -ne 0 ]; then
            echo -n "$i "
            # seleciona coluna do tempo (array)
            if [ $soId -eq 0 ]; then
                time=($(last | grep $i | awk '{print $9}'))
                time=(${time[@]/"in"/})
            else
                time=($(last | grep $i | awk '{print $10}'))
                time=(${time[@]/"no"/})
            fi
            min=1000000000
            max=0
            timeSum=0
            for t in "${time[@]}"; do # percorre tempos de sessao, calcula tempo em minutos e determina tempo minimo e maximo
                hour=$(echo $t | sed 's/(//' | sed 's/)//' | cut -d ":" -f 1)
                min=$(echo $t | sed 's/(//' | sed 's/)//' | cut -d ":" -f 2)
                timeAux=$((10#$hour * 60 + 10#$min)) # 10# para quando operados tem zero a esquerda nao dar erro
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
    dateStr=$(echo $dateStr | sed 's/"//')
    dateStr=$(date -d "$dateStr" "+%Y-%m-%d %H:%M")
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
filters=""
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
        echo $dateStr
        echo $filters
        filters="$filters -s ${dateStr}"
        echo $filters
        ;;
    "-e")
        dateStr=${args[a + 1]}
        dateConversion
        echo $dateStr
        filters="$filters -t ${dateStr}"
        echo $filters
        ;;
    esac
done
len="${#filters}"
len=$((len-1))
last "${filters:1:$len}"
#last -t "$dateStr"

#countUsers
#detailSessions
