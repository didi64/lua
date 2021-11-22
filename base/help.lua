-- DocString of module 'help'
local h = [[
help(obj) 

Show help for object <obj>:
    if obj.__help exists, obj.__help() is run,
    else help[obj] is displayed.
]]

if help and not help.__loading then error('global help exists!') end
if help and  help.__loading then return end
help = {__loading = true}  -- help is global!
require 'help_class'
help[help] = h 


-- help for module help
function help.__help() 
    print(help[help])
end

function help.help(self, obj)
    obj = obj or self
    if  type(obj) == 'table' and obj.__help then 
        obj:__help()
    elseif
        help[obj] then 
        print(help[obj])
    else
        print('No help found!')    
    end    
end           
help[help.help] = help[help]

h = [[
objects(t:table, p:pattern, exclude: set) -> list, sorted

the list has an entry {k,v}
for each k,v in t with k:match(p) and  not exclude[k]
]]
function help.objects(t, pattern, exclude)
    exclude = exclude or {}
    local res = {}
    for k,v in pairs(t) do
        if  k:match(pattern) and not exclude[k] then
            table.insert(res, {k, v})
        end    
    end
    table.sort(res, function(a,b) return type(a[2]) ~= 'function' and  type(b[2]) == 'function' or a[1] < b[1] end )
    return res
end
help[help.objects] = h 

return setmetatable(help, {__mode = "k", __call = help.help}) -- if method gets deleted, help for method can be garbage collected


