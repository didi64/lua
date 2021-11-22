local Class = require 'class'
require 'help'
local h


local verbose = verbose or false

-- class A
h = [[
Grandpa 
]]
local A = {__name = 'A'}  -- to keep access to A , let A={__name = 'A', __src = A} can access A via A.__src 
help[A] = h

-- static method
function A.identify(cn, mn, caller)
    print(string.format('%s defined in class %s, called by %s', mn, cn, caller))
end
function A.__init(self,x) 
    self.value = 1
    self.identify('A', '__init__', self)
end
h = [[
test() 

prints 'A:test' and object that called this method
]]
function A.test(self) 
    self.identify('A:test', self)
end
help[A.test]=h
-- turn A into a class
A = Class.new(A, nil, verbose)


--class B, allow to call instances
h = [[
Parent 2
]]
local B = {__name = 'B'}
help[B] = h
function B.__init(self,x) 
    self.value = 2
    self.identify('B', '__init', self)
end
h = [[
test() 

prints 'B:test' and object that called this method
]]
function B.test(self) 
    self.identify('B', 'test', self)
end
help[B.test]=h

function B.__call(self) print(string.format('calling %s', self)) end
B = Class.new(B, {A}, verbose)

-- class C
h = [[
Parent 1
]]
local C = {__name = 'C'}
help[C] = h
function C.__init(self,x) 
    -- C.__parents[1].__init(self)
    self:super():__init(x) 
    self.identify('C', '__init', self)
end
function C.test(self) 
    self.identify('C', 'test', self)
end
C = Class.new(C, {A}, verbose)
 
--class D
h = [[
tests some features of the moduel 'Class'
]]
local D = {__name = 'D'}
help[D] = h
D.cls = {}
function D.__init(self,x) 
    -- D.__parents[1].__init(self)
    self:super():__init(x) 
    self.identify('D', '__init', self)
end

h = [[ 
test()

prints 'D:test' and object that called this method
]]
function D.test(self)
    self.identify('D', 'test', self)
end
help[D.test]=h

--override __new
function D.cls.__new(cls) 
    cls.counter = cls.counter and cls.counter + 1 or 1 
    local o =  {info = 'this info was added with __new'}  -- instance
    setmetatable(o, cls.__instance_mt)
    if  cls.__init then cls.__init(o) end
    return o
end

-- newindex, what to do with keys that are not strings (when indexing and instance)
function D.__newindex(t, k, v) print('illegal key!') end 

--classmethod
h = [[
foo(...)

prints prototype of caller and ... 
]]
function D.cls.foo(cls, ...) print(string.format('Classmethod foo: cls=%s, args=', cls), ...) end
help[D.cls.foo]=h

D = Class.new(D, {C, B}, verbose)

--------------------------------------------------------------------------------
-- Testing the classes A,B,C,D
--------------------------------------------------------------------------------

local lw = 80
local function hline() print(('='):rep(lw)) end

-- creating instances
print('creating instances:\n')
a, b, c, d = A(), B(), C(), D()
print(a,b,c,d)
hline()

-- proxyaccess
print('proxy access:\n')
cls  = {D,C,B,A}
objs = {d,c,b,a}
for i,o in ipairs(objs) do
    for j = i,4 do
        d.proxy(o, cls[j]):test()
        print()
    end    
end
hline()

-- calling instances
print('calling instances:\n')
for i,o in ipairs(objs) do 
   print(string.format('trying to call %s', o))
   ok, msg = pcall(o) 
   if not ok then print('Error: ' .. msg) end
end
hline()

-- testing class method
print('testing class method:\n')
d:foo(1,2)
D:foo(1,2,3)
hline()

-- accessing keys
print('accessing keys:\n')
for i,o in ipairs(objs) do 
    print(string.format('%s.value=%s', o.__name:lower(), o.value))
end    
print('D.value', D.value)
print('d.x',d.x)
hline()

-- D.__new
print('D.__new:', D.info)
print(d:isInstance(B))
print(C:isSubclass(A))

-- newindex
d[{}]= 0
d[1] = 0

for _,c in ipairs(cls) do _G[c.__name] = c end
for _,o in ipairs(objs) do _G[o.__name:lower()] = o end


