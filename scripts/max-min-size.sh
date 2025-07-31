#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Uso: $0 <arquivo> [-min]"
    exit 1
fi

INPUT_FILE="$1"
MODE="max"

if [ ! -f "$INPUT_FILE" ]; then
    echo "Erro: Arquivo '$INPUT_FILE' não encontrado."
    exit 1
fi

if [ "$2" = "-min" ]; then
    MODE="min"
fi

if [ "$MODE" = "max" ]; then
    awk '{
        size_value = $NF
        if (size_value > max_size || max_size == "") {
            max_size = size_value
            max_record = $0
        }
    } END {
        print max_record
    }' "$INPUT_FILE"
else
    awk '{
        size_value = $NF
        if (size_value < min_size || min_size == "") {
            min_size = size_value
            min_record = $0
        }
    } END {
        print min_record
    }' "$INPUT_FILE"
fi
