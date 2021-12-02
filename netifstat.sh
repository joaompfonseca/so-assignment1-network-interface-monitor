#!/bin/bash

# ------------------------------------ #
#               FUNÇÕES                #
# ------------------------------------ #

# Determina, valida e guarda em variáveis as opções e argumentos passados ao script
function get_args() {

    # Deve ser fornecido pelo menos um argumento, o período de amostragem
    [[ $# -lt 1 ]] && throw_error 10

    # time - período de amostragem
    for time; do :; done
    # $time deve ser um inteiro maior que do que zero
    ! [[ $time =~ ^0*[1-9][0-9]*$ ]] && throw_error 11 "$time"

    while getopts "c:bklmp:RrTtv" op; do
        case ${op} in
        c) # if_filter

            # $if_filter não pode ser o último argumento (período de amostragem)
            [[ $(($OPTIND - 1)) -eq $# ]] && throw_error 12
            # $if_filter não pode ser uma opção do script
            [[ $OPTARG =~ ^-[cbklmpRrTtv]$ ]] && throw_error 13 "$OPTARG"

            if_filter=$OPTARG
            ;;
        b) # b
            # $kb e $mb têm de ser 0
            b=1
            kb=0
            mb=0
            ;;
        k) # kb
            # $b e $mb têm de ser 0
            b=0
            kb=1
            mb=0
            ;;
        l) # loop
            loop=1
            ;;
        m) # mb
            # $b e $kb têm de ser 0
            b=0
            kb=0
            mb=1
            ;;
        p) # if_nMax

            # $if_nMax não pode ser o último argumento (período de amostragem)
            [[ $(($OPTIND - 1)) -eq $# ]] && throw_error 12
            # $if_nMax deve ser um inteiro maior que do que zero
            ! [[ $OPTARG =~ ^0*[1-9][0-9]*$ ]] && throw_error 14 "$OPTARG"

            if_nMax=$OPTARG
            ;;
        R) # sRR
            # $sTX, $sRX e $sTR têm de ser 0
            sTX=0
            sRX=0
            sTR=0
            sRR=1
            ;;
        r) # sRX
            # $sTX, $sTR e $sRR têm de ser 0
            sTX=0
            sRX=1
            sTR=0
            sRR=0
            ;;
        T) # sTR
            # $sTX, $sRX e sRR têm de ser 0
            sTX=0
            sRX=0
            sTR=1
            sRR=0
            ;;
        t) # sTX
            # $sRX, $sTR e sRR têm de ser 0
            sTX=1
            sRX=0
            sTR=0
            sRR=0
            ;;
        v) # sRev
            sRev=1
            ;;
        esac
    done

    return 0
}

# Recolhe e guarda em arrays os dados obtidos através do comando "ifconfig"
function get_data() {

    # Recolhe o output do comando "ifconfig" num array cujas entradas correspondem a uma linha
    IFS=$'\n'
    data=($(ifconfig -a | awk '$1=$1'))
    unset IFS

    # Guarda os dados pretendidos em arrays
    if_names=($(printf "%s\n" "${data[@]}" | grep ": " | cut -d: -f1))
    if_TX=($(printf "%s\n" "${data[@]}" | grep "TX.*bytes" | cut -d" " -f5))
    if_RX=($(printf "%s\n" "${data[@]}" | grep "RX.*bytes" | cut -d" " -f5))

    # Não existem interfaces
    [[ ${#if_names[@]} -eq 0 ]] && throw_error 20

    # Validação do filtro das interfaces
    (for int in ${if_names[@]}; do
        [[ $int =~ $if_filter ]] && break
    done) || throw_error 21 "$if_filter" # Nenhuma interface passou no filtro

    # Determina o número máximo de interfaces a apresentar
    [[ $if_nMax -eq 0 || $if_nMax -gt ${#if_names[@]} ]] && if_nMax=${#if_names[@]}

    return 0
}

# Ordena os dados nos arrays de acordo com a ordenação escolhida
function sort_data() {

    indexes=()   # Array com os índices
    sort_data=() # Array com os dados a serem ordenados
    sort_type="" # Ordenação numérica geral ("g") ou alfabeticamente ("") e/ou inversa ("r")

    # Determina os dados a serem ordenados e a ordenação dos mesmos
    if [[ $sTX -eq 1 ]]; then
        sort_data=(${if_TX[@]}) # TX
        sort_type="g"
    elif [[ $sRX -eq 1 ]]; then
        sort_data=(${if_RX[@]}) # RX
        sort_type="g"
    elif [[ $sTR -eq 1 ]]; then
        sort_data=(${if_TR[@]}) # TRATE
        sort_type="g"
    elif [[ $sRR -eq 1 ]]; then
        sort_data=(${if_RR[@]}) # RRATE
        sort_type="g"
    else
        sort_data=(${if_names[@]}) # NETIF
    fi
    [[ $sRev -eq 1 ]] && sort_type+="r" # Ordenação inversa

    # Determina os índices dos dados ordenados
    indexes=($(printf "%s\n" "${sort_data[@]}" | nl -v0 | sort -$sort_type -k2 | cut -f1))

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
    header="%-10s %8s %8s %8s %8s"
    header_loop="%8s %8s"
    # Formato das linhas
    line=$([[ $b -eq 1 ]] && echo "%-10s %8d %8d %8.1f %8.1f" || echo "%-10s %8.1f %8.1f %8.1f %8.1f")
    line_loop=$([[ $b -eq 1 ]] && echo "%8d %8d" || echo "%8.1f %8.1f")

    # Conversão dos dados de bytes para kilobytes ou megabytes, especificado nos argumentos
    conv=$(($kb * 1024 + $mb * 1024 * 1024))
    for ((i = 0; i < ${#if_names[@]}; i++)); do
        if_TX_conv[i]=$([[ $b -eq 1 ]] && echo ${if_TX[i]} || echo ${if_TX[i]} / $conv | bc -l)
        if_RX_conv[i]=$([[ $b -eq 1 ]] && echo ${if_RX[i]} || echo ${if_RX[i]} / $conv | bc -l)
        if_TR_conv[i]=$([[ $b -eq 1 ]] && echo ${if_TR[i]} || echo ${if_TR[i]} / $conv | bc -l)
        if_RR_conv[i]=$([[ $b -eq 1 ]] && echo ${if_RR[i]} || echo ${if_RR[i]} / $conv | bc -l)
        if_TXTOT_conv[i]=$([[ $b -eq 1 ]] && echo ${if_TXTOT[i]} || echo ${if_TXTOT[i]} / $conv | bc -l)
        if_RXTOT_conv[i]=$([[ $b -eq 1 ]] && echo ${if_RXTOT[i]} || echo ${if_RXTOT[i]} / $conv | bc -l)
    done

    # Imprime o cabeçalho
    [[ $cycle -eq 0 ]] && printf "$header" "NETIF" "TX" "RX" "TRATE" "RRATE"
    [[ $cycle -eq 0 && $loop -eq 1 ]] && printf " $header_loop" "TXTOT" "RXTOT"
    printf "\n"

    # i - itera pelas interfaces; if_n - número de interfaces impressas
    for ((i = 0, if_n = 0; i < ${#if_names[@]} && if_n < $if_nMax; i++)); do

        # Filtragem da interface
        ! [[ ${if_names[i]} =~ $if_filter ]] && continue || ((if_n++))

        # Imprime a linha
        printf "$line" "${if_names[i]}" ${if_TX_conv[i]} ${if_RX_conv[i]} ${if_TR_conv[i]} ${if_RR_conv[i]}
        [[ $loop -eq 1 ]] && printf " $line_loop" ${if_TXTOT_conv[i]} ${if_RXTOT_conv[i]}
        printf "\n"
    done

    return 0
}

# Termina o programa com erro, imprime a causa na consola e retorna o valor de saída correspondente
# $1 - código do erro
# $2 - dado que causou o erro (opcional)
function throw_error() {

    case $1 in
    1*)
        printf "erro de argumentos [código %d]: " $1
        [[ $1 -eq 10 ]] && printf "deve ser fornecido o período de amostragem"
        [[ $1 -eq 11 ]] && printf "%s: período de amostragem deve ser um inteiro maior do que zero" $2
        [[ $1 -eq 12 ]] && printf "o último argumento deve ser o período de amostragem"
        [[ $1 -eq 13 ]] && printf "%s: filtro não pode ser uma opção do script" $2
        [[ $1 -eq 14 ]] && printf "%s: número de interfaces deve ser um inteiro maior do que zero" $2
        ;;
    2*)
        printf "erro de execução [código %d]: " $1
        [[ $1 -eq 20 ]] && printf "nenhuma interface foi detetada no sistema"
        [[ $1 -eq 21 ]] && printf "%s: filtro não encontrou nenhuma interface válida" $2
        ;;
    esac
    printf "\n"

    exit $1
}

# ------------------------------------ #
#                 MAIN                 #
# ------------------------------------ #

# Inicialização das variáveis com os valores por defeito
time=0 # É argumento obrigatório do script, logo é definido na função get_args()

b=1
if_filter=".*"
if_nMax=0 # Depende do número de interfaces, logo é definido na função get_data()
kb=0
loop=0
mb=0
sTX=0
sRX=0
sTR=0
sRR=0
sRev=0

if_names=() #("eth0" "wlan" "lo")
if_TX=()    #(123456 3223 456)
if_RX=()    #(23456 904 234)
if_TR=()    #(12345.6 322.3 45.6)
if_RR=()    #(2345.6 23.4 90.4)
if_TXTOT=() #(123456 3223 456)
if_RXTOT=() #(23456 904 234)

get_args $@

# Fluxo de execução principal
cycle=0
while true; do

    # 1ª recolha
    get_data
    if_TX_prev=(${if_TX[@]})
    if_RX_prev=(${if_RX[@]})

    # Tempo entre recolhas
    sleep $time

    # 2ª recolha
    get_data
    if_TX_curr=(${if_TX[@]})
    if_RX_curr=(${if_RX[@]})

    # Cálculo dos valores
    for ((i = 0; i < ${#if_names[@]}; i++)); do
        if_TX[i]=$((${if_TX_curr[i]} - ${if_TX_prev[i]}))
        if_RX[i]=$((${if_RX_curr[i]} - ${if_RX_prev[i]}))
        if_TR[i]=$(echo ${if_TX[i]} / $time | bc -l)
        if_RR[i]=$(echo ${if_RX[i]} / $time | bc -l)
        if_TXTOT[i]=$((${if_TXTOT[i]} + ${if_TX[i]}))
        if_RXTOT[i]=$((${if_RXTOT[i]} + ${if_RX[i]}))
    done

    sort_data

    print_table

    # Execução em loop
    [[ $loop -eq 0 ]] && break || ((cycle++))
done

exit 0