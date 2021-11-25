#!/bin/bash

# Imprime a tabela com os dados
function print_table() {
    
    echo $1
    # Determina o cabeçalho da tabela
    if [[ $1 == "0" ]]; then
        echo lol
    else
        echo loli
    fi

    return 0
}

print_table $1

exit 0