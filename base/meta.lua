require 'help'
local h = [[
Meta: module
contains info about metamethods.
]]

local Meta = {}
help[Meta] = h

function Meta.__help()
    local text = {}
    local pattern, exclude = '^%a+w*', {}
    for k,v in ipairs(help.objects(Meta, pattern, exclude)) do
        table.insert(text, help[v[2]] or v[1] .. '\n')
    end
    local heading = 'MODULE META:'
    local footer = ('-'):rep(80) .. '\n'
    print(heading .. '\n' .. ('='):rep(#heading) .. '\n' .. table.concat(text, footer) .. footer)
end

h = [[
method_names: dict

key: method_name, value: op_string.
E.g. method_names['__add'] = '+'
]]
Meta.method_names = {
    __add = '+',
    __sub = '-',
    __mul = '*',
    __div = '/',
    __mod = '%',     -- the modulo (%) operation
    __pow = '^',     -- the exponentiation (^) operation
    __unm = 'x=>-x',     -- the unary - operation
    __idiv = '//',    -- the floor division (//) operation
    __band = '&',    -- the bitwise AND (&) operation
    __bor = '|',     -- the bitwise OR (|) operation
    __bxor = '~',    -- the bitwise exclusive OR (binary ~) operation
    __bnot = '~',    -- the bitwise NOT (unary ~) operation
    __shl = '<<',     -- the bitwise left shift (<<) operation
    __shr = '>>',     -- the bitwise right shift (>>) operation
    __concat = '..',  -- the concatenation (..) operation
    __eq = '==',      -- the equal (==) operation
    __lt = '<',      -- the less than (<) operation
    __le = '<=',      -- the less equal (<=) operation
    __len = '#',     -- the length (#) operation
    __metatable = 'getmetatable',  -- return value of getmetatable
    __index = 'index',      -- table or function(self, key) -> value; bypass with rawget(key) 
    __newindex = 'newindex', -- table or function(self, key, value) -> value; bypass with rawset(key, value) 
    __call = 'call',        -- __call(self) is called if the table is called 
    __tostring = 'tostring',
}
help[Meta.method_names] = h

h = [[
get_metamethods(t:metatable) -> dict

returns {k: {v, <op_string of k>} | (k,v) in t and Meta.method_names[k]}
]]
function Meta.get_metamethods(t) 
    local res = {} 
    for k,v in pairs(t) do
        if  Meta.method_names[k] 
            then res[k] = {v,  Meta.method_names[k]}
        end
    end
    return res        
end
help[Meta.get_metamethods] = h

h = [[
get_ops(t:metatable) -> dict

returns {<op_string of k>: {v, k} | (k,v) in t and Meta.method_names[k]}
]]
function Meta.get_ops(t) 
    local ops = {}
    local d = Meta.get_metamethods(t) 
    for k,v in pairs(d) do
        ops[v[2]] = {v[1], k}
    end
    return ops
end
help[Meta.get_ops] = h

return Meta
