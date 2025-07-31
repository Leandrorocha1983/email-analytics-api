#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Uso: $0 <arquivo> [-desc]"
    exit 1
fi

INPUT_FILE="$1"
ORDER="asc"

if [ ! -f "$INPUT_FILE" ]; then
    echo "Erro: Arquivo '$INPUT_FILE' não encontrado."
    exit 1
fi

if [ "$2" = "-desc" ]; then
    ORDER="desc"
fi

if [ "$ORDER" = "asc" ]; then
    sort "$INPUT_FILE"
else
    sort -r "$INPUT_FILE"
fi
