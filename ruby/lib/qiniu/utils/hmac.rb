#!/usr/bin/env ruby
# encoding : utf-8

##############################################################################
#
# Easy Qiniu Ruby SDK
#
# Module: qiniu/utils/hmac.rb
#
# Author: LIANG Tao
# Weibo:  @无锋之刃
# Email:  liangtao@qiniu.com
#         amethyst.black@gmail.com
#
# Wiki:   http://en.wikipedia.org/wiki/Hash-based_message_authentication_code
#
##############################################################################

module Qiniu
    module Utils
        class HMAC
            public
            def initialize(hash, secret_key)
                @hash = hash
                @secret_key = secret_key

                block_size = @hash.chunk_size()
                if secret_key.length > block_size then
                    secret_key = @hash.reset().sum(secret_key)
                    @hash.reset()
                end
                if secret_key.length < block_size then
                    secret_key << ("\x0" * (block_size - secret_key.length))
                end

                @o_key_pad = secret_key.dup.each_byte do |bt|
                    bt = (bt.ord ^ 0x5C).chr
                end
                @i_key_pad = secret_key.dup.each_byte do |bt|
                    bt = (bt.ord ^ 0x36).chr
                end

                reset()
            end # initialize

            def write(msg)
                @hash.write(msg)
            end # write

            def sum(msg)
                i_hash = @hash.sum(msg)
                @hash.reset().sum(@o_key_pad + i_hash)
            end # sum

            def reset()
                @hash.reset().write(@i_key_pad)
            end # reset
        end # HMAC
    end # Utils
end # Qiniu
