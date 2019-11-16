<<<<<<< Updated upstream
#!/bin/bash
=======

# Função para contar o numero de utilizadores
function countUsers(){
    if [ $soId -eq 0 ]; then
        users=($( last | awk '{print $1'} | sed 'N;$!P;$!D;$d' | sort -u ))
    else
        users=($( last | awk '{print $1'} | head -n -2 | sort -u ))
    fi
    users=(${users[@]/"shutdown"})
    users=(${users[@]/"reboot"})
    users=(${users[@]/"root"})
    users=(${users[@]/"_mbsetupuser"})
}

# Função para contar o numero de sessoes para os utilizadores
function detailSessions(){
    for i in "${users[@]}"; do # para cada utilizador
        echo -n $i
        echo -n "$(last | awk '{print $1}' | grep $i | wc -l) " # conta o numero de sessoes
        # seleciona coluna do tempo
        if [ $soId -eq 0 ]; then
            time=($(last | grep $i | awk '{print $9}'))
            time=(${time[@]/"in"})
        else
            time=($(last | grep $i | awk '{print $10}'))
            time=(${time[@]/"no"})
        fi
        min=1000000000
        max=0
        timeSum=0
        for t in "${time[@]}"; do
            hour=$(echo $t | sed 's/(//' | sed 's/)//' | cut -d ":" -f 1)
            min=$(echo $t | sed 's/(//' | sed 's/)//' | cut -d ":" -f 2)
            timeAux=$(($hour*60+$min))
            ((timeSum=$timeSum+$timeAux))
            if [ $timeAux -lt $min ]; then
                ((min=$timeAux))
            fi
            if [ $timeAux -gt $max ]; then
                ((max=$timeAux))
            fi            
        done
        echo "$timeSum $max $min"
    done
}

# main()

# Identifica qual SO esta a correr entre MAC->"Darwin" e Linux->"Linux"
if [ "$(uname)" == "Darwin" ]; then
    soId=0 # under Mac OS X platform        
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    soId=1 # under GNU/Linux platform
fi
countUsers
detailSessions

