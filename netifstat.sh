#!/bin/bash

# ------------------------------------ #
#               FUNÇÕES                #
# ------------------------------------ #

# Valida, determina e guarda em variáveis as opções e argumentos passados ao script
function get_args() {

    # Por agora, a única opção considerada é "s"
    s=$1
}

# Recolhe e guarda em arrays os dados obtidos através do comando "ifconfig"
function get_data() {

    # Guarda output do comando ifconfig (WIP)
    data=$(ifconfig)

    names=$($data)
    echo $names
}

# Ordena os dados nos arrays de acordo com a ordenação escolhida
function sort_data() {

    return 0
}

# Imprime na consola a tabela formatada com os dados nos arrays
function print_table() {

    # Formato do cabeçalho
    header="%-8s %8s %8s %8s %8s"
    header_loop="%8s %8s"
    # Formato das linhas
    line="%-8s %8d %8d %8.1f %8.1f"
    line_loop="%8d %8d"

    # Imprime o cabeçalho
    printf "$header" "NETIF" "TX" "RX" "TRATE" "RRATE"
    [[ $loop -eq 1 ]] && printf " $header_loop" "TXTOT" "RXTOT"
    printf "\n"

    # Imprime as linhas
    for ((i = 0; i < ${#if_names[@]}; i++ )); do
        printf "$line" ${if_names[i]} ${if_TX[i]} ${if_RX[i]} ${if_TR[i]} ${if_RR[i]}
        [[ $loop -eq 1 ]] && printf " $line_loop" ${if_TXTOT[i]} ${if_RXTOT[i]}
        printf "\n"
    done   
}

# ------------------------------------ #
#                 MAIN                 #
# ------------------------------------ #

# Valores para testar print_table()
if_names=("eth0" "wlan" "lo")
if_TX=(123456 3223 456)
if_RX=(23456 904 234)
if_TR=(12345.6 322.3 45.6)
if_RR=(2345.6 23.4 90.4)
if_TXTOT=(123456 3223 456)
if_RXTOT=(23456 904 234)

loop=0

print_table 

exit 0
