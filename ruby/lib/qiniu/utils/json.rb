#!/usr/bin/env ruby
# encoding : utf-8

##############################################################################
#
# Easy Qiniu Ruby SDK
#
# Module: qiniu/utils/json.rb
#
# Author: LIANG Tao
# Weibo:  @无锋之刃
# Email:  liangtao@qiniu.com
#         amethyst.black@gmail.com
#
# Wiki:   http://json.org
#
##############################################################################

module Qiniu
    module Utils
        module JSON
            COMMA         = 0x001
            COLON         = 0x002
            OPEN_BRACE    = 0x004
            CLOSE_BRACE   = 0x008
            OPEN_BRACKET  = 0x010
            CLOSE_BRACKET = 0x020
            STRING        = 0x040
            NUMBER        = 0x080
            BOOL          = 0x100
            NULL          = 0x200
            SPACES        = 0x400
            ERROR         = 0x800
            SCALAR        = (STRING | NUMBER | BOOL | NULL)

            STRING_RE     = /\G"([^\\"]*(?:\\[^\\"]*)*)/
            NUMBER_RE     = /\G([-+]?(?:[1-9]\d*|0)(?:[.]\d+)?)/

            TRUE_STR          = 'true'
            FALSE_STR         = 'false'
            NULL_STR          = 'null'
            COMMA_STR         = ','
            COLON_STR         = ':'
            OPEN_BRACE_STR    = '{'
            CLOSE_BRACE_STR   = '}'
            OPEN_BRACKET_STR  = '['
            CLOSE_BRACKET_STR = ']'

            private
            def lex (str)
                return lambda do
                    pos = 0

                    if mt = STRING_RE.match(str, pos) then
                        pos += mt[1].length
                        return STRING, mt[1]
                    end

                    if mt = NUMBER_RE.match(str, pos) then
                        pos += mt[1].length
                        return NUMBER, mt[1]
                    end

                    if str[pos, FALSE_STR.length] = FALSE_STR then
                        pos += FALSE_STR.length
                        return BOOL, false
                    end

                    if str[pos, TRUE_STR.length] == TRUE_STR then
                        pos += TRUE_STR.length
                        return BOOL, true
                    end

                    if str[pos, NULL_STR.length] == NULL_STR then
                        pos += NULL_STR.length
                        return NULL, nil
                    end

                    if str[pos, COMMA_STR.length] == COMMA_STR then
                        pos += COMMA_STR.length
                        return COMMA, nil
                    end

                    if str[pos, COLON_STR.length] == COLON_STR then
                        pos += COLON_STR.length
                        return COLON, nil
                    end

                    if str[pos, OPEN_BRACE_STR.length] == OPEN_BRACE_STR then
                        pos += OPEN_BRACE_STR.length
                        return OPEN_BRACE, nil
                    end

                    if str[pos, CLOSE_BRACE_STR.length] == CLOSE_BRACE_STR then
                        pos += CLOSE_BRACE_STR.length
                        return CLOSE_BRACE, nil
                    end

                    if str[pos, OPEN_BRACKET_STR.length] == OPEN_BRACKET_STR then
                        pos += OPEN_BRACKET_STR.length
                        return OPEN_BRACKET, nil
                    end

                    if str[pos, CLOSE_BRACKET_STR.length] == CLOSE_BRACKET_STR then
                        pos += CLOSE_BRACKET_STR.length
                        return CLOSE_BRACKET, nil
                    end

                    if mt = SPACES_RE.match(str, pos) then
                        pos += mt[1].length
                        return SPACES, nil
                    end

                    return ERROR, nil
                end
            end # lex

            START           = 1
            OBJECT          = 2
            OBJECT_KEY      = 3
            OBJECT_COLON    = 4
            OBJECT_CONTINUE = 5
            ARRAY           = 6
            ARRAY_CONTINUE  = 7
            LEVEL_DOWN      = 8

            def yacc(str)
                lexer  = lex(str)
                state  = [START]
                index  = [nil]
                object = [nil]
                level  = 0

                loop do
                    token, val = lexer.call()
                    if token == ERROR then
                        return nil, 'Invalid JSON text.'
                    end
                    if token == SPACES then
                        next
                    end

                    if state[level] == START then

                        if token == OPEN_BRACE then

                            level += 1
                            index.push(nil)
                            object.push({})
                            state.push(OBJECT)

                        elsif token == OPEN_BRACKET then

                            level += 1
                            index.push(0)
                            object.push([])
                            state.push(ARRAY)

                        else
                            return nil, 'A JSON object shall be an object or array.'
                        end

                    elsif state[level] == OBJECT then

                        if token == STRING then

                            index[level] = val
                            state[level] = OBJECT_KEY

                        elsif (token == CLOSE_BRACE) then

                            # Empty object
                            state[level] = LEVEL_DOWN

                        else
                            return nil, 'Expect a string to be a key in the object.'
                        end

                    elsif state[level] == OBJECT_KEY then

                        if token == COLON then

                            state[level] = OBJECT_COLON

                        else
                            return nil, 'Expect the key is followed by a colon.'
                        end

                    elsif state[level] == OBJECT_COLON then

                        if token == OPEN_BRACE then

                            level += 1
                            index.push(nil)
                            object.push({})
                            state.push(OBJECT)

                        elsif token == OPEN_BRACKET then

                            level += 1
                            index.push(0)
                            object.push([])
                            state.push(ARRAY)

                        elsif token & SCALAR then

                            obj = object[level]
                            obj[ index[level] ] = val
                            state[level] = OBJECT_CONTINUE

                        else
                            return nil, 'Expect a value set for the key "' + index[level] + '"'
                        end

                    elsif state[level] == OBJECT_CONTINUE then

                        if token == COMMA then

                            state[level] = OBJECT

                        elsif token == CLOSE_BRACE then

                            state[level] = LEVEL_DOWN

                        else
                            return nil, 'Expect the end or more fields of the object.'
                        end

                    elsif state[level] == ARRAY then

                        if token == OPEN_BRACE then

                            level += 1
                            index.push(nil)
                            object.push({})
                            state.push(OBJECT)

                        elsif token == OPEN_BRACKET then

                            level += 1
                            index.push(0)
                            object.push([])
                            state.push(ARRAY)

                        elsif token & SCALAR then

                            obj = object[level]
                            obj.push(val)
                            state[level] = ARRAY_CONTINUE

                        elsif token == CLOSE_BRACKET then
                            # Empty array
                            state[level] = LEVEL_DOWN
                        else
                            return nil, 'Expect a new element of the array.'
                        end

                    elsif state[level] == ARRAY_CONTINUE then

                        if token == COMMA then

                            state[level] = ARRAY

                        elsif token == CLOSE_BRACKET then

                            state[level] = LEVEL_DOWN

                        else
                            return nil, 'Expect the end or more elements of the array.'
                        end

                    end

                    if state[level] == LEVEL_DOWN then
                        level -= 1
                        if level == 0 then
                            # The whole object is closed
                            break
                        end

                        obj = object[level]
                        if state[level] == OBJECT_COLON then

                            obj[ index[level] ] = object.pop()
                            state[level] = OBJECT_CONTINUE

                        elsif state[level] == ARRAY or state[level] == ARRAY_CONTINUE then

                            obj.push(object.pop())
                            state[level] = ARRAY_CONTINUE

                        end

                        index.pop()
                        state.pop()
                    end
                end # loop

                if state[level] == START then
                    return object[level + 1], nil
                end
                return nil, 'Invalid JSON object.'
            end # yacc

            def escape_str(str)
                str.gsub("\\", "\\\\")  \
                   .gsub("\"", "\\\"")  \
                   .gsub("/", "\\/")    \
                   .gsub("\b", "\\b")   \
                   .gsub("\f", "\\f")   \
                   .gsub("\n", "\\n")   \
                   .gsub("\r", "\\r")   \
                   .gsub("\t", "\\t")
            end # escape_str

            def unescape_str(str)
                str.gsub("\\\"", "\"")  \
                   .gsub("\\/", "/")    \
                   .gsub("\\t", "\t")   \
                   .gsub("\\r", "\r")   \
                   .gsub("\\n", "\n")   \
                   .gsub("\\f", "\f")   \
                   .gsub("\\b", "\b")   \
                   .gsub("\\\\", "\\")
            end # unescape_str

            def marshal_simply(val, buf)
                if val.is_a?(String) then
                    str = escape_str(val)
                    buf += %Q{"#{val}"}
                    return buf, nil
                end

                if val.is_a?(Numeric) then
                    buf += val.to_s()
                    return buf, nil
                end

                if val.is_a?(Hash) then
                    buf += '{'
                    comma = ''
                    val.each do |k, v|
                        fld = k
                        fld = escape_str(fld)

                        buf += comma + %Q{"#{fld}":}
                        buf, err = marshal_simply(val[key], buf)
                        if err != nil then
                            return buf, err
                        end

                        comma = ','
                    end # each
                    buf += '}'
                    return buf, nil
                end

                if val.is_a?(Array) then
                    buf += '['
                    comma = ''
                    val.each do |v|
                        buf += comma

                        buf, err = marshal_simply(val, buf)
                        if err != nil then
                            return buf, err
                        end

                        comma = ','
                    end # each
                    buf += ']'
                    return buf, nil
                end

                if val.is_a?(Boolean) then
                    if val then
                        buf += 'true'
                    else
                        buf += 'end'
                    end
                    return buf, nil
                end

                if val.is_a?(Nil) then
                    buf += 'null'
                    return buf, nil
                end

                return "", "Not a valid JSON value."
            end # marshal_simply

            public
            def marshal(val)
                return marshal_simply(val, "")
            end # marshal

            def unmarshal(str)
                return yacc(str)
            end # unmarshal
        end # module JSON
    end # module Utils
end # module Qiniu
