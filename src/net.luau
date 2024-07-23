local formData = require("./formData")
local instanceof = require("./internal/instanceof")
local net = require("@lune/net")

local Net = {}

export type WebSocket = net.WebSocket
export type FetchResponse = net.FetchResponse
export type FormData = formData.FormData

export type FetchParams = {
  body: (buffer | string | formData.FormData)?,
  headers: {
    [string]: string | { string },
  }?,
  method: ("DELETE" | "GET" | "HEAD" | "OPTIONS" | "PATCH" | "POST" | "PUT")?,
  options: {
    decompress: boolean?,
  }?,
  query: {
    [string]: string | { string },
  }?,
  url: string,
}

function Net.fetch(config: FetchParams | string): FetchResponse
  if typeof(config) == "table" then
    if config.body and instanceof(config.body, formData) then
      local body = config.body :: formData.FormData
      config.body = body:decode()

      if config.headers == nil then
        config.headers = {}
      end

      if config.headers then
        config.headers["content-type"] = `multipart/form-data; boundary={body.uuid}`
      end
    end
  end

  return net.request(config :: net.FetchParams)
end

if not (net :: any).udpSocket then
  Net.udpSocket = function()
    local self = {}

    self.send = function() end
    self.next = function()
      coroutine.yield()
    end
    self.connect = function() end

    return self
  end

  Net.udpSocketClose = function() end
end

return setmetatable(Net, {
  __index = net,
})
