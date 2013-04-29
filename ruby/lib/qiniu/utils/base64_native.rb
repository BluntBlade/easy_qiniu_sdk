#!/usr/bin/env ruby
# encoding : utf-8

##############################################################################
#
# Easy Qiniu Ruby SDK
#
# Module: qiniu/utils/base64_native.rb
#
# Author: LIANG Tao
# Weibo:  @无锋之刃
# Email:  amethyst.black@gmail.com
#         liangtao@qiniu.com
#
# Wiki:   http://en.wikipedia.org/wiki/Base64
#
##############################################################################

require 'Base64'

module Qiniu
    module Utils
        module Base64

            def encode_mime (buf)
                Base64.encode64(buf)
            end # encode_mime

            def decode_mime (str)
                Base64.decode64(str)
            end # decode_mime

            def encode_url (buf)
                Base64.encode64(buf)        \
                      .gsub(/\r?\n/, "")    \
                      .sub(/=+$/, "")       \
                      .gsub("+", "-")       \
                      .gsub("/", "_")
            end # encode_url

            def decode_url (str)
                Base64.decode64(
                    str.gsub("_", "/")      \
                       .gsub("-", "+")      \
                       .sub(/$/, "==")
                )
            end # decode_url

        end # module Base64
    end # module Utils
end # module Qiniu
