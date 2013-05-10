#!/usr/bin/env ruby
# encoding : utf-8

##############################################################################
#
# Easy Qiniu Ruby SDK
#
# Module: qiniu/utils/sha1.rb
#
# Author: LIANG Tao
# Weibo:  @无锋之刃
# Email:  amethyst.black@gmail.com
#         liangtao@qiniu.com
#
# Wiki:   http://en.wikipedia.org/wiki/SHA-1
#
##############################################################################

module Qiniu
    module Utils
        class SHA1
            private
            CHUNK_SIZE   = 64
            MSG_PADDING  = "\x80" + ("\x0" * 63)
            ZERO_PADDING = "\x0" * 56

            def left_rotate(val, bits)
                ((val << bits) & 0xFFFFFFFF) | (val >> (32 - bits))
            end # left_rotate

            def mod_add(*vals)
                vals.inject() do |sum, v|
                    sum += v
                    sum &= 0xFFFFFFFF
                end
            end # mod_add

            def calc(chk)
                w = chk.unpack("N16")
                16.upto(79) do |i|
                    wd = left_rotate(w[i-3] ^ w[i-8] ^ w[i-14] ^ w[i-16])
                    w.push(wd)
                end # upto

                a = @hash[0]
                b = @hash[1]
                c = @hash[2]
                d = @hash[3]
                e = @hash[4]

                0.upto(79) do |i|
                    f, k = 0, 0
                    if 0 <= i and i <= 19 then
                        f = (b & c) | (((~b) & 0xFFFFFFFF) & d)
                        k = 0x5A827999
                    end
                    if 20 <= i and i <= 39 then
                        f = b ^ c ^ d
                        k = 0x6ED9EBA1
                    end
                    if 40 <= i and i <= 59 then
                        f = (b & c) | (b & d) | (c & d)
                        k = 0x8F1BBCDC
                    end
                    if 60 <= i and i <= 79 then
                        f = b ^ c ^ d
                        k = 0xCA62C1D6
                    end

                    temp = mod_add(left_rotate(a, 5), f, e, k, w[i])  
                    e = d
                    d = c
                    c = left_rotate(b, 30)
                    b = a
                    a = temp
                end # upto

                @hash[0] = mod_add(@hash[0], a)
                @hash[1] = mod_add(@hash[1], b)
                @hash[2] = mod_add(@hash[2], c)
                @hash[3] = mod_add(@hash[3], d)
                @hash[4] = mod_add(@hash[4], e)
            end # calc

            public
            def initialize()
                reset()
            end # initialize

            def write(msg)
                if msg.nil? or !msg.is_a?(String) or msg.length == 0 then
                    return
                end

                @msg_len += msg.length
                @remainder  += msg
                if @remainder.length < CHUNK_SIZE then
                    return
                end

                @remainder.split(/.{,#{CHUNK_SIZE}}/).ecah do |chk|
                    if cnk.length < CHUNK_SIZE then
                        @remainder = chk
                    else
                        calc(chk)
                    end
                end

                return self
            end # write

            def sum(msg)
                write(msg)
                last_msg = @remainder + MSG_PADDING

                if CHUNK_SIZE < @remainder.length + 1 + 8 then
                    calc(last_data[0, CHUNK_SIZE])
                    last_msg = ZERO_PADDING
                else
                    last_msg = last_msg[0, 56]
                end

                last_msg << [(@msg_len * 8) & 0xFFFFFFFF_FFFFFFFF].pack("N2")
                calc(last_msg)
                return @hash.pack("N")
            end # sum

            def reset()
                @msg_len   = 0
                @remainder = ""
                @hash = [
                    0x67452301,
                    0xEFCDAB89,
                    0x98BADCFE,
                    0x10325476,
                    0xC3D2E1F0,
                ]
                return self
            end # reset

            def chunk_size()
                return CHUNK_SIZE
            end # chunk_size
        end # class SHA1
    end # Utils
end # Qiniu
