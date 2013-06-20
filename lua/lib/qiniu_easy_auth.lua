#!/usr/bin/env lua

--[[
Easy Qiniu Lua SDK

Module: qiniu_easy_auth.lua

Author: LIANG Tao
Weibo:  @无锋之刃
Email:  amethyst.black@gmail.com
        liangtao@qiniu.com
--]]

require('qiniu_base64')
require('qiniu_json')
require('qiniu_hmac')
require('qiniu_sha1')

--[[
Qiniu authorization sign (count in Bytes)

| len(key)   | 1 | 28                        | 1 | len(buf)               |
| access key | : | base64 url encoded digest | : | base64 url encoded buf |
--]]

qiniu_easy_auth = (function ()
    local t = {}

    function t.sign(access_key, secret_key, str)
        local encoded_str = qiniu_base64.encode_url(str)

        local hmac = qiniu_hmac.new(qiniu_sha1.new(), secret_key)
        local digest = hmac:write(encoded_str):sum()
        local encoded_digest = qiniu_base64.encode_url(digest)

        return access_key .. ':' .. encoded_digest .. ':' .. encoded_str, nil;
    end -- t.sign

    function t.sign_json(access_key, secret_key, val)
        local str = qiniu_json.marshal(val)
        return t.sign(access_key, secret_key, str)
    end -- t.sign_json

    function t.sign_request(req, secret_key, inc_body)
        local hmac = qiniu_hmac.new(qiniu_sha1.new(), secret_key)
        local path = req.url.path
        hmac:write(path):write("\n")
        if inc_body then
            hmac:write(req.body)
        end

        local digest = qiniu_base64.encode_url(hmac:sum())
        return digest
    end -- t.sign_request

    local function __is_inc_body(req)
        local headers = req.headers
        if headers == nil then
            return false
        end

        for k, v in pairs(headers) do
            if k:upper() == 'CONTENT-TYPE' then
                for i, v2 in ipairs(v) do
                    local begin = v2:lower():find(
                        'application/x-www-form-urlencoded',
                        1,
                        true
                    )
                    if begin ~= nil then
                        return true
                    end
                end -- for
            end
        end -- for
        return false
    end -- __is_inc_body

    function t.new_transport(access_key, secret_key)
        local tr = {
            round_trip = function (self, req)
                local digest = t.sign_request(
                    req,
                    secret_key,
                    __is_inc_body(req)
                )
                local token = access_key .. ':' .. digest
                if req.headers == nil then
                    req.headers = {}
                end
                req.headers.Authorization = {[1]='QBox ' .. token}
                return self:round_trip(req)
            end
        }
        return qiniu_transport.new(tr)
    end -- t.new_transport

    function t.new_client(access_key, secret_key)
        local tr = t.new_transport(access_key, secret_key)
        local client = qiniu_client.new(tr)
        return client
    end -- t.new_client

    return t
end)() -- qiniu_easy_auth
