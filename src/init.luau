local Os = require("./os")
local formData = require("./formData")
local fs = require("./fs")
local luau = require("./luau")
local net = require("./net")
local path = require("./path")
local process = require("./process")
local sys = require("./sys")

export type FormData = net.FormData
export type FetchParams = net.FetchParams

export type process = process.process
export type Os = Os.Os
export type Path = path.Path

export type Ast = luau.Ast
export type Tokens = luau.Tokens
export type ParseError = luau.ParseError
export type ParseResult = luau.ParseResult

return {
  fs = fs,
  os = Os,
  process = process,
  path = path,
  sys = sys,
  net = net,
  formData = formData,
  luau = luau,
  internal = {
    luaup = require("./internal/luaup"),
  },
}
