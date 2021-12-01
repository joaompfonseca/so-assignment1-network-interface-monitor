#!/bin/bash

# ------------------------------------ #
#               FUNÇÕES                #
# ------------------------------------ #

# Determina, valida e guarda em variáveis as opções e argumentos passados ao script
function get_args() {
    
    if ! [[ "${!#}" =~ ^[0-9]*.[0-9]*$ ]]; then
        echo Definição do período temporal inválida! Tem que definir um tempo máximo.\(s\).
        exit
    else
        echo A validar os argumentos...

        if_filter=.*
        b=1
        kb=0
        mb=0
        if_nMax=0
        sTX=0
        sRX=0
        sTR=0
        sRR=0
        sRev=0
        loop=0
        while getopts "c:bkmp:trTRvl" option; do
            case ${option} in
            c) #For option c
                if_filter=$OPTARG
                ;;
            b) #For option b
                b=0
                if [ ! -k ] | [ ! -m ]; then
                    b=1
                    exit 0
                fi
                ;;
            k) #For option k
                kb=1
                if [ ! -m ]; then
                    kb=0
                    exit 0
                fi
                ;;
            m) #For option m
                mb=1
                ;;
            p) #For option p
                if ! [[ "$OPTARG" =~ ^[1-9]+$ ]]; then
                    echo "A opção -p deverá ser um inteiro maior que 0!"
                    if_nMax=$OPTARG
                    exit 0
                fi
                ;;
            t) #For option t
                sTX=1
                if ! [ -r ] | [ ! -T ] | [ ! -R ]; then
                    sTX=0
                    exit 0

                fi
                ;;
            r) #For option r
                sRX=1
                if [ ! -T ] | [ ! -R ]; then
                    sRX=0
                    exit 0
                fi
                ;;
            T) #For option T
                sTR=1
                if [ ! -R ]; then
                    sTR=0
                    exit 0
                fi
                ;;
            R) #For option R
                sRR=1 ;;
            v) #For option v
                sRev=1 ;;
            l) #For option l
                loop=1 ;;
            esac
        done

    fi

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
        if_TX_conv[i]=$([[ $b -eq 1 ]] && echo ${if_RX[i]} || echo ${if_TX[i]} / $conv | bc -l)
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
# $2 - dado que causou o erro
function throw_error() {

    case $1 in
    1*)
        printf "erro de argumentos [$1]: "
        ;;
    2*)
        printf "erro de execução [$1]: "
        [[ $1 -eq 20 ]] && printf "nenhuma interface foi detetada no sistema"
        [[ $1 -eq 21 ]] && printf "$2: o filtro fornecido não encontrou nenhuma interface válida"
        ;;
    esac
    printf "\n"

    exit $1
}

# ------------------------------------ #
#                 MAIN                 #
# ------------------------------------ #

# Inicialização das variáveis com os valores por defeito
if_filter=".*"
if_nMax=0 # Depende do número de interfaces, logo é definido na função get_data()
b=1
kb=0
mb=0
sTX=0
sRX=0
sTR=0
sRR=0
sRev=0
loop=0
time=0

if_names=() #("eth0" "wlan" "lo")
if_TX=() #(123456 3223 456)
if_RX=() #(23456 904 234)
if_TR=() #(12345.6 322.3 45.6)
if_RR=() #(2345.6 23.4 90.4)
if_TXTOT=() #(123456 3223 456)
if_RXTOT=() #(23456 904 234)

get_args

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
