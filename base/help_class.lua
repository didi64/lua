require 'help'
local h=[[
shows help for prototypes
]]

-- settings
local reserved   = {super = true, proxy = true}
local is_public  = function(k) return k:match('^[%a][_%w]*') and not reserved[k] end  
local is_private = function(k) return k:match('^_[%a][_%w]*') end  
local is_method  = function(f) return type(f) == 'function'   end  
local get_name   = function(c) return c.__type == 'prototype' and c.__name or c.__name:gsub('^%u', string.lower) end  

-- help texts
help.class = {menu = 
  {
    {'MRO WITH SHORT PROTOTYPE DESC:\n', function(c) 
                                           local tree = help.mro_tree(c)
                                           local renderer = 
                                               function(c) 
                                                   return tostring(c) .. '\n' .. (help[c] or '') 
                                               end
                                           local stemlength = 5    
                                           return help.tree2s(tree, stemlength, renderer)
                                         end
    
    },
    {'IMPLEMENTED METAMETHODS:\n', function(c)
                                       return help.class_metamethod_help(c)
                                   end
    
    },
    {'PROTOTYPE-METHODS:\n', function(c)
                                 return help.class_method_help(c)
                             end   
    },
  }    
} 
help[help.class] = h
------------------------------------------------------------------------------------------ 
-- called by help(help.class)
function help.class.__help()
    print(help[help.class])
end

--called by help(c) if c is a class
function help.class_help(c)
   print(('='):rep(80))
   for _,t in ipairs(help.class.menu) do 
       print(t[1] .. '\n' .. t[2](c) ..'\n' .. ('='):rep(80))
   end  
end
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
require 'Table_Basics'
require 'String'
local Meta  = require 'meta'

h = [[
mro_tree(c:class) -> tree=(table, t=>t[1], t=> ipairs(t[2] or {}))

the nodes of the mro tree are prototypes

A tree is a triple (o, root, ch_iter), where
- root, ch_iter are functions with obj in their domain
- ch_iter(obj) = (o_1,...,o_n) so that (o_i,root,ch_iter) is a tree.
- each path is loop-free
]]
function help.mro_tree(c)
    return {help._mro_tree(c),
            function(t)      return t[1] end,               -- root lambda({1}, rawget, {1}), lambda not good enough yet!
            function(t)      return ipairs(t[2] or {}) end, -- ch_iter lambda({1}, ipairs, {1})
            function(t,i,ch) return i == #t[2] end          -- is_last 
           }  
end

function help._mro_tree(c)
    local t = {c}
    local chn = {} -- children
    for i,cls in ipairs(c.__parents) do
        chn[#chn+1] = help._mro_tree(cls)
    end
    t[2] = next(chn) and chn
    return t
end

h = [[
tree2s(t:tree, stemlength:number, renderer: function(node) -> lines)
]]
function help.tree2s(tree, stemlength, renderer)
    renderer = renderer or tostring
    local t, root, ch_iter, is_last = table.unpack(tree)
    
    local padding = ' '
    local stemlength = stemlength or 2
    local stem_ = string.rep('─', stemlength) .. padding
    local stem1 = '├' .. stem_
    local stem2 = '└' .. stem_
    local up    = '│' .. string.rep(' ', stemlength) .. padding
    local blanc = ' ' .. string.rep(' ', stemlength) .. padding
    
    function __tree2s(t, lev, last, ups)
        local stem = lev == 0 and '' or last and stem2 or stem1
        local pos = table.list2set(table.iapply(ups:split(), function(x) return tonumber(x) end))
        local indent = ''
        
        for i = 1, lev - 1 do
            indent = pos[i-1] and indent .. up or indent .. blanc
        end  

        local s = ''
        if  lev == 0 then 
            s = renderer(root(t)) .. '\n'
        else
           for i,line in renderer(root(t)):lines() do
                s = s .. indent .. (i == 1 and stem or (last and blanc) or up) .. line .. '\n'
            end
        end
        
        for i,ch in ch_iter(t) do
            local last = is_last(t,i,ch)
            s = s .. __tree2s(ch,  lev+1, last, last and ups or ups ..  lev ..',') 
        end    
   
        return s
    end
    return __tree2s(t, 0, false, '')
end

--[[
class_method_dict(c:prototype) -> dict

returns a dict
{k = {cls.__public[k], cls, {ancester, ... }, {ancesters as set}}

k:   name of public method in c or one of its ancesters
cls: c or one of its ancesters, where key k is found first
ancester: ancesters of c, where key k is found 
--]]
function help.class_method_dict(c, res)
    res = res or {}
    for k,v in next, c.__public, nil do
        if is_method(v) and is_public(k) then
            if not res[k] then
                res[k] = {v, c, {}, {}}
            elseif not res[k][4][c] then
                res[k][4][c] = true
                table.insert(res[k][3], c)
            end   
        end
    end
        
    for _,cls in  ipairs(c.__parents) do
        help.class_method_dict(cls, res)
    end
    return res        
end

h = [[
class_methods(c:prototype) -> list: sorted by methodname

for each method, where is a list entry of the form
{classname:methodname, method, parents that have a method with the same name}
]]
function help.class_methods(c)
    local d = help.class_method_dict(c)
    local t = {}
    for k,v in pairs(d) do
        t[#t+1] = {get_name(v[2]) .. ':' .. k, v[1], table.concat(table.iapply(v[3], get_name),':')}
    end 
    table.sort(t, function(a,b) return a[1] < b[1] end)   
    return t
end
help[help.class_methods] = h


h = [[
class_method_help(c:prototype) -> string

returns list of public methods and DocStrings
]]
function help.class_method_help(c)
    local t = help.class_methods(c)
    htext = {'Methods: '}
    for _,v in ipairs(t) do 
        table.insert(htext, v[1] .. ', ' .. v[3])
        table.insert(htext, help[v[2]] or '\n')
    end
    return table.concat(htext,'\n')
end
help[help.class_method_help] = h


h = [[
class_metamethod_help(c: prototye)

returns list of implemented metamethods,
if help is available, it is printed as well.
]]
function help.class_metamethod_help(c)
    local t = Meta.get_ops(c.__instance_mt)
    heading= 'Implemented metamethods: '
    for k,v in pairs(t) do
        heading = heading .. k .. ', '
    end
    heading = heading:sub(1,-3)    
    
    -- use table.rev(Class.instance_mmtt), what do do with tostring? 
    local htext = ''
    mm = Meta.get_metamethods(c.__instance_mt) 
    for k,v in pairs(mm) do
        local text = help[v[1]] or ''
        htext = htext .. text
    end    
    return heading .. '\n'.. htext
end
help[help.class_metamethod_help] = h

