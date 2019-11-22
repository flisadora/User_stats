#!/bin/bash

# main()

# le primeiro ficheiro linha a linha
file1=$1
file2=$2
userF1=()
userF2=()
usedUsers=()
output=""
args=("$@")
while IFS= read -r line; do
  if [ ! -z "$line" ]; then
    userF1=($(echo $line))
    output+="$userF1\t"
    userF2=($(cat $file2 | grep "$userF1"))
    if [ ${#userF2[@]} -ne 0 ]; then
      output+="$((${userF1[1]} - ${userF2[1]}))\t" # faz a diferenca do numero de sessoes
      output+="$((${userF1[2]} - ${userF2[2]}))\t" # faz a diferenca do do tempo total
      output+="$((${userF1[3]} - ${userF2[3]}))\t" # faz a diferenca do do tempo maximo
      output+="$((${userF1[4]} - ${userF2[4]}))\n" # faz a diferenca do do tempo minimo
      usedUsers+=($userF1)
    else
      output+="${userF1[1]}\t${userF1[2]}\t${userF1[3]}\t${userF1[4]}\n"
    fi
  fi
done <"$file1"

while IFS= read -r line; do
  if [ ! -z "$line" ]; then
    userF2=($(echo $line))
    if [[ ! ${usedUsers[*]} =~ $userF2 ]]; then # verifica se o usuario esta no ficheiro 2 e nao estava no ficheiro 1
      output+="${userF2[0]}\t$((-${userF2[1]}))\t$((-${userF2[2]}))\t$((-${userF2[3]}))\t$((-${userF2[4]}))\n"
    fi
  fi
done <"$file2"

# Processar os argumentos
for ((a = 0; a < $#; a++)); do
    case ${args[a]} in
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
    esac
done

# Output
echo -e "${output::-2}" | sort $sortFilter