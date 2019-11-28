#!/bin/bash

# main()

# le primeiro ficheiro linha a linha
args=("$@")
if [ ${#args[@]} -lt 2 ]; then
  echo "ERROR! Usage: ./comparestats.sh <options> <file1> <file2>"
  echo "Options are not requised and should be writen before the files names!"
  exit
fi
file1=${args[$# - 2]}
file2=${args[$# - 1]}
# Validacao dos argumentos
if [ ! -f $file1 ]; then
  echo "ERROR! The file $file1 does not exist!"
  exit
fi
if [ ! -f $file2 ]; then
  echo "ERROR! The file $file2 does not exist!"
  exit
fi
userF1=()
userF2=()
usedUsers=()
output=""
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
  *) # Validacao das opcoes (se chegou aqui e comeca por "-" e porque e invalida)
    if [[ ${args[a]} == -* ]]; then
      echo "ERROR! ${args[a]} is not an option!"
      echo "The valid options are..."
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

# Output
if [ ${#output} -gt 0 ]; then
  echo -e "${output::-2}" | sort $sortFilter
else
  echo "There is no data to show matching the given options."
fi
