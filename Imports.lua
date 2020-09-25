local addonName, envTable = ...

local function DeepCopyTable(t)
    local n = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            n[k] = DeepCopyTable(v)
        else
            n[k] = v
        end
    end
    return n
end

local function Import(name)
    local global = _G[name]
    envTable[name] = type(global) == "table" and DeepCopyTable(global) or global
end

setfenv(1, envTable)

Import("table")
Import("string")
Import("math")

Import("ipairs")
Import("pairs")
Import("assert")
Import("setmetatable")
Import("type")
Import("print")
Import("select")
Import("tostring")
Import("unpack")

Import("CreateFrame")
Import("GetTime")
Import("UnitName")
Import("IsInGroup")
Import("GetCursorPosition")

Import("C_ChatInfo")
Import("C_Timer")

Import("CreateFromMixins")
Import("PixelUtil")
Import("ObjectPoolMixin")
Import("CreateTexturePool")
Import("CreateFontStringPool")


Game_Debug = {
	{
		["y"] = -50,
		["x"] = -50,
	}, -- [1]
	{
		["y"] = -5.28594970703125,
		["x"] = -50,
	}, -- [2]
	{
		["y"] = 70.46099853515625,
		["x"] = 24.2530517578125,
	}, -- [3]
	{
		["y"] = 70.46099853515625,
		["x"] = 174.2530517578125,
	}, -- [4]
	{
		["y"] = -79.53900146484375,
		["x"] = 174.2530517578125,
	}, -- [5]
	{
		["y"] = -79.53900146484375,
		["x"] = 24.2530517578125,
	}, -- [6]
	{
		["y"] = -50,
		["x"] = -5.285949707031243,
	}, -- [7]
	{
		["y"] = 50,
		["x"] = -50,
	}, -- [8]
	{
		["y"] = 50,
		["x"] = 3.792053222656257,
	}, -- [9]
	{
		["y"] = -3.79205322265625,
		["x"] = -50,
	}, -- [10]
	["ConcaveDecompose"] = {
		{
			["IsLeftOrOnOf"] = nil --[[ skipped inline function ]],
			["LengthSquared"] = nil --[[ skipped inline function ]],
			["IsLeftOf"] = nil --[[ skipped inline function ]],
			["Dot"] = nil --[[ skipped inline function ]],
			["Length"] = nil --[[ skipped inline function ]],
			["IsRightOrOnOf"] = nil --[[ skipped inline function ]],
			["GetXY"] = nil --[[ skipped inline function ]],
			["IsRightOf"] = nil --[[ skipped inline function ]],
			["Distance"] = nil --[[ skipped inline function ]],
			["ToPerpendicular"] = nil --[[ skipped inline function ]],
			["y"] = -50,
			["x"] = -50,
			["GetX"] = nil --[[ skipped inline function ]],
			["Cross"] = nil --[[ skipped inline function ]],
			["GetY"] = nil --[[ skipped inline function ]],
			["SetXY"] = nil --[[ skipped inline function ]],
			["DistanceSquared"] = nil --[[ skipped inline function ]],
			["GetNormal"] = nil --[[ skipped inline function ]],
		}, -- [1]
		{
			["IsLeftOrOnOf"] = nil --[[ skipped inline function ]],
			["LengthSquared"] = nil --[[ skipped inline function ]],
			["IsLeftOf"] = nil --[[ skipped inline function ]],
			["Dot"] = nil --[[ skipped inline function ]],
			["Length"] = nil --[[ skipped inline function ]],
			["IsRightOrOnOf"] = nil --[[ skipped inline function ]],
			["GetXY"] = nil --[[ skipped inline function ]],
			["IsRightOf"] = nil --[[ skipped inline function ]],
			["Distance"] = nil --[[ skipped inline function ]],
			["ToPerpendicular"] = nil --[[ skipped inline function ]],
			["y"] = 0,
			["x"] = -100,
			["GetX"] = nil --[[ skipped inline function ]],
			["Cross"] = nil --[[ skipped inline function ]],
			["GetY"] = nil --[[ skipped inline function ]],
			["SetXY"] = nil --[[ skipped inline function ]],
			["DistanceSquared"] = nil --[[ skipped inline function ]],
			["GetNormal"] = nil --[[ skipped inline function ]],
		}, -- [2]
		{
			["IsLeftOrOnOf"] = nil --[[ skipped inline function ]],
			["LengthSquared"] = nil --[[ skipped inline function ]],
			["IsLeftOf"] = nil --[[ skipped inline function ]],
			["Dot"] = nil --[[ skipped inline function ]],
			["Length"] = nil --[[ skipped inline function ]],
			["IsRightOrOnOf"] = nil --[[ skipped inline function ]],
			["GetXY"] = nil --[[ skipped inline function ]],
			["IsRightOf"] = nil --[[ skipped inline function ]],
			["Distance"] = nil --[[ skipped inline function ]],
			["ToPerpendicular"] = nil --[[ skipped inline function ]],
			["y"] = 50,
			["x"] = -50,
			["GetX"] = nil --[[ skipped inline function ]],
			["Cross"] = nil --[[ skipped inline function ]],
			["GetY"] = nil --[[ skipped inline function ]],
			["SetXY"] = nil --[[ skipped inline function ]],
			["DistanceSquared"] = nil --[[ skipped inline function ]],
			["GetNormal"] = nil --[[ skipped inline function ]],
		}, -- [3]
		{
			["IsLeftOrOnOf"] = nil --[[ skipped inline function ]],
			["LengthSquared"] = nil --[[ skipped inline function ]],
			["IsLeftOf"] = nil --[[ skipped inline function ]],
			["Dot"] = nil --[[ skipped inline function ]],
			["Length"] = nil --[[ skipped inline function ]],
			["IsRightOrOnOf"] = nil --[[ skipped inline function ]],
			["GetXY"] = nil --[[ skipped inline function ]],
			["IsRightOf"] = nil --[[ skipped inline function ]],
			["Distance"] = nil --[[ skipped inline function ]],
			["ToPerpendicular"] = nil --[[ skipped inline function ]],
			["y"] = 75,
			["x"] = 0,
			["GetX"] = nil --[[ skipped inline function ]],
			["Cross"] = nil --[[ skipped inline function ]],
			["GetY"] = nil --[[ skipped inline function ]],
			["SetXY"] = nil --[[ skipped inline function ]],
			["DistanceSquared"] = nil --[[ skipped inline function ]],
			["GetNormal"] = nil --[[ skipped inline function ]],
		}, -- [4]
		{
			["IsLeftOrOnOf"] = nil --[[ skipped inline function ]],
			["LengthSquared"] = nil --[[ skipped inline function ]],
			["IsLeftOf"] = nil --[[ skipped inline function ]],
			["Dot"] = nil --[[ skipped inline function ]],
			["Length"] = nil --[[ skipped inline function ]],
			["IsRightOrOnOf"] = nil --[[ skipped inline function ]],
			["GetXY"] = nil --[[ skipped inline function ]],
			["IsRightOf"] = nil --[[ skipped inline function ]],
			["Distance"] = nil --[[ skipped inline function ]],
			["ToPerpendicular"] = nil --[[ skipped inline function ]],
			["y"] = 50,
			["x"] = 50,
			["GetX"] = nil --[[ skipped inline function ]],
			["Cross"] = nil --[[ skipped inline function ]],
			["GetY"] = nil --[[ skipped inline function ]],
			["SetXY"] = nil --[[ skipped inline function ]],
			["DistanceSquared"] = nil --[[ skipped inline function ]],
			["GetNormal"] = nil --[[ skipped inline function ]],
		}, -- [5]
		{
			["IsLeftOrOnOf"] = nil --[[ skipped inline function ]],
			["LengthSquared"] = nil --[[ skipped inline function ]],
			["IsLeftOf"] = nil --[[ skipped inline function ]],
			["Dot"] = nil --[[ skipped inline function ]],
			["Length"] = nil --[[ skipped inline function ]],
			["IsRightOrOnOf"] = nil --[[ skipped inline function ]],
			["GetXY"] = nil --[[ skipped inline function ]],
			["IsRightOf"] = nil --[[ skipped inline function ]],
			["Distance"] = nil --[[ skipped inline function ]],
			["ToPerpendicular"] = nil --[[ skipped inline function ]],
			["y"] = -50,
			["x"] = 50,
			["GetX"] = nil --[[ skipped inline function ]],
			["Cross"] = nil --[[ skipped inline function ]],
			["GetY"] = nil --[[ skipped inline function ]],
			["SetXY"] = nil --[[ skipped inline function ]],
			["DistanceSquared"] = nil --[[ skipped inline function ]],
			["GetNormal"] = nil --[[ skipped inline function ]],
		}, -- [6]
	},
	["UnionPolygonsA"] = {
		{
			["IsLeftOrOnOf"] = nil --[[ skipped inline function ]],
			["LengthSquared"] = nil --[[ skipped inline function ]],
			["IsLeftOf"] = nil --[[ skipped inline function ]],
			["Dot"] = nil --[[ skipped inline function ]],
			["Length"] = nil --[[ skipped inline function ]],
			["IsRightOrOnOf"] = nil --[[ skipped inline function ]],
			["GetXY"] = nil --[[ skipped inline function ]],
			["IsRightOf"] = nil --[[ skipped inline function ]],
			["Distance"] = nil --[[ skipped inline function ]],
			["ToPerpendicular"] = nil --[[ skipped inline function ]],
			["y"] = 208.3333053588867,
			["x"] = 150,
			["GetX"] = nil --[[ skipped inline function ]],
			["Cross"] = nil --[[ skipped inline function ]],
			["GetY"] = nil --[[ skipped inline function ]],
			["SetXY"] = nil --[[ skipped inline function ]],
			["DistanceSquared"] = nil --[[ skipped inline function ]],
			["GetNormal"] = nil --[[ skipped inline function ]],
		}, -- [1]
		{
			["IsLeftOrOnOf"] = nil --[[ skipped inline function ]],
			["LengthSquared"] = nil --[[ skipped inline function ]],
			["IsLeftOf"] = nil --[[ skipped inline function ]],
			["Dot"] = nil --[[ skipped inline function ]],
			["Length"] = nil --[[ skipped inline function ]],
			["IsRightOrOnOf"] = nil --[[ skipped inline function ]],
			["GetXY"] = nil --[[ skipped inline function ]],
			["IsRightOf"] = nil --[[ skipped inline function ]],
			["Distance"] = nil --[[ skipped inline function ]],
			["ToPerpendicular"] = nil --[[ skipped inline function ]],
			["y"] = 208.3333053588867,
			["x"] = 276.1904602050781,
			["GetX"] = nil --[[ skipped inline function ]],
			["Cross"] = nil --[[ skipped inline function ]],
			["GetY"] = nil --[[ skipped inline function ]],
			["SetXY"] = nil --[[ skipped inline function ]],
			["DistanceSquared"] = nil --[[ skipped inline function ]],
			["GetNormal"] = nil --[[ skipped inline function ]],
		}, -- [2]
		{
			["IsLeftOrOnOf"] = nil --[[ skipped inline function ]],
			["LengthSquared"] = nil --[[ skipped inline function ]],
			["IsLeftOf"] = nil --[[ skipped inline function ]],
			["Dot"] = nil --[[ skipped inline function ]],
			["Length"] = nil --[[ skipped inline function ]],
			["IsRightOrOnOf"] = nil --[[ skipped inline function ]],
			["GetXY"] = nil --[[ skipped inline function ]],
			["IsRightOf"] = nil --[[ skipped inline function ]],
			["Distance"] = nil --[[ skipped inline function ]],
			["ToPerpendicular"] = nil --[[ skipped inline function ]],
			["y"] = 75,
			["x"] = 200,
			["GetX"] = nil --[[ skipped inline function ]],
			["Cross"] = nil --[[ skipped inline function ]],
			["GetY"] = nil --[[ skipped inline function ]],
			["SetXY"] = nil --[[ skipped inline function ]],
			["DistanceSquared"] = nil --[[ skipped inline function ]],
			["GetNormal"] = nil --[[ skipped inline function ]],
		}, -- [3]
		{
			["IsLeftOrOnOf"] = nil --[[ skipped inline function ]],
			["LengthSquared"] = nil --[[ skipped inline function ]],
			["IsLeftOf"] = nil --[[ skipped inline function ]],
			["Dot"] = nil --[[ skipped inline function ]],
			["Length"] = nil --[[ skipped inline function ]],
			["IsRightOrOnOf"] = nil --[[ skipped inline function ]],
			["GetXY"] = nil --[[ skipped inline function ]],
			["IsRightOf"] = nil --[[ skipped inline function ]],
			["Distance"] = nil --[[ skipped inline function ]],
			["ToPerpendicular"] = nil --[[ skipped inline function ]],
			["y"] = 50,
			["x"] = 150,
			["GetX"] = nil --[[ skipped inline function ]],
			["Cross"] = nil --[[ skipped inline function ]],
			["GetY"] = nil --[[ skipped inline function ]],
			["SetXY"] = nil --[[ skipped inline function ]],
			["DistanceSquared"] = nil --[[ skipped inline function ]],
			["GetNormal"] = nil --[[ skipped inline function ]],
		}, -- [4]
	},
	["UnionPolygonsB"] = {
		{
			["IsLeftOrOnOf"] = nil --[[ skipped inline function ]],
			["LengthSquared"] = nil --[[ skipped inline function ]],
			["IsLeftOf"] = nil --[[ skipped inline function ]],
			["Dot"] = nil --[[ skipped inline function ]],
			["Length"] = nil --[[ skipped inline function ]],
			["IsRightOrOnOf"] = nil --[[ skipped inline function ]],
			["GetXY"] = nil --[[ skipped inline function ]],
			["IsRightOf"] = nil --[[ skipped inline function ]],
			["Distance"] = nil --[[ skipped inline function ]],
			["ToPerpendicular"] = nil --[[ skipped inline function ]],
			["y"] = 208.3333053588867,
			["x"] = 223.8095158168248,
			["GetX"] = nil --[[ skipped inline function ]],
			["Cross"] = nil --[[ skipped inline function ]],
			["GetY"] = nil --[[ skipped inline function ]],
			["SetXY"] = nil --[[ skipped inline function ]],
			["DistanceSquared"] = nil --[[ skipped inline function ]],
			["GetNormal"] = nil --[[ skipped inline function ]],
		}, -- [1]
		{
			["IsLeftOrOnOf"] = nil --[[ skipped inline function ]],
			["LengthSquared"] = nil --[[ skipped inline function ]],
			["IsLeftOf"] = nil --[[ skipped inline function ]],
			["Dot"] = nil --[[ skipped inline function ]],
			["Length"] = nil --[[ skipped inline function ]],
			["IsRightOrOnOf"] = nil --[[ skipped inline function ]],
			["GetXY"] = nil --[[ skipped inline function ]],
			["IsRightOf"] = nil --[[ skipped inline function ]],
			["Distance"] = nil --[[ skipped inline function ]],
			["ToPerpendicular"] = nil --[[ skipped inline function ]],
			["y"] = 208.3333053588867,
			["x"] = 538.8886413574219,
			["GetX"] = nil --[[ skipped inline function ]],
			["Cross"] = nil --[[ skipped inline function ]],
			["GetY"] = nil --[[ skipped inline function ]],
			["SetXY"] = nil --[[ skipped inline function ]],
			["DistanceSquared"] = nil --[[ skipped inline function ]],
			["GetNormal"] = nil --[[ skipped inline function ]],
		}, -- [2]
		{
			["IsLeftOrOnOf"] = nil --[[ skipped inline function ]],
			["LengthSquared"] = nil --[[ skipped inline function ]],
			["IsLeftOf"] = nil --[[ skipped inline function ]],
			["Dot"] = nil --[[ skipped inline function ]],
			["Length"] = nil --[[ skipped inline function ]],
			["IsRightOrOnOf"] = nil --[[ skipped inline function ]],
			["GetXY"] = nil --[[ skipped inline function ]],
			["IsRightOf"] = nil --[[ skipped inline function ]],
			["Distance"] = nil --[[ skipped inline function ]],
			["ToPerpendicular"] = nil --[[ skipped inline function ]],
			["y"] = -111.7969699435764,
			["x"] = 538.8886413574219,
			["GetX"] = nil --[[ skipped inline function ]],
			["Cross"] = nil --[[ skipped inline function ]],
			["GetY"] = nil --[[ skipped inline function ]],
			["SetXY"] = nil --[[ skipped inline function ]],
			["DistanceSquared"] = nil --[[ skipped inline function ]],
			["GetNormal"] = nil --[[ skipped inline function ]],
		}, -- [3]
		{
			["IsLeftOrOnOf"] = nil --[[ skipped inline function ]],
			["LengthSquared"] = nil --[[ skipped inline function ]],
			["IsLeftOf"] = nil --[[ skipped inline function ]],
			["Dot"] = nil --[[ skipped inline function ]],
			["Length"] = nil --[[ skipped inline function ]],
			["IsRightOrOnOf"] = nil --[[ skipped inline function ]],
			["GetXY"] = nil --[[ skipped inline function ]],
			["IsRightOf"] = nil --[[ skipped inline function ]],
			["Distance"] = nil --[[ skipped inline function ]],
			["ToPerpendicular"] = nil --[[ skipped inline function ]],
			["y"] = -100,
			["x"] = 300,
			["GetX"] = nil --[[ skipped inline function ]],
			["Cross"] = nil --[[ skipped inline function ]],
			["GetY"] = nil --[[ skipped inline function ]],
			["SetXY"] = nil --[[ skipped inline function ]],
			["DistanceSquared"] = nil --[[ skipped inline function ]],
			["GetNormal"] = nil --[[ skipped inline function ]],
		}, -- [4]
		{
			["IsLeftOrOnOf"] = nil --[[ skipped inline function ]],
			["LengthSquared"] = nil --[[ skipped inline function ]],
			["IsLeftOf"] = nil --[[ skipped inline function ]],
			["Dot"] = nil --[[ skipped inline function ]],
			["Length"] = nil --[[ skipped inline function ]],
			["IsRightOrOnOf"] = nil --[[ skipped inline function ]],
			["GetXY"] = nil --[[ skipped inline function ]],
			["IsRightOf"] = nil --[[ skipped inline function ]],
			["Distance"] = nil --[[ skipped inline function ]],
			["ToPerpendicular"] = nil --[[ skipped inline function ]],
			["y"] = -50,
			["x"] = 150,
			["GetX"] = nil --[[ skipped inline function ]],
			["Cross"] = nil --[[ skipped inline function ]],
			["GetY"] = nil --[[ skipped inline function ]],
			["SetXY"] = nil --[[ skipped inline function ]],
			["DistanceSquared"] = nil --[[ skipped inline function ]],
			["GetNormal"] = nil --[[ skipped inline function ]],
		}, -- [5]
	},
}
