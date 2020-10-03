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

local function Mash(data)
    data = tostring(data)
    local n = 0xefc8249d

    for i = 1, #data do
        n = n + data:byte(i)
        local h = 0.02519603282416938 * n
        n = math.floor(h)
        h = h - n
        h = h * n
        n = math.floor(h)
        h = h - n
        n = n + h * 0x100000000 -- 2^32
    end
    return math.floor(n) * 2.3283064365386963e-10 -- 2^-32
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
        c = math.floor(t)
        s2 = t - c
        return s2
    end

    for i = 1, 5 do
        random()
    end

    return random
end

local function fract53(random)
    return random() + math.floor(random() * 0x200000) * 1.1102230246251565e-16 -- 2^-53
end

--[[ End https://github.com/nquinlan/better-random-numbers-for-javascript-mirror ]]

local RandomStreamProto = {}
local RandomStreamMetatable = { __index = RandomStreamProto }

function CreateRandomStream(...)
    local randomStream = setmetatable({}, RandomStreamMetatable)
    randomStream:Initialize(...)
    return randomStream
end

function RandomStreamProto:Initialize(...)
    if select("#", ...) == 0 then
        self.randomState = Alea(tostring(self))
    else
        self.randomState = Alea(...)
    end
end

function RandomStreamProto:GetNextNumber()
    return self.randomState()
end

function RandomStreamProto:GetNextColor()
    -- TODO: Should use HSV
    return CreateColor(self:GetNextNumber(), self:GetNextNumber(), self:GetNextNumber())
end

function RandomStreamProto:GetNextByte()
    return self:GetIntInRange(0, 255)
end

function RandomStreamProto:GetIntInRange(min, max)
    local randFloat = self:GetNextNumber()
    -- biased, but good enough
    return math.floor(randFloat * (max - min + 1)) + min
end

function RandomStreamProto:GetNextPrintableChar()
    local printableCharacters = String.GetPrintableCharacters()
    local index = self:GetIntInRange(1, #printableCharacters)
    return printableCharacters[index]
end