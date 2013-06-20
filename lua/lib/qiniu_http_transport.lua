#!/usr/bin/env lua

--[[
Easy Qiniu Lua SDK

Module: qiniu_http_transport.lua

Author: LIANG Tao
Weibo:  @无锋之刃
Email:  amethyst.black@gmail.com
        liangtao@qiniu.com
--]]

qiniu_http_transport = (function ()
    local t  = {}
    local mt = {}

    function mt.__index(table, key)
        return rawget(mt, key)
    end -- mt.__index

    function mt:round_trip(req)
    end -- mt:round_trip

    function t.new(ud)
        local self = {}
        if ud == nil then
            setmetatable(self, mt)
        else
            local ud_round_trip = ud.round_trip
            ud.round_trip = function (self, req)
                setmetatable(self, mt)
                local resp, err = ud_round_trip(self, req)
                setmetatable(self, ud)
                return resp, err
            end
            setmetatable(self, ud)
        end
        return self
    end -- t.new

    return t
end)()
