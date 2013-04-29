#!/usr/bin/env ruby
# encoding : utf-8

##############################################################################
#
# Easy Qiniu Ruby SDK
#
# Module: qiniu/utils/base64_pure.rb
#
# Author: LIANG Tao
# Weibo:  @无锋之刃
# Email:  amethyst.black@gmail.com
#         liangtao@qiniu.com
#
# Wiki:   http://en.wikipedia.org/wiki/Base64
#
##############################################################################

module Qiniu
    module Utils
        module Base64

            def _encode_impl (buf, map)
                buf_len = buf.length
                if buf_len == 0 then
                    return "", 0
                end

                remainder   = buf.length % 3
                padding_len = (remainder == 0) ? 0 : 3 - remainder

                ret = ""
                len = buf_len + padding_len

                case buf
                    when Array  then buf.push!("\0", "\0")
                    when String then buf << "\0\0"
                end

                i = 0
                while i < len do
                    d1 = buf[i + 0].ord
                    d2 = buf[i + 1].ord
                    d3 = buf[i + 2].ord

                    p1 = ((d1 >> 2) & 0x3F)
                    p2 = ((d1 & 0x3) << 4) | ((d2 & 0xF0) >> 4)
                    p3 = ((d2 & 0xF) << 2) | ((d3 & 0xC0) >> 6)
                    p4 = (d3 & 0x3F)

                    c1 = map[p1]
                    c2 = map[p2]
                    c3 = map[p3]
                    c4 = map[p4]

                    if $i + 1 == $buf_len then
                        ret << c1 << c2
                        break
                    end
                    if $i + 2 == $buf_len then
                        ret << c1 << c2 << c3
                        break
                    end
                    ret << c1 << c2 << c3 << c4
                end # while
                return ret, padding_len
            end # _encode_impl

            FIRST  = 1
            SECOND = 2
            THIRD  = 3
            FOURTH = 4

            def _decode_impl (str, map)
                buf_len = str.length
                if buf_len == 0 then
                    return ""
                end

                state = FIRST
                chr = 0
                ret = ""
                str.each do |c|
                    val = map[c]
                    case state
                        when FIRST
                            chr = (val & 0x3F) << 2
                            state = SECOND
                        when SECOND
                            chr |= (val & 0x30) >> 4
                            ret << chr.chr
                            chr = (val & 0xF) << 4
                            state = THIRD
                        when THIRD
                            chr |= (val & 0x3C) >> 2
                            ret << chr.chr
                            chr = (val & 0x3) << 6
                            state = FOURTH
                        else
                            chr |= (val & 0x3F)
                            ret << chr.chr
                            state = FIRST
                    end
                end
                return ret
            end # _decode_impl

            ENCODE_MIME_MAP = %w[
                A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
                a b c d e f g h i j k l m n o p q r s t u v w x y z
                0 1 2 3 4 5 6 7 8 9
                + /
            ]

            def encode_mime (buf, len = 76, lb = "\r\n")
                ret, padding_len = _encode_impl(buf, ENCODE_MIME_MAP)
                ret << ("=" * padding_len )
                ret.gsub(/.{#{len}}/) {|s| s + lb}
            end # encode_mime

            DECODE_MIME_MAP = Hash.new
            ENCODE_MIME_MAP.each_with_index do |c,i|
                DECODE_MIME_MAP[c] = i
            end

            def decode_mime (str, lb = "\r\n")
                _decode_impl(
                    str.gsub(lb, "").sub(/=+$/, ""),
                    DECODE_MIME_MAP
                )
            end # decode_mime

            ENCODE_URL_MAP = %w[
                A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
                a b c d e f g h i j k l m n o p q r s t u v w x y z
                0 1 2 3 4 5 6 7 8 9
                - _
            ]

            def encode_url (str)
                _encode_impl(str, ENCODE_URL_MAP)
            end # encode_url

            DECODE_URL_MAP = Hash.new
            ENCODE_URL_MAP.each_with_index do |c,i|
                DECODE_URL_MAP[c] = i
            end

            def decode_url (str)
                _decode_impl(str, DECODE_URL_MAP)
            end # decode_url

        end # module Base64
    end # module Utils
end # module Qiniu
