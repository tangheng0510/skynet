
local function GetDump(value, description, nesting)
    if type(nesting) ~= "number" then nesting = 3 end

    local lookupTable = {}
    local result = {}

    local function _v(v)
        if type(v) == "string" then
            v = "\"" .. v .. "\""
        end
        local rst = tostring(v) or ""
        return rst
    end
    local traceback = string.split(debug.traceback("", 2), "\n")
    local text = string.format("<%s>dump from: %s ",
                                description or "--",string.trim(traceback[3]))

    local function _dump(value, description, indent, nest, keylen)
        description = description or "<var>"
        local spc = ""
        if type(keylen) == "number" then
            spc = string.rep(" ", keylen - string.len(_v(description)))
        end
        if type(value) ~= "table" then
            local key = _v(description)
            key = "["..key.."]"
            result[#result +1 ] = string.format("%s%s%s = %s", indent,key, spc, _v(value))..","
        elseif lookupTable[value] then
            result[#result +1 ] = string.format("%s%s%s = *REF*", indent, description, spc)
        else
            lookupTable[value] = true
            if nest > nesting then
                result[#result +1 ] = string.format("%s%s = *MAX NESTING*", indent, description)
            else
                local key = _v(description)
                key = "["..key.."]"
                result[#result +1 ] = string.format("%s%s = {", indent, key)
                local indent2 = indent.."    "
                local keys = {}
                local keylen = 0
                local values = {}
                for k, v in pairs(value) do
                    keys[#keys + 1] = k
                    local vk = _v(k)
                    local vkl = string.len(vk)
                    if vkl > keylen then keylen = vkl end
                    values[k] = v
                end
                table.sort(keys, function(a, b)
                    if type(a) == "number" and type(b) == "number" then
                        return a < b
                    else
                        return tostring(a) < tostring(b)
                    end
                end)
                for i, k in ipairs(keys) do
                    _dump(values[k], k, indent2, nest + 1, keylen)
                end
                result[#result +1] = string.format("%s},", indent)
            end
        end
    end
    _dump(value, description, "", 1)

    for i, line in ipairs(result) do
        text = text .. "\n" .. line
    end
    return text
end

function GetDumpStr(value, nesting)
    if value==nil then
        return "nil"
    else
        return GetDump(value, "", nesting)
    end
end
