#!/bin/bash

##############################################################################
#
# Easy Qiniu Bash SDK
#
# Module: base64.sh
#
# Author: LIANG Tao
# Weibo:  @无锋之刃
# Email:  liangtao@qiniu.com
#         amethyst.black@gmail.com
#
# Wiki:   http://en.wikipedia.org/wiki/Base64
#
##############################################################################

QNC_BASE64_PAD="="

function __qnc_base64_chr {
    printf \\$(($1/64*100 + $1%64/8*10 + $1%8))
} # __qnc_base64_chr

function __qnc_base64_encode_calc {
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
} # __qnc_base64_encode_calc

function __qnc_base64_encode_impl {
    local args_cnt=$#

    local map=$1
    local buf=$2
    shift 2

    local len=0
    local ret=""
    local buf_len=${#buf}
    if [[ "${args_cnt}" -eq 0 ]]; then
        while read d1 d2 d3; do
            local output=""
            output="$(__qnc_base64_encode_calc "${map}" "${d1}" "${d2}" "${d3}")"
            len=$(( ${len} + $? ))

            if [[ -z "${output}" ]]; then
                break
            fi
            ret="${ret}${output}"
        done
    else
        if [[ "${#buf}" -eq 0 ]]; then
            echo -n ""
            return
        fi

        local i=0
        while true; do
            local i1=$(( $i + 1 ))
            local i2=$(( $i + 2 ))
            local input="$(LC_CTYPE=C printf "%d %d %d" \'${buf:$i:1} \'${buf:${i1}:1} \'${buf:${i2}:1})"
            local output=""
            output="$(__qnc_base64_encode_calc "${map}" ${input})"
            len=$(( ${len} + $? ))

            i=$(( $i + 3 ))

            if [[ -z "${output}" ]]; then
                break
            fi
            ret="${ret}${output}"
        done
    fi

    echo -n "${ret}"

    if [[ -n "${QNC_BASE64_PAD}" ]]; then
        local padding_len=$(( 3 - (${len} % 3) ))
        if [[ "${padding_len}" -eq 1 ]]; then
            echo -n "${QNC_BASE64_PAD}"
        elif [[ "${padding_len}" -eq 2 ]]; then
            echo -n "${QNC_BASE64_PAD}${QNC_BASE64_PAD}"
        fi
    fi
    return 0
} # __qnc_base64_encode_impl

function __qnc_base64_encode_wrapper {
    if [[ $# -gt 1 ]]; then
        __qnc_base64_encode_impl "$@"
    else
        od -v -tu1 -An                 | \
        tr '\n' ' '                    | \
        grep -o '\([0-9]\+ *\)\{1,3\}' | \
        __qnc_base64_encode_impl "$@"
    fi
} # __qnc_base64_encode_wrapper

function __qnc_base64_decode_calc {
    local map=$1
    local c1=$2
    local c2=$3
    local c3=$4
    local c4=$5
    shift 5

    local prefix=""
    local chr=0
    local ord=0

    if [[ -z "${c1}" || "${c1}" == "${QNC_BASE64_PAD}" ]]; then
        return 0
    fi

    ### decode first byte
    prefix="${map%%${c1}*}"
    ord="${#prefix}"

    chr=$(( (${ord} & 0x3F) << 2 ))

    if [[ -z "${c2}" || "${c2}" == "${QNC_BASE64_PAD}" ]]; then
        return 0
    fi

    ### decode second byte
    prefix="${map%%${c2}*}"
    ord="${#prefix}"

    chr=$(( ${chr} | ( (${ord} & 0x30) >> 4 ) ))
    echo -n "$(__qnc_base64_chr "${chr}")"
    chr=$(( (${ord} & 0xF) << 4 ))

    if [[ -z "${c3}" || "${c3}" == "${QNC_BASE64_PAD}" ]]; then
        return 0
    fi

    ### decode third byte
    prefix="${map%%${c3}*}"
    ord="${#prefix}"

    chr=$(( ${chr} | ( (${ord} & 0x3C) >> 2 ) ))
    echo -n "$(__qnc_base64_chr "${chr}")"
    chr=$(( (${ord} & 0x3) << 6 ))

    if [[ -z "${c4}" || "${c4}" == "${QNC_BASE64_PAD}" ]]; then
        return 0
    fi

    ### decode fourth byte
    prefix="${map%%${c4}*}"
    ord="${#prefix}"

    chr=$(( ${chr} | (${ord} & 0x3F) ))
    echo -n "$(__qnc_base64_chr "${chr}")"
    return 0
} # __qnc_base64_decode_calc

function __qnc_base64_decode_impl {
    local map=$1
    local buf=$2
    shift 2

    local buf_len=${#buf}
    if [[ "${buf_len}" -eq 0 ]]; then
        while read d1 d2 d3 d4; do
            local output=""
            output="$(__qnc_base64_decode_calc "${map}" "${d1}" "${d2}" "${d3}" "${d4}")"
            if [[ -z "${output}" ]]; then
                break
            fi

            echo -n "${output}"
        done
    else
        local i=0
        while true; do
            local i1=$(( $i + 1 ))
            local i2=$(( $i + 2 ))
            local i3=$(( $i + 3 ))
            local output=""
            output="$(__qnc_base64_decode_calc "${map}" "${buf:$i:1}" "${buf:$i1:1}" "${buf:$i2:1}" "${buf:$i3:1}")"
            if [[ -z "${output}" ]]; then
                break
            fi

            echo -n "${output}"
            i=$(( $i + 4 ))
        done
    fi

    return 0
}; # decode_impl

function __qnc_base64_decode_wrapper {
    if [[ $# -gt 1 ]]; then
        __qnc_base64_decode_impl "$@"
    else
        grep -o '[^ ]'                 | \
        tr '\n' ' '                    | \
        grep -o '\([^ ]\+ *\)\{1,4\}'  | \
        __qnc_base64_decode_impl "$@"
    fi
} # __qnc_base64_decode_wrapper

__QNC_BASE64_URLSAFE_MAP="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"

function qnc_base64_encode_urlsafe {
    __qnc_base64_encode_wrapper "${__QNC_BASE64_URLSAFE_MAP}" "$@"
} # qnc_base64_encode_urlsafe

function qnc_base64_decode_urlsafe {
    __qnc_base64_decode_wrapper "${__QNC_BASE64_URLSAFE_MAP}" "$@"
} # qnc_base64_decode_urlsafe

__QNC_BASE64_MAP="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

function qnc_base64_encode {
    __qnc_base64_encode_wrapper "${__QNC_BASE64_MAP}" "$@"
} # qnc_base64_encode

function qnc_base64_decode {
    __qnc_base64_decode_wrapper "${__QNC_BASE64_MAP}" "$@"
} # qnc_base64_decode

qnc_base64_encode
###echo -n "abcd" | qnc_base64_encode
###echo
###qnc_base64_encode "abcd"
###echo
###echo -n "YWJjZA==" | qnc_base64_decode
###echo
###qnc_base64_decode "YWJjZA=="
###echo
