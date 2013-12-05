#!/bin/bash

function chr {
    printf \\$(($1/64*100 + $1%64/8*10 + $1%8))
} # chr

function ord {
    LC_CTYPE=C printf '%d' "'$1"
} # ord

function __base64_encode_impl {
    local map=$1
    local buf=$2
    local pad=$3
    shift 3

    if [[ -z "${pad}" ]]; then
        pad="="
    fi

    local buf_len=${#buf}
    if [[ "${buf_len}" -eq 0 ]]; then
        echo -n ""
        return 0
    fi

    local remainder=$(( ${buf_len} % 3 ))
    local padding_len=0
    if [[ "${remainder}" -eq 0 ]]; then
        padding_len=0
    else
        padding_len=$(( 3 - ${remainder} ))
    fi

    local ret=""
    local len=$(( ${buf_len} + ${padding_len} ))
    for ((i = 0; i < "${len}"; i += 3)); do
        local i1=$(( $i + 1 ))
        local i2=$(( $i + 2 ))
        eval "d=($(LC_CTYPE=C printf "\- %d %d %d" \'${buf:$i:1} \'${buf:${i1}:1} \'${buf:${i2}:1}))"

        ### echo ${d[1]} ${d[2]} ${d[3]}
 
        local p1=$(( (${d[1]} >> 2) & 0x3F ))
        local p2=$(( ( (${d[1]} & 0x3) << 4 ) | ( (${d[2]} & 0xF0) >> 4 ) ))
        local p3=$(( ( (${d[2]} & 0xF) << 2 ) | ( (${d[3]} & 0xC0) >> 6 ) ))
        local p4=$(( ${d[3]} & 0x3F ))

        ### printf "%d %d %d %d\n" $p1 $p2 $p3 $p4

        local c1=${map:$p1:1}
        local c2=${map:$p2:1}
        local c3=${map:$p3:1}
        local c4=${map:$p4:1}

        if [[ "${i1}" -eq "${buf_len}" ]]; then
            ret="${ret}${c1}${c2}"
            break
        fi
        if [[ "${i2}" -eq "${buf_len}" ]]; then
            ret="${ret}${c1}${c2}${c3}"
            break
        fi

        ret="${ret}${c1}${c2}${c3}${c4}"
    done

    echo -n "${ret}"
    if [[ "${padding_len}" -eq 1 ]]; then
        echo -n "${pad}"
    elif [[ "${padding_len}" -eq 2 ]]; then
        echo -n "${pad}${pad}"
    fi
    return 0
} # __base64_encode_impl

__BASE64_FIRST=1
__BASE64_SECOND=2
__BASE64_THIRD=3
__BASE64_FOURTH=4

function __base64_decode_impl {
    local map=$1
    local buf=$2
    local pad=$3
    shift 3

    if [[ -z "${pad}" ]]; then
        pad="="
    fi

    buf="${buf%%${pad}*}"

    local buf_len=${#buf}
    if [[ "${buf_len}" -eq 0 ]]; then
        echo -n ""
        return
    fi

    local state="${__BASE64_FIRST}"
    local chr=0
    local ret=""
    for ((i = 0; i < "${buf_len}"; i += 1)); do
        local prefix=${map%%${buf:$i:1}*}
        local val=${#prefix}
        if [[ "${state}" -eq "${__BASE64_FIRST}" ]]; then
            chr=$(( (${val} & 0x3F) << 2))
            state="${__BASE64_SECOND}"
            continue
        fi
        if [[ "${state}" -eq "${__BASE64_SECOND}" ]]; then
            chr=$(( ${chr} | ( (${val} & 0x30) >> 4 ) ))
            ret="${ret}$(chr "${chr}")"
            chr=$(( (${val} & 0xF) << 4 ))
            state="${__BASE64_THIRD}"
            continue
        fi
        if [[ "${state}" -eq "${__BASE64_THIRD}" ]]; then
            chr=$(( ${chr} | ( (${val} & 0x3C) >> 2 ) ))
            ret="${ret}$(chr "${chr}")"
            chr=$(( (${val} & 0x3) << 6 ))
            state="${__BASE64_FOURTH}"
            continue
        fi

        chr=$(( ${chr} | (${val} & 0x3F) ))
        ret="${ret}$(chr "${chr}")"
        state="${__BASE64_FIRST}"
    done

    echo -n "${ret}"
    return 0
}; # decode_impl

__BASE64_URLSAFE_MAP="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"

function base64_encode_urlsafe {
    __base64_encode_impl "${__BASE64_URLSAFE_MAP}" "$@"
} # base64_encode_urlsafe

function base64_decode_urlsafe {
    __base64_decode_impl "${__BASE64_URLSAFE_MAP}" "$@"
} # base64_decode_urlsafe

__BASE64_MAP="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

function base64_encode {
    __base64_encode_impl "${__BASE64_MAP}" "$@"
} # base64_encode

function base64_decode {
    __base64_decode_impl "${__BASE64_MAP}" "$@"
} # base64_decode

###base64_encode "abcd"
###echo
###base64_decode "YWJjZA=="
###echo
