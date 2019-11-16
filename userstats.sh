#!/bin/bash

# Função para contar o numero de utilizadores
function countUsers(){
    users=$( last | awk '{print $1'} | head -n -2 | sort u )
    for i in "${users[@]}"; do
        echo "$i" 
    done
}

countUsers

# Função para filtrar e visualizar o número de sessões de um utilizador
#function numberOfSessions(user){
#    last | awk
#}