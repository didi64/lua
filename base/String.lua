-- upgrade the string class
require 'help'
-- require 'iterators'

string.__class = 'String' 
string.__isA = {String = true}
string.__mt = getmetatable('') 

h = [=[
string([a:number|nil [, b:number|nil [, c:number|nil]]]) -> string

returns a substring as produced by python's slice notation.
examples:
    string(a,b,c) is strng[a,b,c]
    string(nil,nil,-1) is string[::-1]
]=]
function string.__mt.__call(self, from, to, step)
    step = step or 1
    from = from or (step > 0 and 1) or #self
    to   = to   or (step > 0 and #self +1 ) or 0
    if from < 0 then from = #self + from + 1 end
    if to   < 0 then to =   #self + to   + 1 end
  
    local res = {}
    for i in I.range(from, to, step) do
        res[#res+1] = self:sub(i,i)
    end
    return table.concat(res)   
end
help[string.__mt.__call]=h


h = [[
s * n as an alias for string.rep(s,n)
]]
function string.__mt.__mul(self, n)
    return self:rep(n)
end
help[string.__mt.__mul]=h



h = [[
s % n
chops the string into lines of length n.

'a\n' % 2  = 'a '
'ab\n' % 2 = 'ab\n  '

]]
function string.__mt.__mod(self, chunk_size)
    local res = ''
    local i, j, n = 1, 0, #self
    local corr = true
    local next_stop = self:find('\n') and self:find('\n') - 1 or n + 1
    
    while i <= n do
        corr = i >= next_stop
        j = corr and next_stop or i + chunk_size - 1
        res = res .. self:sub(i,j) .. (' '):rep(chunk_size-(j-i+1)) .. '\n' 
        i = corr and j + 2 or j + 1
        next_stop = corr and (self:find('\n',i) and self:find('\n',i) - 1 or n+1)  or next_stop
    end
   
    if  j>n then return res:sub(1,-2) .. (' '):rep(j-n) end
    if  self:sub(-1,-1) ~= '\n' then return res:sub(1,-2)  end
    return res:sub(1,-2) 
end
help[string.__mt.__mod]=hs

h = [[
-s = string in reverse order
]]
function string.__mt.__unm(self)
   return self(nil,nil,-1)
end
help[string.__mt.__unm]=hs


h = [[
__tosting(self) -> string

--returns quoted string
--]]
--function string.__mt.__tostring(self)
--   return string.format('%q',self)
--end
--help[string.__mt.__tostring]=h


h = [[
capitalize(s:string) -> string
]]
function string.capitalize(s)
    return (s:gsub("^%l", string.upper))
end
help[string.capitalize] = h

h = [[
uncap(s:string) -> string

replace first character with lowercase
]]
function string.capitalize(s)
    return (s:gsub("^%u", string.lower))
end
help[string.capitalize] = h


h = [[
title(s:string) -> string	

Converts the first character of each word to upper case
]]
function string.title(s)
    return (s:gsub('%w+', string.capitalize))
end
help[string.title] = h

h = [[
string:line(s:string) -> iterator
usage: for i,line in s:lines do
]]
function string:lines()
    local iter_ = string.gmatch(self .. '\n','(.-)\n')
    local 
        function iter(s,i)
            local line = iter_()
            return line and i+1, line
        end 
    return iter, nil, 0
end
help[string.lines] = h

h = [[
string:wrap(prefix_:string|function(i:number,s:string) -> string, suffix_:string|function(i:number,s:string) -> string)

replaces the ith line by 
prefix_.. line --suffix_ or
prefix_(i,line) .. line --suffix_(i,line)
]]
function string:wrap(prefix_, suffix_)
    local prefix = type(prefix_) == 'string' and function() return prefix_ end or prefix_
    local suffix = type(suffix_) == 'string' and function() return suffix_ end or suffix_   

    local res = ''

    for i, line in self:lines() do
        res = res .. prefix(i,line) .. line .. suffix(i,line) .. '\n'
    end
    return res:sub(1,-2)
end
help[string.wrap]=h

h=[[
split(s:string sep:pattern) -> List
misses last, unless string ends with separator
]]
function string.split (s, sep)
    sep = sep or ',%s*'
    local pat = string.format('(.-)(%s)', sep)
    local res = {}
    
    for str in s:gmatch(pat) do
        res[#res+1] = str
    end
    
    return res
end
help[string.split]=h


h = [[
matcher(pattern: string|function(s) -> boolean|table|boolean) -> (function(s:string) -> boolean) 
returns a function match(s:string) -> boolean
that returns true, if s matches the pattern:
  s:match(pattern), if pattern is a string
  pattern(s) if pattern is a function
  pattern[s] if pattern is a table
  pattern, if pattern is a boolean
]]

function string.matcher(p)

    local match
    
    if type(p) == 'string' then 
        match = function(s) return type(s) == 'string' and s:match(p) end
        
    elseif  type(p) == 'table' then 
        match = function(k) return p[k] end
        
    elseif  type(p) == 'function' then 
        match = p
        
    else 
        match = function(x) return p end
    end
    
    return match 

end
help[string.matcher] = h

h = [[string iterator: for i, ch in s:iter() iterates over index and charater at index]]
function string:iter()
    local iter = function(self,i)
        return i < #self and i+1 or nil, self:sub(i+1, i+1)
    end
    return iter, self, 0
end
help[string.iter]=h



function string:_replace(pos, char)
    return self:sub(1, pos-1) .. char .. self:sub(pos+1,#self)
end


h = [[
string.replace(pos:list, ch:character, except:nil|function(ch) -> any) 
replace characters ch at positions in list by ch unless except(ch) ~= nil 
]]
function string:replace(pos, ch, except)
    for _,i in ipairs(pos) do
        local char = self:sub(i,i)
        if not except or  except(char) then
            self = self:replace1(i, ch)
        end
    end
    return self        
end
help[string.replace]=h

--[[ an alternative implementation of %
h = [[convert lines of text into colblocks]]
function string.lines2ts(s, width)
    last = s:sub(#s,#s)
    s = s .. (last ~= '\n' and '\n' or '')
    local res = {}
    for line in string.gmatch(s,'(.-)\n') do
        local chunks = string.split(line, width)
        for i=1, #chunks do
            res[i] = (res[i] or '') .. chunks[i] .. '\n'
        end
    end
    return table.concat(res, '\n')
end
help[string.split]=h
--]]

return string
