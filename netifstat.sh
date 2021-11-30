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

    # Guarda o output do comando "ifconfig" num array cujas entradas correspondem a uma linha
    IFS=$'\n'
    data=($(ifconfig))
    IFS=""  # ISTO ESTRAGA PRINT E OU SORT!!

    if_names=($( printf "%s\n" ${data[@]} | grep ": " | cut -d: -f1 ))
    echo ${if_names[@]}
}

# Ordena os dados nos arrays de acordo com a ordenação escolhida
function sort_data() {

    indexes=()      # Array com os índices
    sort_data=()    # Array com os dados a serem ordenados
    sort_type=""    # Ordenação numérica geral ("g") ou alfabeticamente ("") e/ou inversa ("r")

    # Determina os dados a serem ordenados e a ordenação dos mesmos
    if [[ $sTX -eq 1 ]]; then   
        sort_data=(${if_TX[@]})         # TX
        sort_type="g"                   
    elif [[ $sRX -eq 1 ]]; then 
        sort_data=(${if_RX[@]})         # RX
        sort_type="g"
    elif [[ $sTR -eq 1 ]]; then 
        sort_data=(${if_TR[@]})         # TRATE
        sort_type="g"
    elif [[ $sRR -eq 1 ]]; then 
        sort_data=(${if_RR[@]})         # RRATE
        sort_type="g"
    else            
        sort_data=(${if_names[@]})      # NETIF
    fi
    [[ $sRev -eq 1 ]] && sort_type+="r" # Ordenação inversa

    # Determina os índices dos dados ordenados
    indexes=($( printf "%s\n" ${sort_data[@]} | nl -v0 | sort -$sort_type -k2 | cut -f1 ))

    # Ordena todos os arrays, utilizando arrays temporários e os índices descobertos
    if_names_copy=(${if_names[@]})
    if_TX_copy=(${if_TX[@]})
    if_RX_copy=(${if_RX[@]})
    if_TR_copy=(${if_TR[@]})
    if_RR_copy=(${if_RR[@]})
    if_TXTOT_copy=(${if_TXTOT[@]})
    if_RXTOT_copy=(${if_RXTOT[@]})

    for ((i = 0; i < ${#if_names[@]}; i++)); do
        if_names[i]=${if_names_copy[indexes[i]]}
        if_TX[i]=${if_TX_copy[indexes[i]]}
        if_RX[i]=${if_RX_copy[indexes[i]]}
        if_TR[i]=${if_TR_copy[indexes[i]]}
        if_RR[i]=${if_RR_copy[indexes[i]]}
        if_TXTOT[i]=${if_TXTOT_copy[indexes[i]]}
        if_RXTOT[i]=${if_RXTOT_copy[indexes[i]]}
    done
    
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
    for ((i = 0; i < ${#if_names[@]}; i++)); do
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

loop=1
sRev=1
sTX=0

get_data

sort_data

print_table

exit 0
