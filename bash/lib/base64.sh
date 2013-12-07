#!/bin/bash

BASE64_PAD="="

function chr {
    printf \\$(($1/64*100 + $1%64/8*10 + $1%8))
} # chr

function ord {
    LC_CTYPE=C printf '%d' "'$1"
} # ord

function __base64_encode_calc {
    local map=$1
    local d1=$2
    local d2=$3
    local d3=$4
    shift 4

    if [[ -z "${d1}" || "${d1}" -eq 0 ]]; then
        return 0
    fi
    if [[ -z "${d2}" ]]; then
        d2=0
    fi
    if [[ -z "${d3}" ]]; then
        d3=0
    fi

    local p1=$(( (${d1} >> 2) & 0x3F ))
    local p2=$(( ( (${d1} & 0x3) << 4 ) | ( (${d2} & 0xF0) >> 4 ) ))
    local p3=$(( ( (${d2} & 0xF) << 2 ) | ( (${d3} & 0xC0) >> 6 ) ))
    local p4=$(( ${d3} & 0x3F ))

    ### printf "%d %d %d %d\n" $p1 $p2 $p3 $p4

    if [[ "${d2}" -eq 0 ]]; then
        echo -n "${map:$p1:1}${map:$p2:1}"
        return 1
    fi
    if [[ "${d3}" -eq 0 ]]; then
        echo -n "${map:$p1:1}${map:$p2:1}${map:$p3:1}"
        return 2
    fi

    echo -n "${map:$p1:1}${map:$p2:1}${map:$p3:1}${map:$p4:1}"
    return 3
} # __base64_encode_calc

function __base64_encode_impl {
    local map=$1
    local buf=$2
    shift 2

    local len=0
    local ret=""
    local buf_len=${#buf}
    if [[ "${buf_len}" -eq 0 ]]; then
        while read d1 d2 d3; do
            local output=""
            output="$(__base64_encode_calc "${map}" "${d1}" "${d2}" "${d3}")"
            len=$(( ${len} + $? ))

            if [[ -z "${output}" ]]; then
                break
            fi
            ret="${ret}${output}"
        done
    else
        local i=0
        while true; do
            local i1=$(( $i + 1 ))
            local i2=$(( $i + 2 ))
            local input="$(LC_CTYPE=C printf "%d %d %d" \'${buf:$i:1} \'${buf:${i1}:1} \'${buf:${i2}:1})"
            local output=""
            output="$(__base64_encode_calc "${map}" ${input})"
            len=$(( ${len} + $? ))

            i=$(( $i + 3 ))

            if [[ -z "${output}" ]]; then
                break
            fi
            ret="${ret}${output}"
        done
    fi

    echo -n "${ret}"

    if [[ -n "${BASE64_PAD}" ]]; then
        local padding_len=$(( 3 - (${len} % 3) ))
        if [[ "${padding_len}" -eq 1 ]]; then
            echo -n "${BASE64_PAD}"
        elif [[ "${padding_len}" -eq 2 ]]; then
            echo -n "${BASE64_PAD}${BASE64_PAD}"
        fi
    fi
    return 0
} # __base64_encode_impl

function __base64_encode_wrapper {
    if [[ $# -gt 1 ]]; then
        __base64_encode_impl "$@"
    else
        od -tu1 -An                    | \
        tr -d '\n'                     | \
        grep -o '\( *[0-9]\+\)\{1,3\}' | \
        __base64_encode_impl "$@"
    fi
} # __base64_encode_wrapper

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
    __base64_encode_wrapper "${__BASE64_URLSAFE_MAP}" "$@"
} # base64_encode_urlsafe

function base64_decode_urlsafe {
    __base64_decode_impl "${__BASE64_URLSAFE_MAP}" "$@"
} # base64_decode_urlsafe

__BASE64_MAP="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

function base64_encode {
    __base64_encode_wrapper "${__BASE64_MAP}" "$@"
} # base64_encode

function base64_decode {
    __base64_decode_impl "${__BASE64_MAP}" "$@"
} # base64_decode

###echo -n "abcd" | base64_encode
###echo
###base64_encode "abcd"
###echo
###base64_decode "YWJjZA=="
###echo
