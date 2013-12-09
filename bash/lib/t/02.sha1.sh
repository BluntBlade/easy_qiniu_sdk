#!/bin/bash

dir=$(dirname $0)
if [[ "${dir}" == "." ]]; then
    dir=$(pwd)
fi

source "${dir}/../utils/sha1.sh"

function test_sha1 {
    local case=$1
    local src=$2
    local dst=$3
    shift 3

    local ret=$(QNC_SHA1_HEX=1 qnc_sha1 "${src}")

    local check=""
    if [[ "${ret}" == "${dst}" ]]; then
        check="ok"
    else
        check="failed"
    fi

    echo "$case: [$dst] [$ret] $check"
} # test_sha1

test_sha1 "sha1_1" "1" "356a192b7913b04c54574d18c28d46e6395428ab"
test_sha1 "sha1_abc" "abc" "a9993e364706816aba3e25717850c26c9cd0d89d"
test_sha1 "sha1_zero_bytes" "" "da39a3ee5e6b4b0d3255bfef95601890afd80709"
test_sha1 "sha1_26_letters" "The quick brown fox jumps over the lazy dog" "2fd4e1c67a2d28fced849ee1bb76e7391b93eb12"

test_sha1 "sha1_55_chars" $(perl -e 'print "1" x 55') "6b10c9ff4e3356b38d340918f62de8de87af9c6d"
test_sha1 "sha1_56_chars" $(perl -e 'print "2" x 56') "22cca35f9663d431d6cb3c90ad7ebd63894f6d7c"
test_sha1 "sha1_57_chars" $(perl -e 'print "3" x 57') "cbf1acf4032a1061944cc7edab1197b722c173a5"
test_sha1 "sha1_58_chars" $(perl -e 'print "4" x 58') "4bcf8831ffea0f4ab7cae9489ee7f40ab8bd831c"
test_sha1 "sha1_59_chars" $(perl -e 'print "5" x 59') "fb2c06c4248c559294cb81027ffaabe2dca133f5"
test_sha1 "sha1_60_chars" $(perl -e 'print "6" x 60') "1d335f86eec79c17ecc9b30cbebfcd53e82281ee"
test_sha1 "sha1_61_chars" $(perl -e 'print "7" x 61') "10925fe9f1805b248bc425f34e007e66ebeb08e4"
test_sha1 "sha1_62_chars" $(perl -e 'print "8" x 62') "6b4f246bbdc828850c20de13ce222c7dc6a3aafd"
test_sha1 "sha1_63_chars" $(perl -e 'print "9" x 63') "3174fc2c9058350caaf76d555e38114e6c49cc43"
test_sha1 "sha1_64_chars" $(perl -e 'print "0" x 64') "0114498021cb8c4f1519f96bdf58dd806f3adb63"
test_sha1 "sha1_65_chars" $(perl -e 'print "A" x 65') "826b7e7a7af8a529ae1c7443c23bf185c0ad440c"
test_sha1 "sha1_66_chars" $(perl -e 'print "B" x 66') "af2a537bf42a6e2393eaa71f0b203a3b3f0f7ec0"
test_sha1 "sha1_67_chars" $(perl -e 'print "C" x 67') "a78a3e18cfbcf38dc30f175097940301b03d17ac"
test_sha1 "sha1_68_chars" $(perl -e 'print "D" x 68') "3999ef9ace5826a444579949aa0e6f1c39318459"
