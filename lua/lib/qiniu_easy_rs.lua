#!/usr/bin/env lua

--[[
Easy Qiniu Lua SDK

Module: qiniu_easy_rs.lua

Author: LIANG Tao
Weibo:  @无锋之刃
Email:  amethyst.black@gmail.com
        liangtao@qiniu.com
--]]

require('qiniu_utils_base64')
require('qiniu_easy_auth')
require('qiniu_easy_conf')

qiniu_easy_rs = (function ()
    local t  = {}
    local mt = {}

    function mt.__index(table, key)
        return rawget(mt, key)
    end -- mt.__index

    function mt:stat(bucket, key)
        local url = qiniu_conf.RS_HOST .. t.uri_stat(bucket, key)

        local ret, err = self.client.get(url)
        if err ~= nil then
            return nil, err
        end

        local ret_obj = nil
        ret_obj, err = qiniu_json.unmarshal(ret)
        return ret_obj, err
    end -- mt:stat

    function mt:delete(bucket, key)
        local url = qiniu_conf.RS_HOST .. t.uri_delete(bucket, key)

        local ret, err = self.client.get(url)
        if err ~= nil then
            return nil, err
        end

        local ret_obj = nil
        ret_obj, err = qiniu_json.unmarshal(ret)
        return ret_obj, err
    end -- mt:delete

    function mt:copy(src_bucket, src_key, dst_bucket, dst_key)
        local url = qiniu_conf.RS_HOST .. t.uri_copy(
            src_bucket,
            src_key,
            dst_bucket,
            dst_key
        )

        local ret, err = self.client.get(url)
        if err ~= nil then
            return nil, err
        end

        local ret_obj = nil
        ret_obj, err = qiniu_json.unmarshal(ret)
        return ret_obj, err
    end -- mt:copy

    function mt:move(src_bucket, src_key, dst_bucket, dst_key)
        local url = qiniu_conf.RS_HOST .. t.uri_move(
            src_bucket,
            src_key,
            dst_bucket,
            dst_key
        )

        local ret, err = self.client.get(url)
        if err ~= nil then
            return nil, err
        end

        local ret_obj = nil
        ret_obj, err = qiniu_json.unmarshal(ret)
        return ret_obj, err
    end -- mt:move

    function mt:batch(op)
        local url = qiniu_conf.RS_HOST .. '/batch'
        local args = { op = op }

        local ret, err = self.client.post_form(url, args)
        if err ~= nil then
            return nil, err
        end

        local ret_obj = nil
        ret_obj, err = qiniu_json.unmarshal(ret)
        return ret_obj, err
    end -- mt:batch

    function mt:batch_stat(entries)
        local op = {}
        for i, v in ipairs(entries) do
            op[#op+1] = t.uri_stat(v.bucket, v.key)
        end -- for
        return self:batch(op)
    end -- mt:batch_stat

    function mt:batch_delete(entries)
        local op = {}
        for i, v in ipairs(entries) do
            op[#op+1] = t.uri_delete(v.bucket, v.key)
        end -- for
        return self:batch(op)
    end -- mt:batch_delete

    function mt:batch_copy(entries)
        local op = {}
        for i, v in ipairs(entries) do
            op[#op+1] = t.uri_copy(
                v.src_bucket,
                v.src_key,
                v.dst_bucket,
                v.dst_key
            )
        end -- for
        return self:batch(op)
    end -- mt:batch_copy

    function mt:batch_move(entries)
        local op = {}
        for i, v in ipairs(entries) do
            op[#op+1] = t.uri_move(
                v.src_bucket,
                v.src_key,
                v.dst_bucket,
                v.dst_key
            )
        end -- for
        return self:batch(op)
    end -- mt:batch_move

    function t.new(access_key, secret_key)
        local self = {}
        if access_key == nil then
            access_key = qiniu_conf.ACCESS_KEY
        end
        if secret_key == nil then
            secret_key = qiniu_conf.SECRET_KEY
        end

        self.access_key = access_key
        self.secret_key = secret_key
        self.client = qiniu_auth.new_client(access_key, secret_key)

        return self
    end -- t.new

    function t.uri_stat(bucket, key)
        local id = qiniu_base64.encode_url(bucket .. ':' .. key)
        return '/stat/' .. id
    end -- t.uri_stat

    function t.uri_delete(bucket, key)
        local id = qiniu_base64.encode_url(bucket .. ':' .. key)
        return '/delete/' .. id
    end -- t.uri_delete

    function t.uri_copy(src_bucket, src_key, dst_bucket, dst_key)
        local src_id = qiniu_base64.encode_url(src_bucket .. ':' .. src_key)
        local dst_id = qiniu_base64.encode_url(dst_bucket .. ':' .. dst_key)
        return '/copy/' .. src_id .. '/' .. dst_id
    end -- t.uri_copy

    function t.uri_move(src_bucket, src_key, dst_bucket, dst_key)
        local src_id = qiniu_base64.encode_url(src_bucket .. ':' .. src_key)
        local dst_id = qiniu_base64.encode_url(dst_bucket .. ':' .. dst_key)
        return '/move/' .. src_id .. '/' .. dst_id
    end -- t.uri_move

    function t.token_for_get(args)
        local policy = {}
        if args.scope ~= nil then
            policy.S = args.scope
        end
        if args.expires ~= nil then
            policy.E = args.expires + time()
        end

        local access_key = args.access_key
        if access_key == nil then
            access_key = qiniu_conf.ACCESS_KEY
        end

        local secret_key = args.secret_key
        if secret_key == nil then
            secret_key = qiniu_conf.SECRET_KEY
        end

        local token = qiniu_auth.sign_json(access_key, secret_key, policy)
        return token
    end -- t.token_for_get

    function t.token_for_put(args)
        local policy = {}
        if args.scope ~= nil then
            policy.scope = args.scope
        end
        if args.expires ~= nil then
            policy.expires = args.expires + time()
        end

        if args.callback_url ~= nil then
            policy.callback_url = args.callback_url
        elseif args.callbackUrl ~= nil then
            policy.callback_url = args.callbackUrl
        end

        if args.callback_body_type ~= nil then
            policy.callback_body_type = args.callback_body_type
        elseif args.callbackBodyType ~= nil then
            policy.callback_body_type = args.callbackBodyType
        end

        if args.async_ops ~= nil then
            policy.async_ops = args.async_ops
        elseif args.asyncOps ~= nil then
            policy.async_ops = args.asyncOps
        end

        if args.customer ~= nil then
            policy.customer = args.customer
        end
        if args.escape ~= nil then
            policy.escape = args.escape
        end

        if args.detect_mime ~= nil then
            policy.detect_mime = args.detect_mime
        elseif args.detectMime ~= nil then
            policy.detect_mime = args.detectMime
        end
            
        local access_key = args.access_key
        if access_key == nil then
            access_key = qiniu_conf.ACCESS_KEY
        end

        local secret_key = args.secret_key
        if secret_key == nil then
            secret_key = qiniu_conf.SECRET_KEY
        end

        local token = qiniu_auth.sign_json(access_key, secret_key, policy)
        return token
    end -- t.token_for_put

    return t
end)() -- qiniu_easy_rs
