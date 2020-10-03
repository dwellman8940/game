local addonName, envTable = ...
setfenv(1, envTable)

Mixin = {}

-- where ... are mixins to mix into object
function Mixin.MixinInto(object, ...)
    local n = select("#", ...)
    for i = 1, n do
        local mixin = select(i, ...)
        for k, v in pairs(mixin) do
            object[k] = v
        end
    end
    return object
end

-- where ... are mixins to mix into a new object
function Mixin.CreateFromMixins(...)
    return Mixin.MixinInto({}, ...)
end