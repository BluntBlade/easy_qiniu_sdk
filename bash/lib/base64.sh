#!/bin/bash

BASE64_PAD="="

function chr {
    printf \\$(($1/64*100 + $1%64/8*10 + $1%8))
} # chr

function ord {
    LC_CTYPE=C printf '%d' "'$1"
} # ord

function __base64_encode_impl {
    local map=$1
    local buf=$2
    shift 2

    local pad="${BASE64_PAD}"

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

        if [[ "${i1}" -eq "${buf_len}" ]]; then
            ret="${ret}${map:$p1:1}${map:$p2:1}"
            break
        fi
        if [[ "${i2}" -eq "${buf_len}" ]]; then
            ret="${ret}${map:$p1:1}${map:$p2:1}${map:$p3:1}"
            break
        fi

        ret="${ret}${map:$p1:1}${map:$p2:1}${map:$p3:1}${map:$p4:1}"
    done

    echo -n "${ret}"
    if [[ "${padding_len}" -eq 1 ]]; then
        echo -n "${pad}"
    elif [[ "${padding_len}" -eq 2 ]]; then
        echo -n "${pad}${pad}"
    fi
    return 0
} # __base64_encode_impl

function __base64_decode_impl {
    local map=$1
    local buf=$2
    shift 2

    local pad="${BASE64_PAD}"

    buf="${buf%%${pad}*}"

    local buf_len=${#buf}
    if [[ "${buf_len}" -eq 0 ]]; then
        echo -n ""
        return
    fi

    local chr=0
    local ret=""
    local i=0
    local prefix=""
    local val=""
    while [[ $i -lt "${buf_len}" ]]; do
        ### decode first byte
        prefix="${map%%${buf:$i:1}*}"
        val="${#prefix}"

        chr=$(( (${val} & 0x3F) << 2 ))

        i=$(( $i + 1 ))
        if [[ $i -ge "${buf_len}" ]]; then
            return 1
            break
        fi

        ### decode second byte
        prefix="${map%%${buf:$i:1}*}"
        val="${#prefix}"

        chr=$(( ${chr} | ( (${val} & 0x30) >> 4 ) ))
        ret="${ret}$(chr "${chr}")"
        chr=$(( (${val} & 0xF) << 4 ))

        i=$(( $i + 1 ))
        if [[ $i -ge "${buf_len}" ]]; then
            break
        fi

        ### decode third byte
        prefix="${map%%${buf:$i:1}*}"
        val="${#prefix}"

        chr=$(( ${chr} | ( (${val} & 0x3C) >> 2 ) ))
        ret="${ret}$(chr "${chr}")"
        chr=$(( (${val} & 0x3) << 6 ))

        i=$(( $i + 1 ))
        if [[ $i -ge "${buf_len}" ]]; then
            break
        fi

        ### decode fourth byte
        prefix="${map%%${buf:$i:1}*}"
        val="${#prefix}"

        chr=$(( ${chr} | (${val} & 0x3F) ))
        ret="${ret}$(chr "${chr}")"

        i=$(( $i + 1 ))
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
