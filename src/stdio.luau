local stdio = require("@lune/stdio")

local Stdio = {}

return setmetatable(Stdio, {
  __index = stdio,
})
