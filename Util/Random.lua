local addonName, envTable = ...
setfenv(1, envTable)

-- Modified from https://github.com/nquinlan/better-random-numbers-for-javascript-mirror
--[[

Copyright (C) 2010 by Johannes Baagøe <baagoe@baagoe.org>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.]]

local floor = math.floor

local function Mash(data)
    data = tostring(data)
    local n = 0xefc8249d

    for i = 1, #data do
        n = n + data:byte(i)
        local h = 0.02519603282416938 * n
        n = floor(h)
        h = h - n
        h = h * n
        n = floor(h)
        h = h - n
        n = n + h * 0x100000000 -- 2^32
    end
    return floor(n) * 2.3283064365386963e-10 -- 2^-32
end

local function Alea(...)
    local s0 = Mash(' ')
    local s1 = Mash(' ')
    local s2 = Mash(' ')
    local c = 1

    for i = 1, select("#", ...) do
        local arg = select(i, ...)
        s0 = s0 - Mash(arg)
        if s0 < 0 then
            s0 = s0 + 1
        end
        s1 = s1 - Mash(arg)
        if s1 < 0 then
            s1 = s1 + 1
        end
        s2 = s2 - Mash(arg)
        if s2 < 0 then
            s2 = s2 + 1
        end
    end

    local function random()
        local t = 2091639 * s0 + c * 2.3283064365386963e-10 -- 2^-32
        s0 = s1
        s1 = s2
        c = floor(t)
        s2 = t - c
        return s2
    end

    return random
end

local function uint32(random)
    return random() * 0x100000000 -- 2^32
end

local function fract53(random)
    return random() + floor(random() * 0x200000) * 1.1102230246251565e-16 -- 2^-53
end

--[[ End https://github.com/nquinlan/better-random-numbers-for-javascript-mirror ]]

local RandomStreamProto = {}
local RandomStreamMetatable = { __index = RandomStreamProto }

function CreateRandomStream(seed)
    local randomStream = setmetatable({}, RandomStreamMetatable)
    randomStream:Initialize(seed)
    return randomStream
end

function RandomStreamProto:Initialize(seed)
    self.randomState = Alea(seed)
end

function RandomStreamProto:GetNextNumber()
    return self.randomState()
end

function RandomStreamProto:GetNextColor()
    -- TODO: Should use HSV
    return CreateColor(self:GetNextNumber(), self:GetNextNumber(), self:GetNextNumber())
end

function RandomStreamProto:GetNextFract53()
    return fract53(self.randomState)
end

function RandomStreamProto:GetNextUint32()
    return uint32(self.randomState)
end