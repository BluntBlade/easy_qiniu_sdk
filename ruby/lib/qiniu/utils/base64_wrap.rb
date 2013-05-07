#!/usr/bin/env ruby
# encoding : utf-8

##############################################################################
#
# Easy Qiniu Ruby SDK
#
# Module: qiniu/utils/base64_wrap.rb
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

            def self.encode_mime (buf)
                Base64.encode64(buf)
            end # self.encode_mime

            def self.decode_mime (str)
                Base64.decode64(str)
            end # self.decode_mime

            def self.encode_url (buf)
                Base64.encode64(buf)        \
                      .gsub(/\r?\n/, "")    \
                      .gsub("+", "-")       \
                      .gsub("/", "_")
            end # self.encode_url

            def self.decode_url (str)
                Base64.decode64(
                    str.gsub("_", "/")      \
                       .gsub("-", "+")
                )
            end # self.decode_url

        end # module Base64
    end # module Utils
end # module Qiniu
