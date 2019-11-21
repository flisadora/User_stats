#!/bin/bash

# main()

# le primeiro ficheiro linha a linha
input=$1
while IFS= read -r line
do
  echo "$line"
done < "$input"