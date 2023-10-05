#!/bin/bash

_APISERVER=127.0.0.1:10085
_XRAY=/usr/local/bin/xray
REFRESH_INTERVAL=0.5 # Ubah interval sesuai anda mau

# Untuk mengambil statistik data dari Xray API
get_data_stats() {
    local ARGS=
    if [[ $1 == "reset" ]]; then
      ARGS="reset: false"
    fi
    $_XRAY api statsquery --server=$_APISERVER "${ARGS}" \
    | awk '{
        if (match($1, /"name":/)) {
            f=1; gsub(/^"|link"|,$/, "", $2);
            split($2, p,  ">>>");
            printf "%s:%s->%s\t", p[1],p[2],p[4];
        }
        else if (match($1, /"value":/) && f){
          f = 0;
          gsub(/"/, "", $2);
          printf "%.0f\n", $2;
        }
        else if (match($0, /}/) && f) { f = 0; print 0; }
    }'
}

print_sum() {
    local DATA="$1"
    local PREFIX="$2"
    local SORTED=$(echo "$DATA" | grep "^${PREFIX}" | sort -r)
    local SUM=$(echo "$SORTED" | awk '
        /->up/{us+=$2}
        /->down/{ds+=$2}
        END{
            printf "SUM->up:\t%.0f\nSUM->down:\t%.0f\nSUM->TOTAL:\t%.0f\n", us, ds, us+ds;
        }')
    echo -e "${SORTED}\n${SUM}" \
    | numfmt --field=2 --suffix=B --to=iec \
    | column -t
}

# untuk melakukan pelacakan data secara real-time
track_realtime_data() {
    while true; do
        clear
        DATA=$(get_data_stats)
        echo "------------Download----------"
        print_sum "$DATA" "inbound"
        echo "-----------------------------"
        echo "------------Upload----------"
        print_sum "$DATA" "outbound"
        echo "-----------------------------"
        echo
        echo "-------------Akun------------"
        print_sum "$DATA" "user"
        echo "-----------------------------"
        read -t $REFRESH_INTERVAL -n 1 -s -p "Tekan Enter untuk menuju ke menu"
        if [ $? = 0 ]; then
            break
        fi
    done
    clear
    menu
}

# Memulai pelacakan data secara real-time
track_realtime_data

                                                                                                       70,0-1        Bot
