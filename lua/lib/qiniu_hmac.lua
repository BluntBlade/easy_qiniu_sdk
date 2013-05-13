#!/usr/bin/env lua

--[[
Easy Qiniu Lua SDK

Module: qiniu_hmac.lua

Author: LIANG Tao
Weibo:  @无锋之刃
Email:  amethyst.black@gmail.com
        liangtao@qiniu.com

Wiki:   http://en.wikipedia.org/wiki/Hash-based_message_authentication_code
--]]

require('bit32')
require('qiniu_sha1')

qiniu_hmac = (function ()
    local t  = {}
    local mt = {}

    function mt.__index(table, key)
        return rawget(mt, key)
    end -- mt.__index

    function mt:write(msg)
        self.hash:write(msg)
        return self
    end -- mt:write

    function mt:sum(msg)
        local i_hash = self.hash:sum(msg)
        return self.hash:reset():sum(self.o_key_pad .. i_hash)
    end -- mt:sum

    local HEX_MAP = {
        [0]='0',  [1]='1',  [2]='2',  [3]='3',
        [4]='4',  [5]='5',  [6]='6',  [7]='7',
        [8]='8',  [9]='9',  [10]='a', [11]='b',
        [12]='c', [13]='d', [14]='e', [15]='f'
    }

    function mt:hex_sum(msg)
        local ret = self:sum(msg)
        local hex = {}
        for i = 1, string.len(ret), 1 do
            local ord  = ret:byte(i)
            local high = bit32.extract(ord, 4, 4)
            local low  = bit32.extract(ord, 0, 4)
            hex[#hex+1] = HEX_MAP[high]
            hex[#hex+1] = HEX_MAP[low]
        end -- for
        return table.concat(hex)
    end -- mt:hex_sum

    function mt:reset()
        self.hash:reset():write(self.i_key_pad)
        return self
    end -- mt:reset

    function t.new(hash, secret_key)
        local self = {}
        setmetatable(self, mt)
        self.hash = hash

        local block_size = hash:chunk_size()
        if secret_key:len() > block_size then
            secret_key = hash:reset():sum(secret_key)
            hash:reset()
        end
        if secret_key:len() < block_size then
            secret_key = secret_key .. string.rep("\x00", block_size - secret_key:len())
        end

        self.o_key_pad = secret_key:gsub("(.)", function (chr)
            return string.char(bit32.bxor(chr:byte(1), 0x5C))
        end)
        self.i_key_pad = secret_key:gsub("(.)", function (chr)
            return string.char(bit32.bxor(chr:byte(1), 0x36))
        end)

        self:reset()
        return self
    end -- t.new

    return t
end)()

--[[
print(qiniu_hmac.new(qiniu_sha1.new(), ""):hex_sum(""))
print(qiniu_hmac.new(qiniu_sha1.new(), "key"):hex_sum("The quick brown fox jumps over the lazy dog"))
--]]
