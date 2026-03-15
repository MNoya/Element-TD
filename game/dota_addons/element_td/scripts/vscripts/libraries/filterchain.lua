FILTERCHAIN_VERSION = "1.0.0"

local FilterChain = {}
FilterChain.__index = FilterChain

function FilterChain:New()
  return setmetatable({ filters = {} }, self)
end

function FilterChain:AddFilter(fn, context)
  table.insert(self.filters, { fn = fn, context = context })
end

function FilterChain:Execute(payload)
  for _, entry in ipairs(self.filters) do
    if not entry.fn(entry.context, payload) then
      return false
    end
  end

  return true
end

_G.FilterChain = FilterChain