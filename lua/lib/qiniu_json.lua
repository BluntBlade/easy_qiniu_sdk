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

    local function __escape_str(str)
        return str:gsub("\\", "\\\\")
                  :gsub("\"", "\\\"")
                  :gsub("/", "\\/")
                  :gsub("\b", "\\b")
                  :gsub("\f", "\\f")
                  :gsub("\n", "\\n")
                  :gsub("\r", "\\r")
                  :gsub("\t", "\\t")
    end -- __escape_str

    local function __unescape_str(str)
        return str:gsub("\\\"", "\"")
                  :gsub("\\/", "/")
                  :gsub("\\b", "\b")
                  :gsub("\\f", "\f")
                  :gsub("\\n", "\n")
                  :gsub("\\r", "\r")
                  :gsub("\\t", "\t")
                  :gsub("\\\\", "\\")
    end -- __enscape_str

    local function __marshal(obj)
        local val_type = type(val)

        if val_type == 'table' then
            if #val == 0 then
                -- As a hash

                local tmp = {}
                tmp[#tmp+1] = '{'

                local cnt = 0
                for k, v in pairs(val) do
                    local str = __marshal(v)
                    if str ~= nil then
                        if cnt == 0 then
                            tmp[#tmp+1] = '"' .. __escape_str(k) .. '":'
                        else
                            tmp[#tmp+1] = ',"' .. __escape_str(k) .. '":'
                        end

                        tmp[#tmp+1] = str
                        cnt = cnt + 1
                    end
                end

                tmp[#tmp+1] = '}'
                return table.concat(tmp)
            else
                -- As an array

                local tmp = {}
                tmp[#tmp+1] = '['

                local cnt = 0
                for i, v in ipairs(val) do
                    local str = __marshal(v)
                    if str ~= nil then
                        if cnt > 0 then
                            tmp[#tmp+1] = ','
                        end

                        tmp[#tmp+1] = str
                        cnt = cnt + 1
                    end
                end

                tmp[#tmp+1] = ']'
                return table.concat(tmp)
            end
        end
        if val_type == 'string' then
            return '"' .. __escape_str(val) .. '"'
        end
        if val_type == 'number' then
            return tostring(val)
        end
        if val_type == 'boolean' then
            return tostring(val)
        end
        if val_type == 'nil' then
            return 'null'
        end

        return nil
    end -- __marshal
    
    function t.marshal(obj)
        return __marshal(obj)
    end -- t.marshal

    local COMMA         = 0x001
    local COLON         = 0x002
    local OPEN_BRACE    = 0x004
    local CLOSE_BRACE   = 0x008
    local OPEN_BRACKET  = 0x010
    local CLOSE_BRACKET = 0x020 
    local STRING        = 0x040
    local NUMBER        = 0x080
    local BOOLEAN       = 0x100
    local NULL          = 0x200
    local SPACES        = 0x400
    local ERROR         = 0x800

    local SCALAR        = bit32.bor(STRING, NUMBER, BOOLEAN, NULL)

    local function __lex(str)
        return function (s)
            s.pos = s.pos + 1
            local chr = s.str:sub(s.pos, s.pos)

            if chr == ',' then
                return COMMA, chr
            end

            if chr == ':' then
                return COLON, chr
            end

            if chr == '"' then
                local cnt = 0
                local prev_chr = nil
                for pos = s.pos + 1, s.len, 1 do
                    chr = s.str:sub(pos, pos)
                    if chr == '"' and prev_chr ~= '\\' then
                        local str = __unescape_str(
                            s.str:sub(s.pos + 1, s.pos + 1 + cnt - 1)
                        )
                        s.pos = pos
                        return STRING, str 
                    end
                    cnt      = cnt + 1
                    prev_chr = chr
                end -- for
                return ERROR, nil
            end

            local int_begin, int_end = s.str:find("^[-+]?[1-9]%d*", s.pos)
            if int_begin == nil then
                int_begin, int_end = s.str:match("^[-+]?0", s.pos)
            end
            if int_begin ~= nil then
                local frac_begin, frach_end = s.str:find("\\.%d+", int_end)
                if frac_begin ~= nil then
                    return NUMBER, tonumber(
                        s.str:sub(int_begin, frac_end)
                    )
                end
                return NUMBER, tonumber(
                    s.str:sub(int_begin, int_end)
                )
            end

            local true_begin, true_end = s.str:find("true", s.pos, true)
            if true_begin ~= nil then
                return BOOLEAN, true
            end
            local false_begin, false_end = s.str:find("false", s.pos, true)
            if false_begin ~= nil then
                return BOOLEAN, false
            end

            local null_begin, null_end = s.str:find("null", s.pos, true)
            if null_begin ~= nil then
                return NULL, nil
            end

            if chr == '{' then
                return OPEN_BRACE, chr
            end
            if chr == '}' then
                return CLOSE_BRACE, chr
            end

            if chr == '[' then
                return OPEN_BRACKET, chr
            end
            if chr == ']' then
                return CLOSE_BRACKET, chr
            end

            local space_begin, space_end = s.str:find("%s", s.pos)
            if space_begin ~= nil then
                s.pos = space_end
                return SPACES, nil
            end

            return ERROR, nil
        end,
        {
            pos = 0,
            len = str:len(),
            str = str
        },
        nil
    end -- __lex

    local START           = 1
    local OBJECT          = 2
    local OBJECT_KEY      = 3
    local OBJECT_COLON    = 4
    local OBJECT_CONTINUE = 5
    local ARRAY           = 6
    local ARRAY_CONTINUE  = 7
    local LEVEL_DOWN      = 8

    local function __yacc(str)
        local state  = {[1]=START}
        local index  = {[1]=nil}
        local object = {[1]=nil}
        local level  = 1

        for token, val in __lex(str) do
            if token == ERROR then
                return nil, 'Invalid JSON object.'
            end

            if token ~= SPACES then
                if state[level] == START then

                    if token == OPEN_BRACE then
                        level         = level + 1
                        object[level] = {}
                        state[level]  = OBJECT
                        index[level]  = nil
                    elseif token == OPEN_BRACKET then
                        level         = level + 1
                        object[level] = {}
                        state[level]  = ARRAY
                        index[level]  = 0
                    else
                        return nil, 'A JSON object shall be a hash or array.'
                    end

                elseif state[level] == OBJECT then

                    if token == STRING then
                        index[level] = val
                        state[level] = OBJECT_KEY
                    elseif token == CLOSE_BRACE then
                        -- Empty hash
                        state[level] = LEVEL_DOWN
                    else
                        return nil, 'Expect a string that shall be a key in hash.'
                    end

                elseif state[level] == OBJECT_KEY then

                    if token == COLON then
                        state[level] = OBJECT_COLON
                    else
                        return nil, 'Expect the key is followed by a colon.'
                    end

                elseif state[level] == OBJECT_COLON then

                    if token == OPEN_BRACE then
                        level         = level + 1
                        object[level] = {}
                        state[level]  = OBJECT
                        index[level]  = nil
                    elseif token == OPEN_BRACKET then
                        level         = level + 1
                        object[level] = {}
                        state[level]  = ARRAY
                        index[level]  = 0
                    elseif bit32.band(token, SCALAR) ~= 0 then
                        local obj = object[level]
                        obj[index[level]] = val
                        state[level] = OBJECT_CONTINUE
                    else
                        return nil, 'Expect a value set for the key "' .. index[level] .. '"'
                    end

                elseif state[level] == OBJECT_CONTINUE then

                    if token == COMMA then
                        state[level] = OBJECT
                    elseif token == CLOSE_BRACE then
                        state[level] = LEVEL_DOWN
                    else
                        return nil, 'Expect the end or more content of the hash.'
                    end

                elseif state[level] == ARRAY then

                    if token == OPEN_BRACE then
                        level         = level + 1
                        object[level] = {}
                        index[level]  = nil
                        state[level]  = OBJECT
                    elseif token == OPEN_BRACKET then
                        level         = level + 1
                        object[level] = {}
                        index[level]  = 0
                        state[level]  = ARRAY
                    elseif bit32.band(token, SCALAR) ~= 0 then
                        index[level] = index[level] + 1

                        local obj = object[level]
                        obj[index[level]] = val

                        state[level] = ARRAY_CONTINUE
                    elseif token == CLOSE_BRACKET then
                        -- Empty array
                        state[level] = LEVEL_DOWN
                    else
                        return nil, 'Expect a new element.'
                    end

                elseif state[level] == ARRAY_CONTINUE then

                    if token == COMMA then
                        state[level] = ARRAY
                    elseif token == CLOSE_BRACKET then
                        state[level] = LEVEL_DOWN
                    else
                        return nil, 'Expect the end or more elements of the array.'
                    end

                end

                if state[level] == LEVEL_DOWN then
                    level = level - 1
                    if level == 1 then
                        -- The whole object is closed
                        break
                    end

                    local obj = object[level]
                    if state[level] == OBJECT then
                        obj[index[level]] = object[level+1]
                    elseif state[level] == ARRAY then
                        index[level] = index[level] + 1
                        obj[index[level]] = object[level+1]
                    end
                end
            end -- if token ~= SPACES
        end -- for

        if state[level] == START then
            return object[level+1], nil
        end        
        return nil, 'Invalid JSON object.'
    end -- __yacc

    function t.unmarshal(str)
        return __yacc(str)
    end -- t.unmarshal

    return t
end)()

--[[
print(qiniu_json.marshal({[1]=1, [2]="2\f", [3]=true}))
local obj, err = qiniu_json.unmarshal('{"name" : "Tom"}')
print(err)
print(obj.name)
local arr, err = qiniu_json.unmarshal('["Tom"]')
print(err)
print(arr[1])
--]]
