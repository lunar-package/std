local String = {}
function String.charCodeAt(str: string, index: number): number
  if type(index) ~= "number" then
    index = 1
  end

  local length = string.len(str)
  if index < 1 or index > length then
    return 0 / 0
  end

  -- utf8.offset returns nil for out of bounds
  local offset = utf8.offset(str, index)

  if offset == nil or offset > length then
    return 0 / 0
  end

  local value = utf8.codepoint(str, offset, offset)

  if value == nil then
    return 0 / 0
  end

  return value
end

function String.lastIndexOf(str: string, searchValue: string, fromIndex: number?): number
  local strLength = string.len(str)
  local calculatedFromIndex
  if fromIndex then
    calculatedFromIndex = fromIndex
  else
    calculatedFromIndex = strLength
  end
  if fromIndex and fromIndex < 1 then
    calculatedFromIndex = 1
  end
  if fromIndex and fromIndex > strLength then
    calculatedFromIndex = strLength
  end
  if searchValue == "" then
    return calculatedFromIndex :: number
  end

  local lastFoundStartIndex, foundStartIndex
  local foundEndIndex: number? = 0
  repeat
    lastFoundStartIndex = foundStartIndex
    foundStartIndex, foundEndIndex = string.find(str, searchValue, foundEndIndex :: number + 1, true)
  until foundStartIndex == nil or foundStartIndex > calculatedFromIndex

  if lastFoundStartIndex == nil then
    return -1
  end
  return lastFoundStartIndex :: number
end

function String.slice(str: string, startIndexStr: string | number, lastIndexStr: (string | number)?): string
  local strLen, invalidBytePosition = utf8.len(str)
  assert(strLen ~= nil, ("string `%s` has an invalid byte at position %s"):format(str, tostring(invalidBytePosition)))
  local startIndex = tonumber(startIndexStr)
  assert(typeof(startIndex) == "number", "startIndexStr should be a number")

  if startIndex + strLen < 0 then
    -- then |start index| is greater than string length
    startIndex = 1
  end

  if startIndex > strLen then
    return ""
  end

  local lastIndex = strLen + 1
  if lastIndexStr ~= nil then
    local NaN = 0 / 0
    lastIndex = tonumber(lastIndexStr) or NaN -- this works because 0 is truthy in Lua
  end
  assert(typeof(lastIndex) == "number", "lastIndexStr should convert to number")

  if lastIndex > strLen then
    lastIndex = strLen + 1
  end

  local startIndexByte = utf8.offset(str, startIndex) :: number
  local lastIndexByte = utf8.offset(str, lastIndex) :: number - 1

  return string.sub(str, startIndexByte, lastIndexByte)
end

return setmetatable(String, {
  __index = string,
})
