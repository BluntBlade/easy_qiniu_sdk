#!/bin/bash

##############################################################################
#
# Easy Qiniu Bash SDK
#
# Module: utils/hmac.sh
#
# Author: LIANG Tao
# Weibo:  @无锋之刃
# Email:  liangtao@qiniu.com
#         amethyst.black@gmail.com
#
# Wiki:   http://en.wikipedia.org/wiki/Hash-based_message_authentication_code
#
##############################################################################

QNC_HMAC_HEX=""

dir=$(dirname $0)
if [[ "${dir}" == "." ]]; then
    dir=$(pwd)
fi

function __qnc_hmac_unpack_bytes {
    perl -ne 'chomp; print map { "$_ " } (unpack("H*", $_) =~ m/(.{2})/g)'
} # __qnc_hmac_unpack_bytes

function __qnc_hmac_pack_bytes {
    perl -ne 'chomp; s/ //g; print pack("H*", $_)'
} # __qnc_hmac_pack_bytes

function __qnc_hmac_calc_key_pad {
    local hex=($1)
    local pad=$2
    local cnt=$3
    shift 3

    local tmp=0
    for (( i = 0; i < ${cnt}; i += 1 )); do
        tmp=$(( 0x${hex[$i]} ^ 0x${pad} ))
        hex[$i]=$(printf "%02x" "${tmp}")
    done
    echo -n "${hex[@]} "
    return 0
} # __qnc_hmac_calc_key_pad

function qnc_hmac_new {
    local hash="qnc_$1"
    local secret_key=$2
    shift 2

    local block_size=""
    block_size=$(${hash}_chunk_size)

    # Don't extract the length of the secret key since it would be changed
    if [[ "${#secret_key}" -gt "${block_size}" ]]; then
        secret_key=$(${hash} "${secret_key}" | __qnc_hmac_unpack_bytes)
    else
        secret_key=$(echo -n "${secret_key}" | __qnc_hmac_unpack_bytes)
    fi

    local secret_key_len=$(( ${#secret_key} / 3 ))
    if [[ "${secret_key_len}" -lt "${block_size}" ]]; then
        for (( i = 0; i < $((${block_size} - ${secret_key_len})); i += 1 )); do
            secret_key="${secret_key}00 "
        done
    fi

    local o_key_pad=""
    o_key_pad=$(__qnc_hmac_calc_key_pad "${secret_key}" "5C" "${block_size}")

    local i_key_pad=""
    i_key_pad=$(__qnc_hmac_calc_key_pad "${secret_key}" "36" "${block_size}")

    local hash_ctx=""
    hash_ctx=$(${hash}_new)
    hash_ctx=$(echo -n "${i_key_pad}" | __qnc_hmac_pack_bytes | ${hash}_write "${hash_ctx}")
    echo -n "${#o_key_pad} ${o_key_pad}${i_key_pad}${hash} ${hash_ctx}"
    return 0
} # qnc_hmac_new

function __qnc_hmac_calc {
    local end=$1
    local ctx=$2
    local msg=$3
    shift 3

    local key_pad_len="${ctx%% *}"
    ctx="${ctx#* }"
    local o_key_pad="${ctx:0:${key_pad_len}}"
    local i_key_pad="${ctx:${key_pad_len}:${key_pad_len}}"
    ctx="${ctx:$(( ${key_pad_len} * 2 ))}"
    local hash="${ctx%% *}"
    local hash_ctx="${ctx#* }"

    if [[ "${#end}" -eq 0 ]]; then
        hash_ctx=$(${hash}_write "${hash_ctx}" "${msg}")
        echo -n "${key_pad_len} ${o_key_pad}${i_key_pad}${hash} ${hash_ctx}"
        return 0
    fi

    local i_hash=""
    i_hash=$(${hash}_sum "${hash_ctx}" "${msg}")

    hash_ctx=$(${hash}_new)
    hash_ctx=$(echo -n "${o_key_pad}" | __qnc_hmac_pack_bytes | ${hash}_write "${hash_ctx}")
    local output=""
    output=$(echo -n "${i_hash}" | ${hash}_sum "${hash_ctx}")

    if [[ "${#QNC_HMAC_HEX}" -eq 0 ]]; then
        echo -n "${output}"
    else
        echo -n "${output}" | perl -ne 'print unpack("H*", $_);'
    fi
    return 0
} # __qnc_hmac_calc

function qnc_hmac_write {
    __qnc_hmac_calc '' "$@"
} # qnc_hmac_write

function qnc_hmac_sum {
    __qnc_hmac_calc 'END' "$@"
} # qnc_hmac_sum

###echo -n "abcd" | __qnc_hmac_unpack_bytes
###echo -n "61 62 63 64 " | __qnc_hmac_pack_bytes
###source "${dir}/sha1.sh"
###hmac_ctx=$(qnc_hmac_new "sha1" "12345678")
###hmac=$(QNC_HMAC_HEX=1 qnc_hmac_sum "${hmac_ctx}" "12345678")
###echo "${hmac}"
