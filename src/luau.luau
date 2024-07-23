--!strict

local luau = require("@lune/luau")
local luaup = require("./internal/luaup")

export type Ast = luaup.Ast
export type ParseError = luaup.ParseError

export type ParseResult = { ast: Ast, success: true } | { error: ParseError, success: false }

export type Tokens = { luaup.Token }

local Luau = {}
function Luau.parse(input: string): ParseResult
  return luaup.ast.parse(input)
end

function Luau.tokens(input: luaup.Ast): Tokens
  return luaup.ast.tokens(input) :: Tokens
end

return setmetatable(Luau, {
  __index = luau,
})
