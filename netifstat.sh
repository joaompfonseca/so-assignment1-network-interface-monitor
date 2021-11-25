#!/bin/bash

# ------------------------------------ #
#               FUNCOES                #
# ------------------------------------ #

# Determina as opções fornecidas
function get_args() {

    # Por agora, a unica opcao considerada e [T]
    T=$1
}

# Recolhe e organiza os dados das interfaces
function get_data() {

    # Guarda output do comando ifconfig (WIP)
    data=$(ifconfig | grep ": " | join)

    echo $data 
}

# Imprime a tabela com os dados
function print_table() {

    # Determina o cabecalho da tabela
    if [[ $1 == "0" ]]; then
        echo lol
    else
        echo loli
    fi

    return 0
}

# ------------------------------------ #
#                 MAIN                 #
# ------------------------------------ #

get_args $@

get_data

#sleep $T

#get_data

exit 0
