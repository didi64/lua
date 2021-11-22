--[[ 
organize as package
Table_basics ->Table/init.lua
Table/iteratore
Table/copy
...
function unrequire(m)
    package.loaded[m] = nil
    _G[m] = nil
end

unrequire 'Table_Basics'
Table = require 'Table_Basics'
a={1,2,3,4,5}
for k,v in table.ppairs(a,'^.*') do print(k,v) end
--]]






require 'help'
-- require 'table_aux'
-- Type = require 'Type'


local h 
table.__mt =  {__index = table}

h = [[
bless(t:table without a metatable)

short for setmetatable(t, {__index = table}) 
]]
function table.bless(t)
   local msg = type(t) ~= 'table' and string.format('table expected, got %s.', type(t)) or
               getmetatable(t) and 'able has already metatable'
   if msg then 
       error(msg) 
   else
       setmetatable(t, table.__mt)
   end    
end

h=[[
iextend(t, ...:tables) 

appends the list-elements of tables to t using table.move
]]
function table.iextend(t, ...)
    local arg = table.pack(...)
    for _,v in ipairs(arg) do
        if  type(v) == 'table' then table.move(v, 1, #v, #t+1, t) end
    end
end
help[table.iextend]=h


h=[[
append(t:table,conf:table)
appends the list-elements of tables to t using iter.

conf = {iter = (()=>next,nil), replace = true}


How to pass the config table?
]]
function table.append(t,...)
    local arg = table.pack(...)
    for _,v in ipairs(arg) do
        if  type(v) == 'table' then table.move(v, 1, #v, #t+1, t) end
    end
end
help[table.iextend]=h






h=[[
table.irev(t)
if ipairs sees the pair (k,v) then k=table.irev(t)[v] 
]]
function table.irev(t)
    local res = {}
    for i,v in ipairs(t) do
        res[v] = i
    end
    return res
end
help[table.irev]=h


h=[[
table.irevl(t)
if ipairs sees the pair (k,v) then k is appended to the list with key v
]]
function table.irevl(t)
    local res = {}
    for i,v in ipairs(t) do
        if not res[v] then 
            res[v] = {i}
        else
            res[v][#res[v] +1] = i 
        end
    end
    return res
end
help[table.irev]=h



h=[[
rev(t:table, iter:2-iterator) -> table

if the 2-iterator sees the pair (k,v) then v is a key of the returned table with value k
]]
function table.rev(t, iter) 
    local iter = iter or pairs
    local res = {}
    for i,v in iter(t) do
        res[v] = i
    end
    return res
end
help[table.rev]=h

function table.revl(t, iter) 
    local iter = iter or pairs
    local res = {}
    for i,v in iter(t) do
        if not res[v] then 
            res[v] = {i}
        else
            res[v][#res[v] +1] = i 
        end
    end
    return res
end

h = [[
index(l:list, x:obj, idx:number) -> number|nil
returns the least index i>=idx so that l[i] == x, or nil
]]
function table.index(l, x, idx)
    idx = idx or 0
    for i = idx, #l do
        if l[i] ==  x then 
            return i
        end
    end
end
help[table.index] = h    

h = [[
list2set(t:list)->set
returns {t[i] for 0<i<#t}
]]
function table.list2set(t)
    local res = {}
    for i,v in ipairs(t) do
        res[v] = true
    end
    return res
end
help[table.list2set] = h

h=[[
iapply(t:table|any, f:function(any)->any, iter=ipairs, 2-iter)

returns f(t) if t is not a table,
else {k=f(x) for k,x in iter(t)}
]]
function table.iapply(t, f, iter)
    if  type(t) ~= 'table' then return f(t) end
    local iter = iter or ipairs
    local res={}
    for k,v in iter(t) do
        res[k]= f(v)
    end
    return res
end
help[table.iapply]=h

h = [[
ipack([i=2],iter,state,k) -> list
]]
function table.ipack(...)
    local i, iter, s, k0
    if  select('#',...) == 3 then
        i, iter, s, k0 = 2, ...
    else
        i, iter, s, k0 = ...
    end
    local res = {}
    for k,v in iter,s,k0 do
        res[#res+1] = i == 1 and k or v
    end
    return res    
end



return table









