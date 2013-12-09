#!/bin/bash

dir=$(dirname $0)
if [[ "${dir}" == "." ]]; then
    dir=$(pwd)
fi

source "${dir}/../utils/base64.sh"

function test_base64_encode_mime {
    local case=$1
    local src=$2
    local dst=$3
    shift 3

    local ret=$(qnc_base64_encode "${src}")
    local check=""
    if [[ "${ret}" == "${dst}" ]]; then
        check="ok"
    else
        check="failed"
    fi

    echo "$case: [$dst] [$ret] $check"
} # test_base64_encode_mime

function test_base64_decode_mime {
    local case=$1
    local src=$2
    local dst=$3
    shift 3

    local ret=$(qnc_base64_decode "${src}")
    local check=""
    if [[ "${ret}" == "${dst}" ]]; then
        check="ok"
    else
        check="failed"
    fi

    echo "$case: [$dst] [$ret] $check"
} # test_base64_decode_mime

test_base64_encode_mime "encode_mime_2" "H" "SA==" 
test_base64_encode_mime "encode_mime_3" "He" "SGU=" 
test_base64_encode_mime "encode_mime_4" "Hel" "SGVs" 
test_base64_encode_mime "encode_mime_5" "Hell" "SGVsbA==" 
test_base64_encode_mime "encode_mime_6" "Hello" "SGVsbG8=" 
#test_base64_encode_mime "encode_mime_7" "Hello\0" "SGVsbG8A" 
#test_base64_encode_mime "encode_mime_8" "\xff\xff\xff\xff" "/////w==" 
test_base64_encode_mime "encode_mime_9" "f" "Zg==" 
test_base64_encode_mime "encode_mime_10" "fo" "Zm8=" 
test_base64_encode_mime "encode_mime_11" "foo" "Zm9v" 
test_base64_encode_mime "encode_mime_12" "foob" "Zm9vYg==" 
test_base64_encode_mime "encode_mime_13" "fooba" "Zm9vYmE=" 
test_base64_encode_mime "encode_mime_14" "foobar" "Zm9vYmFy" 

test_base64_decode_mime "decode_mime_2" "SA==" "H" 
test_base64_decode_mime "decode_mime_3" "SGU=" "He" 
test_base64_decode_mime "decode_mime_4" "SGVs" "Hel" 
test_base64_decode_mime "decode_mime_5" "SGVsbA==" "Hell" 
test_base64_decode_mime "decode_mime_6" "SGVsbG8=" "Hello" 
#test_base64_decode_mime "decode_mime_7" "SGVsbG8A" "Hello\0" 
#test_base64_decode_mime "decode_mime_8" "/////w==" "\xff\xff\xff\xff" 
test_base64_decode_mime "decode_mime_9" "Zg==" "f" 
test_base64_decode_mime "decode_mime_10" "Zm8=" "fo" 
test_base64_decode_mime "decode_mime_11" "Zm9v" "foo" 
test_base64_decode_mime "decode_mime_12" "Zm9vYg==" "foob" 
test_base64_decode_mime "decode_mime_13" "Zm9vYmE=" "fooba" 
test_base64_decode_mime "decode_mime_14" "Zm9vYmFy" "foobar" 
