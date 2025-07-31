#!/bin/bash

if [ $# -ne 3 ]; then
    echo "Uso: $0 <arquivo> <min_messages> <max_messages>"
    exit 1
fi

INPUT_FILE="$1"
MIN_MESSAGES="$2"
MAX_MESSAGES="$3"

if [ ! -f "$INPUT_FILE" ]; then
    echo "Erro: Arquivo '$INPUT_FILE' não encontrado."
    exit 1
fi

if ! [[ "$MIN_MESSAGES" =~ ^[0-9]+$ ]] || ! [[ "$MAX_MESSAGES" =~ ^[0-9]+$ ]]; then
    echo "Erro: Os valores de mensagens devem ser números inteiros."
    exit 1
fi

awk -v min="$MIN_MESSAGES" -v max="$MAX_MESSAGES" '{
    messages = $3 + 0
    if (messages >= min && messages <= max) {
        print $0
    }
}' "$INPUT_FILE" | sort
