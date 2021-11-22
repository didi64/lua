local h
h = [=[
Class.new(c:class-definition, parents:list) -> Class

Examples:
create a class:
Foo     = {__name = 'Foo'}
Foo.cls = {} -- for classmethods

-- add attributes
Foo.attr1 = 'foo'

--add method
function Foo:method1() <code> end

--add staticmethod
function Foo.method1() <code> end

--add classmethod
function Foo.cls:method2 <code> end, call as self:method2(), binding is taken care of, what with private class methods?

--add metamethod: 
function Foo.__add(self, other) <code> end

--add class metamethod: (Foo + Foo triggers Foo.cls.__add(Foo, Foo)
function Foo.cls.__add(self, other) <code> end

--add __init
function  Foo.__init(self,...) <code> end

-- make the class
Foo = Class.new(Foo)


-- inherit form Foo
Bar = {__name = 'Bar'}
function Bar.__init(self)
    self:super():__init() -- call __init of parent
    
Bar = Class.new(Bar, {Foo}) -- Foo is parent of Bar

the instance metamethods __index and __newindex:
normal behaviour is only overriden for keys of the sets c.__indextypes and c.__newindextypes

DO NOT override the class metamethods __index, and __newindex (at least for now).
]=]


require 'help'
require 'table_print'
local Meta = require 'meta'

Class = setmetatable({}, {__call = function(...) return Class.new(...) end}) 
help[Class] = h

Class.public_pattern  = '^[%a][_%w]*'
Class.private_pattern = '^_[%a][_%w]*'
Class.meta_pattern    = '^__[%a][_%w]*'

-- allow to configure 
Class.indextypes    = {string = true}
Class.newindextypes = {string = true}
--instance metamethod mapping  
Class.instance_mmtt = {__index = '___index', __newindex = '___newindex'} 
 
Class.cls = {}      -- methods that are attached to each class
Class.instance = {} -- methods that are attached to each class-instance
 
function Class.new(cls, parents, verbose)
    if  not cls.__name or type(cls.__name) ~= 'string' then
        error(string.format('key .__name not valid! String expected got %s', type(cls.__name)))
    end    
    parents = parents or {}
   
    local c = {__type = 'prototype', __parents  = parents, __help = help.class_help, 
               __info = 'public table of class ' .. cls.__name, __debug = verbose,
               __indextypes =  Class.indextypes, __newindextypes = Class.newindextypes}
    
    c.__new    = cls.cls and cls.cls.__new  or Class.cls.new 
    c.__init   = cls.__init                                  
      
    c.__public = {
        __cls  = c,
        __type = 'instance',
        __name = cls.__name,
        __info     = 'table with public methods and attributes of class ' .. cls.__name,
        isA   = {[cls.__name] = c},
        isInstance = function(o, cls) return o.__type == 'instance'  and o.isA[cls.__name] end,
        isSubclass = function(o, cls) return o.__type == 'prototype' and o.isA[cls.__name] end,
        super = Class.super, 
        proxy = Class.proxy, 
    }   
 
    c.__mt  = {
        __tostring = Class.cls.tostring,
        __index    = c.__public, -- if key is not found in c
        __newindex = c.__public, -- if key is not found in c
        __call     = cls.cls and cls.cls.__call or c.__new, 
        __info     = 'metatable of the class ' .. cls.__name,
    }
 
    c.__instance_mt  = {
        __tostring = Class.instance.tostring,
        -- __index    = c.__public, -- if key is not found in c
        __index    = function(_, k) 
                         if c.__indextypes[type(k)] then 
                             return c.__public[k] 
                         elseif c.__instance_mt.___index then
                             return c.__instance_mt.___index(_, k) 
                         end    
                     end,     
        __newindex = function(t, k, v) 
                         if  c.__newindextypes[type(k)] then 
                             rawset(t, k, v) 
                         elseif c.__instance_mt.___newindex then 
                             c.__instance_mt.___newindex(t,k,v) 
                         end
                      end,   
        __info     = 'metatable of class ' .. cls.__name .. '\'s instances',
    }
   
    setmetatable(c, c.__mt)
    setmetatable(c.__public, {__index = Class.index })
   
    Class.init_isA(c)           
    Class.add_metamethods(cls, c)          
    Class.add_parents_metamethods(c)          
    Class.add_methods(cls, c)          
    help[c] = help[cls]
    return c
end
--  dofile('class_example.lua')
 -- default constructor
function Class.cls.new(cls, ...)
    local o =  {}  -- class-instance
    setmetatable(o, cls.__instance_mt)
    if  cls.__init then cls.__init(o,...) end
    return o
end

function Class.cls.tostring(self)
   return 'Class ' .. self.__name .. ', ' .. table.rawtostring(self) 
end   

function Class.instance.tostring(self)
   return 'Instance of Class ' .. self.__name .. ', ' .. table.rawtostring(self) 
end   

-- if key is not found in c.__public
function Class.index(c_publ, k)
    if c_publ.__cls.__debug then print(string.format('key \"%s\" not found in %s', k, c_publ.__info)) end
    if  type(k) == 'string' and k:match(Class.private_pattern) then return nil end
    --for _,p in ipairs(rawget(c_publ.__cls,'__parents') or {}) do
    for _,p in ipairs(c_publ.__cls.__parents) do
        if c_publ.__cls.__debug then print(string.format('checking for key \"%s\"  in %s', k, p.__public.__info)) end
        local val = p.__public[k]
        if  val then return val end
    end        
end

function Class.init_isA(c)
    --for _,p in ipairs(rawget(c, '__parents') or {}) do
    for _,p in ipairs(c.__parents) do
       for k,v in pairs(p.isA) do
           c.__public.isA[k] = v
       end      
    end
end 

function Class.add_metamethods(self,c)
    for k,v in pairs(self.cls or {}) do
        if k == Meta.method_names[k] then
            c.__mt[k] = v
        end
    end
    
    for k,v in pairs(self or {}) do
        if Meta.method_names[k] then
            k = Class.instance_mmtt[k] or k
            c.__instance_mt[k] = v
        end
    end   
end

-- c.__mt and c.__instance_mt
function Class.add_parents_metamethods(c)
    --for _,p in ipairs(rawget(c,'__parents') or {}) do
    for _,p in ipairs(c.__parents) do
       for k,v in pairs(p.__mt or {}) do
           if not c.__mt[k] then 
               c.__mt[k] = v
           end
       end        
      
       for k,v in pairs(p.__instance_mt or {}) do
           if not c.__instance_mt[k] then 
               c.__instance_mt[k] = v
           end
       end       
          
    end  
end
  
function Class.add_methods(self,c)
    for k,v in pairs(self or {}) do
        if type(k) == 'string' and k:match(Class.public_pattern) then
            c.__public[k] = v
        end
    end
    
    for k,f in pairs(self.cls or {}) do
        if  type(f) ~= 'function' then error(string.format('function expected, got %s', type(f))) end
        if  type(k) == 'string' and k:match(Class.private_pattern) then
            self.cls[k] =  function(self,...) return f(c,...) end  
        else   
            c.__public[k] = function(self,...) return f(c,...) end 
            help[c.__public[k]] = help[f] and '@classmethod\n' .. help[f] 
        end
    end
end



--[[
    the methods super and proxy are always accessed directly (no rebinding)
    Problem that we solve here:
      C inherits from B which inherits from A
      in C: C.__init(self) calls self:super():__init 
      in B: B.__init(self) calls self:super():__init 
      
      in C, self is a c (an instance of C)
      the call self:super():__init in C unwinds to B.__init(c), which c rebound by proxy, thus c.__org is linked to proxy 
      the call self:super():__init in B unwinds as follows:
          self:super() is c:super().
          as c is linked to a proxy, c:super() is a proxy (c,A), therefore
          self:super():__init in B unwinds to A.__init(c)
      
--]]
h = [[
Class.super(self:obj|cls, cls:cls)
returns proxy to call methods of first parent of cls as self
]]
function Class.super(self, cls) 
    self, cls = Class._get_proxy_args(self, cls)
    --cls =  rawget(cls, '__parents') and  cls.__parents[1]
    cls =  cls.__parents and  cls.__parents[1]
    Class._check_proxy_args(self, cls)
    return Class._make_proxy(self, cls) 
end   


h = [[
Class.proxy(self:obj|cls, cls:cls)
returns proxy to call methods of cls as self
]]
function Class.proxy(self, cls) 
    self, cls = Class._get_proxy_args(self, cls)
    Class._check_proxy_args(self, cls)
    return Class._make_proxy(self, cls) 
end   

--[[
auxiliary stuff ---------------------------------------------------------------------------------------------
--]]

function Class._get_proxy_args(self, cls)
    -- self linked to proxy
    if rawget(self, '__org') then 
        cls = cls or self.__org.___cls
    -- self is proxy    
    elseif self.__type == 'proxy' then 
        self = self.___self 
        cls = cls or self.___cls
    else
        cls = cls or self.__cls  
    end
    return self, cls
end       
   
--[[   
if self is an instance it must be an instance of cls
if self is a class it must be a subclass of cls      
--]]
function Class._check_proxy_args(self, cls)
    if self.__type == 'instance' or self.__type == 'prototype' then 
        return self.isA[cls.__name]
    end
end          
       
function Class._make_proxy(self, cls) 
    local proxy =  {__type = 'proxy',___self = self, ___cls = cls}
    local mt    =  {__index = Class._proxy_index(self, cls),
                    __tostring = function(self) return string.format('proxy=(%s, %s)', self.___self, self.___cls) end,
                   }
                   
    return setmetatable(proxy, mt) 
end

function Class._proxy_index(self, cls)
    local 
        function __index(proxy, k)
            if cls.__debug then print(string.format('accessing key \"%s\" via %s', k, proxy)) end
            if k == 'super' or k == 'proxy' then
                return cls[k]
            end
            
            local f = cls[k]
            if type(f) == 'function' then
               
                return 
                    function(self_, ...)   
                        self.__org = self_
                        local res = f(self, ...) 
                        self.__org = nil
                        return res
                    end   
            end    
            return f               
        end

    return __index     
end



return Class
