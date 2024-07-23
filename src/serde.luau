local serde = require("@lune/serde")

local Serde = {}

return setmetatable(Serde, {
  __index = serde,
})
