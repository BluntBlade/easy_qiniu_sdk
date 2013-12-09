#!/bin/bash

##############################################################################
#
# Easy Qiniu Bash SDK
#
# Module: sha1.sh
#
# Author: LIANG Tao
# Weibo:  @无锋之刃
# Email:  liangtao@qiniu.com
#         amethyst.black@gmail.com
#
# Wiki:   http://en.wikipedia.org/wiki/SHA-1
#
##############################################################################

QNC_SHA1_HEX=""

__QNC_SHA1_CHUNK_SIZE=64
__QNC_SHA1_INIT_HASH="67452301 EFCDAB89 98BADCFE 10325476 C3D2E1F0 "
__QNC_SHA1_MSG_PADDING="80 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  "
__QNC_SHA1_ZERO_PADDING="00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 "

function __qnc_sha1_left_rotate {
    local val=$1
    local bits=$2
    shift 2

    ret=$(( ( (${val} << ${bits}) & 0xFFFFFFFF ) | ( ${val} >> (32 - $bits) ) ))
    echo -n "${ret}"
    return 0
} # __qnc_sha1_left_rotate

function __qnc_sha1_mod_add {
    local sum=0
    for n in "$@"; do
        sum=$(( (${sum} + $n) & 0xFFFFFFFF ))
    done
    echo -n "${sum}"
    return 0
} # __qnc_sha1_mod_add

function __qnc_sha1_bytes2integers {
    local msg=($1)
    for (( i0 = 0; i0 < ${__QNC_SHA1_CHUNK_SIZE}; i0 += 4 )); do
        local i1=$(( $i0 + 1 ))
        local i2=$(( $i0 + 2 ))
        local i3=$(( $i0 + 3 ))
        echo -n "0x${msg[$i0]}${msg[$i1]}${msg[$i2]}${msg[$i3]} "
    done
    return 0
} # __qnc_sha1_bytes2integers

function __qnc_sha1_integers2bytes {
    local ints=($1)
    for (( i = ${#ints[@]}; i >= 0; i -= 1)); do
        local int=${ints[$i]}
        echo -n "${int:0:2} ${int:2:2} ${int:4:2} ${int:6:2} "
    done
    return 0
} # __qnc_sha1_integers2bytes

function __qnc_sha1_count_bits {
    local byte_cnt=$1
    local bit_len=($2)
    local bit_cnt=$(( $byte_cnt * 8 ))
    local tmp=$(( 0x${bit_len[0]} + ${bit_cnt} ))
    bit_len[0]=$(( ${tmp} & 0xFFFFFFFF ))
    bit_len[1]=$(( (${tmp} >> 32) & 0xFFFFFFFF ))
    printf "%08x %08x " "${bit_len[@]}"
    return 0
} # __qnc_sha1_count_bits

function __qnc_sha1_calc {
    local hash=($1)
    local w=($(__qnc_sha1_bytes2integers "$2"))
    shift 2

    for (( i = 16; i < 80; i += 1 )); do
        local n1=$(( $i - 3 ))
        local n2=$(( $i - 8 ))
        local n3=$(( $i - 14 ))
        local n4=$(( $i - 16 ))
        local tmp=$(( ${w[$n1]} ^ ${w[$n2]} ^ ${w[$n3]} ^ ${w[$n4]} ))
        w[$i]=$(__qnc_sha1_left_rotate "${tmp}" 1)
    done

    local a=$(( 0 + 0x${hash[0]} ))
    local b=$(( 0 + 0x${hash[1]} ))
    local c=$(( 0 + 0x${hash[2]} ))
    local d=$(( 0 + 0x${hash[3]} ))
    local e=$(( 0 + 0x${hash[4]} ))

    local f=0
    local k=0

    k=$(( 0 + 0x5A827999 ))
    for ((i = 0; i <= 19; i += 1)); do
        f=$(( ($b & $c) | ( ( (~$b) & 0xFFFFFFFF ) & $d ) ))

        local tmp="$(__qnc_sha1_mod_add $(__qnc_sha1_left_rotate "$a" 5) "$f" "$e" "$k" "${w[$i]}")"
        e="$d"
        d="$c"
        c="$(__qnc_sha1_left_rotate "$b" 30)"
        b="$a"
        a="${tmp}"
    done # for

    k=$(( 0 + 0x6ED9EBA1 ))
    for ((i = 20; i <= 39; i += 1)); do
        f=$(( $b ^ $c ^ $d ))

        local tmp="$(__qnc_sha1_mod_add $(__qnc_sha1_left_rotate "$a" 5) "$f" "$e" "$k" "${w[$i]}")"
        e="$d"
        d="$c"
        c="$(__qnc_sha1_left_rotate "$b" 30)"
        b="$a"
        a="${tmp}"
    done # for

    k=$(( 0 + 0x8F1BBCDC ))
    for ((i = 40; i <= 59; i += 1)); do
        f=$(( ($b & $c) | ($b & $d) | ($c & $d) ))

        local tmp="$(__qnc_sha1_mod_add $(__qnc_sha1_left_rotate "$a" 5) "$f" "$e" "$k" "${w[$i]}")"
        e="$d"
        d="$c"
        c="$(__qnc_sha1_left_rotate "$b" 30)"
        b="$a"
        a="${tmp}"
    done # for

    k=$(( 0 + 0xCA62C1D6 ))
    for ((i = 60; i <= 79; i += 1)); do
        f=$(( $b ^ $c ^ $d ))

        local tmp="$(__qnc_sha1_mod_add $(__qnc_sha1_left_rotate "$a" 5) "$f" "$e" "$k" "${w[$i]}")"
        e="$d"
        d="$c"
        c="$(__qnc_sha1_left_rotate "$b" 30)"
        b="$a"
        a="${tmp}"
    done # for

    hash[0]=$(__qnc_sha1_mod_add "0x${hash[0]}" "$a")
    hash[1]=$(__qnc_sha1_mod_add "0x${hash[1]}" "$b")
    hash[2]=$(__qnc_sha1_mod_add "0x${hash[2]}" "$c")
    hash[3]=$(__qnc_sha1_mod_add "0x${hash[3]}" "$d")
    hash[4]=$(__qnc_sha1_mod_add "0x${hash[4]}" "$e")

    printf "%08x %08x %08x %08x %08x " "${hash[@]}"
    return 0
} # __qnc_sha1_calc

function __qnc_sha1_calc_msg {
    local ctx=$1
    local end=$2
    shift 2

    local hash="${ctx:0:45}"
    local bit_len="${ctx:45:18}"
    local remainder="${ctx:63}"

    while read msg; do
        msg=${msg}
        if [[ "${#msg}" -eq 0 ]]; then
            break
        fi

        remainder="${remainder}${msg} "
        if [[ "${#remainder}" -lt 192 ]]; then
            continue
        fi

        hash=$(__qnc_sha1_calc "${hash}" "${remainder:0:192}")

        bit_len=$(__qnc_sha1_count_bits "${__QNC_SHA1_CHUNK_SIZE}" "${bit_len}")
        remainder="${remainder:192}"
    done

    ### when reach here, remainder is holding the remainder of the message, with one trailling space
    if [[ -z "${end}" ]]; then
        ### not a sum invocation
        printf "%s%08x %08x %s" "${hash}" "${bit_len}" "${remainder}"
        return
    fi

    local remainder_len=$(( ${#remainder} / 3 ))
    bit_len=$(__qnc_sha1_count_bits "${remainder_len}" "${bit_len}")

    remainder="${remainder}${__QNC_SHA1_MSG_PADDING}"
    if [[ ${__QNC_SHA1_CHUNK_SIZE} -lt $(( ${remainder_len} + 1 + 8 )) ]]; then
        hash=$(__qnc_sha1_calc "${hash}" "${remainder:0:192}")
        remainder="${__QNC_SHA1_ZERO_PADDING}"
    else
        remainder="${remainder:0:168}"
    fi

    remainder="${remainder}$(__qnc_sha1_integers2bytes "${bit_len}")"
    hash=$(__qnc_sha1_calc "${hash}" "${remainder}")

    if [[ "${#QNC_SHA1_HEX}" -eq 0 ]]; then
        echo -n "${hash[@]}" | tr -d ' ' | perl -ne 'print pack("H*", $_);'
    else
        echo -n "${hash[@]}" | tr -d ' '
    fi
    return 0
} # __qnc_sha1_calc_msg

function __qnc_sha1_calc_msg_wrapper {
    local arg_cnt=$#

    local end=$1
    local ctx=$2
    local msg=$3
    shift 3

    local cmd=""
    if [[ "${arg_cnt}" -eq 2 ]]; then
        cmd="cat"
    else
        cmd="echo -n \"${msg}\""
    fi

    eval $cmd                                | \
    od -v -tx1 -An                           | \
    __qnc_sha1_calc_msg "${ctx}" "${end}"
    return 0
} # __qnc_sha1_calc_msg_wrapper

function qnc_sha1_new {
    echo -n "${__QNC_SHA1_INIT_HASH}00000000 00000000 "
    return 0
} # qnc_sha1_new

function qnc_sha1_write {
    __qnc_sha1_calc_msg_wrapper "" "$@"
} # qnc_sha1_write

function qnc_sha1_sum {
    __qnc_sha1_calc_msg_wrapper "END" "$@"
} # qnc_sha1_sum

function qnc_sha1 {
    local ctx=""
    ctx=$(qnc_sha1_new)
    qnc_sha1_sum "${ctx}" "$@"
} # qnc_sha1

###printf "%08x\n" $(__qnc_sha1_left_rotate "0x99990000" 16)
###printf "%08x\n" $(__qnc_sha1_mod_add "0xFFFF0000" "0x00012345")
###ctx=$(qnc_sha1_new)
###hash=$(QNC_SHA1_HEX=1 qnc_sha1_sum "${ctx}" "abcd")
###echo "${hash}"
###ctx=$(qnc_sha1_new)
###hash=$(perl -e 'print "0" x 65;' | QNC_SHA1_HEX=1 qnc_sha1_sum "${ctx}")
###echo "${hash}"
