local source = {}

source.new = function()
  return setmetatable({}, { __index = source })
end

source.get_trigger_characters = function()
  return { "[" }
end

source.get_keyword_pattern = function()
  -- TODO: figure out wtf is going on here
  return [=[\%(\s\|^\)\zs\[\[.*]=]
end

---Backtrack through a string to find the first occurence of '[['.
---@param input string
---@return string
source._find_search_start = function(input)
  for i = string.len(input) - 1, 1, -1 do
    local substr = string.sub(input, i)
    if vim.startswith(substr, "[[") then
      return substr
    end
  end
  return input
end

source.complete = function(self, request, callback)
  local dir = self:option(request).dir
  if dir == nil then
    error "Obsidian completion has not been setup correctly!"
  end
  local client = require("obsidian").new(dir)

  local input = source._find_search_start(request.context.cursor_before_line)
  local suffix = string.sub(request.context.cursor_after_line, 1, 2)
  local search = string.sub(input, 3)

  -- TODO: make this work without auto closing brackets.
  -- TODO: suggest most recently used references when 'search' is empty.

  if string.len(search) > 0 and vim.startswith(input, "[[") and suffix == "]]" then
    local items = {}
    for _, note in pairs(client.cache:search_alias(search)) do
      for _, alias in pairs(note.aliases) do
        table.insert(items, {
          -- filterText = alias,
          -- insertText = "[[" .. note.id .. "|" .. alias .. "]]",
          label = "[[" .. note.id .. "|" .. alias .. "]]",
          kind = 18,
          textEdit = {
            newText = "[[" .. note.id .. "|" .. alias .. "]]",
            range = {
              start = {
                line = request.context.cursor.row - 1,
                character = request.context.cursor.col - 1 - #input,
              },
              ["end"] = {
                line = request.context.cursor.row - 1,
                character = request.context.cursor.col + 1,
              },
            },
          },
        })
      end
    end
    callback {
      items = items,
      isIncomplete = false,
    }
  else
    return callback { isIncomplete = true }
  end
end

source.option = function(_, params)
  return vim.tbl_extend("force", {
    dir = "./",
  }, params.option)
end

return source