#!/usr/bin/env lua

--[[
Easy Qiniu Lua SDK

Module: qiniu_json.lua

Author: LIANG Tao
Weibo:  @无锋之刃
Email:  amethyst.black@gmail.com
        liangtao@qiniu.com

Wiki:   http://en.wikipedia.org/wiki/JSON
--]]

require('string')

qiniu_json = (function ()
    local t = {}

    local function __marshal(obj)
        local obj_type = type(obj)

        if obj_type == 'table' then
            if #obj == 0 then
                -- As a hash

                local tbl = {}
                tbl[#tbl+1] = '{'

                local cnt = 0
                for k, v in pairs(obj) do
                    local str = __marshal(v)
                    if str ~= nil then
                        if cnt == 0 then
                            tbl[#tbl+1] = '"' .. k .. '":'
                        else
                            tbl[#tbl+1] = ',"' .. k .. '":'
                        end

                        tbl[#tbl+1] = str
                        cnt = cnt + 1
                    end
                end

                tbl[#tbl+1] = '}'
                return table.concat(tbl)
            else
                -- As an array

                local tbl = {}
                tbl[#tbl+1] = '['

                local cnt = 0
                for i, v in ipairs(obj) do
                    local str = __marshal(v)
                    if str ~= nil then
                        if cnt > 0 then
                            tbl[#tbl+1] = ','
                        end

                        tbl[#tbl+1] = str
                        cnt = cnt + 1
                    end
                end

                tbl[#tbl+1] = ']'
                return table.concat(tbl)
            end
        end
        if obj_type == 'string' then
            new_str = obj:gsub("\\", "\\\\")
                         :gsub("\"", "\\\"")
                         :gsub("/", "\\/")
                         :gsub("\b", "\\b")
                         :gsub("\f", "\\f")
                         :gsub("\n", "\\n")
                         :gsub("\r", "\\r")
                         :gsub("\t", "\\t")
            return '"' .. new_str .. '"'
        end
        if obj_type == 'number' then
            return tostring(obj)
        end
        if obj_type == 'boolean' then
            return tostring(obj)
        end
        if obj_type == 'nil' then
            return 'null'
        end

        return nil
    end -- __marshal
    
    function t.marshal(obj)
        return __marshal(obj)
    end -- t.marshal

    function t.unmarshal(str)
    end -- t.unmarshal

    return t
end)()

--[[
print(qiniu_json.marshal({[1]=1, [2]="2\f", [3]=true}))
--]]
