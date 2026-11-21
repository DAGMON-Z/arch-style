-- Talks to two browser extensions on port 27121, the port CPH (the VS Code
-- extension) uses, so both work with Neovim:
--
--   Competitive Companion  sends problems (POST). They're passed on to
--                          competitest.nvim, which saves them, on port 27122.
--   CPH Submit             asks every 3 seconds for a solution to submit
--                          (GET /getSubmit). F7 puts one there.
--
-- Only one program can listen on a port, so only the first Neovim you open does
-- this. Other Neovims send their F7 submissions to that one.

local M = {}

M.port = 27121 -- the browser extensions use this port
M.competitest_port = 27122 -- competitest.nvim listens here (only for us)

local uv = vim.uv
local empty = { empty = true }
local pending = empty -- the solution waiting for CPH Submit
local server = nil

-- Problem URLs, saved when problems arrive, so F7 knows where to submit.
-- Key: the file name without extension, such as "A. Watermelon".
local db_path = vim.fn.stdpath("data") .. "/cp-problem-urls.json"

local function load_urls()
  local f = io.open(db_path, "r")
  if not f then
    return {}
  end
  local ok, data = pcall(vim.json.decode, f:read("*a"))
  f:close()
  return (ok and type(data) == "table") and data or {}
end

local function save_url(name, url)
  local urls = load_urls()
  urls[name] = url
  local f = io.open(db_path, "w")
  if f then
    f:write(vim.json.encode(urls))
    f:close()
  end
end

-- The same file name competitest uses for a problem
local function file_name(task_name)
  return (task_name:gsub('[<>:"/\\|?*]', "_"))
end

local function notify(msg, level)
  vim.schedule(function()
    vim.notify(msg, level or vim.log.levels.INFO, { title = "CP" })
  end)
end

-- Pass a problem from Competitive Companion on to competitest.nvim
local function forward_to_competitest(body)
  local client = uv.new_tcp()
  client:connect("127.0.0.1", M.competitest_port, function(err)
    if err then
      client:close()
      notify("A problem arrived, but competitest isn't listening. Press Space C r.", vim.log.levels.WARN)
      return
    end
    local request = "POST / HTTP/1.1\r\nContent-Type: application/json\r\n"
      .. "Content-Length: " .. #body .. "\r\n\r\n" .. body
    client:write(request, function()
      client:shutdown(function()
        client:close()
      end)
    end)
  end)
end

-- Answer one HTTP request. Returns status line and reply body.
local function route(method, path, headers, body)
  if method == "OPTIONS" then
    return "204 No Content", ""
  end
  if method == "GET" and path:match("^/getSubmit") then
    local reply = vim.json.encode(pending)
    -- Only the extension itself takes the solution (like CPH does)
    if headers:lower():match("\ncph%-submit:%s*true") and not pending.empty then
      notify("Brave is submitting " .. pending.fileName .. " now.")
      pending = empty
    end
    return "200 OK", reply
  end
  if method == "POST" and path == "/queue-submit" then
    local ok, data = pcall(vim.json.decode, body)
    if ok and type(data) == "table" and data.sourceCode then
      pending = data
      return "200 OK", '{"ok":true}'
    end
    return "400 Bad Request", '{"ok":false}'
  end
  if method == "POST" then
    -- A problem from Competitive Companion: remember its URL, then save it
    local ok, task = pcall(vim.json.decode, body)
    if ok and type(task) == "table" and type(task.name) == "string" and type(task.url) == "string" then
      save_url(file_name(task.name), task.url)
    end
    forward_to_competitest(body)
    return "200 OK", '{"ok":true}'
  end
  return "404 Not Found", '{"ok":false}'
end

local function handle(client)
  local data = ""
  client:read_start(function(err, chunk)
    if err or not chunk then
      if not client:is_closing() then
        client:close()
      end
      return
    end
    data = data .. chunk
    local head_end = data:find("\r\n\r\n", 1, true)
    if not head_end then
      return -- headers not complete yet
    end
    local head = data:sub(1, head_end - 1)
    local length = tonumber(head:lower():match("\ncontent%-length:%s*(%d+)")) or 0
    local body = data:sub(head_end + 4)
    if #body < length then
      return -- body not complete yet
    end
    client:read_stop()
    local method, path = head:match("^(%u+)%s+(%S+)")
    local status, reply = route(method or "", path or "", head, body:sub(1, length))
    local response = "HTTP/1.1 " .. status .. "\r\n"
      .. "Content-Type: application/json\r\n"
      .. "Access-Control-Allow-Origin: *\r\n"
      .. "Access-Control-Allow-Headers: *\r\n"
      .. "Access-Control-Allow-Methods: GET, POST, OPTIONS\r\n"
      .. "Content-Length: " .. #reply .. "\r\n"
      .. "Connection: close\r\n\r\n" .. reply
    client:write(response, function()
      if not client:is_closing() then
        client:close()
      end
    end)
  end)
end

--- Start listening on port 27121. Returns nil, or an error message.
function M.start()
  if server then
    return nil
  end
  local tcp = uv.new_tcp()
  local ok, err = tcp:bind("127.0.0.1", M.port)
  if ok then
    ok, err = tcp:listen(128, function(listen_err)
      if listen_err then
        return
      end
      local client = uv.new_tcp()
      tcp:accept(client)
      handle(client)
    end)
  end
  if not ok then
    tcp:close()
    return "port " .. M.port .. " is in use (" .. tostring(err) .. ")"
  end
  server = tcp
  return nil
end

function M.stop()
  if server then
    server:close()
    server = nil
  end
end

function M.is_listening()
  return server ~= nil
end

-- Codeforces' numbers for the compilers (CSES uses the same numbers)
local languages = {
  cpp = { id = 89, name = "GNU G++20 13.2 (64 bit)" },
  cc = { id = 89, name = "GNU G++20 13.2 (64 bit)" },
  c = { id = 43, name = "GNU GCC C11 5.1.0" },
  java = { id = 87, name = "Java 21 64bit" },
  py = { id = 70, name = "PyPy 3.10 (64 bit)" },
}

-- "1234A" for Codeforces URLs, like CPH does
local function problem_name(url)
  for _, pattern in ipairs({
    "/contest/(%d+)/problem/(%w+)",
    "/gym/(%d+)/problem/(%w+)",
    "/problemset/problem/(%d+)/(%w+)",
    "/problemset/gymProblem/(%d+)/(%w+)",
    "/problemsets/acmsguru/problem/(%d+)/(%w+)",
  }) do
    local contest, index = url:match(pattern)
    if contest then
      return contest .. index
    end
  end
  return ""
end

-- Send the solution to the Neovim that's listening (maybe this one)
local function queue(payload)
  local body = vim.json.encode(payload)
  local client = uv.new_tcp()
  client:connect("127.0.0.1", M.port, function(err)
    if err then
      client:close()
      notify("Nothing is listening for CPH Submit. Press Space C r, then F7 again.", vim.log.levels.WARN)
      return
    end
    local request = "POST /queue-submit HTTP/1.1\r\nHost: localhost\r\n"
      .. "Content-Type: application/json\r\nContent-Length: " .. #body .. "\r\n\r\n" .. body
    local reply = ""
    client:read_start(function(_, chunk)
      if chunk then
        reply = reply .. chunk
        return
      end
      client:close()
      if reply:match('"ok":true') then
        notify("Sent " .. payload.fileName .. " (" .. payload.languageName .. "). Brave submits it within a few seconds.")
      else
        notify("Submitting failed: Neovim didn't accept the solution.", vim.log.levels.ERROR)
      end
    end)
    client:write(request)
  end)
  -- If CPH Submit doesn't take it, say so
  vim.defer_fn(function()
    if server and not pending.empty and pending.fileName == payload.fileName then
      vim.notify(
        "Brave hasn't picked it up yet. Is Brave open, with the CPH Submit extension, and are you logged in?",
        vim.log.levels.WARN,
        { title = "CP" }
      )
    end
  end, 10000)
end

--- F7: save, then submit the current file with CPH Submit
function M.submit()
  vim.cmd("stopinsert")
  vim.cmd("silent! write")
  local file = vim.api.nvim_buf_get_name(0)
  local ext = vim.fn.fnamemodify(file, ":e")
  local lang = languages[ext]
  if file == "" or not lang then
    vim.notify("F7 submits C++, C, Java and Python files", vim.log.levels.WARN, { title = "CP" })
    return
  end
  local name = vim.fn.fnamemodify(file, ":t:r")
  local source = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n") .. "\n"

  local function send(url)
    queue({
      empty = false,
      problemName = problem_name(url),
      url = url,
      sourceCode = source,
      languageId = lang.id,
      -- not used by CPH Submit, only for our messages
      fileName = name,
      languageName = lang.name,
    })
  end

  local url = load_urls()[name]
  if url then
    send(url)
    return
  end
  -- Not received from the browser: ask for the problem's link once
  vim.ui.input({ prompt = "Problem link (copy it from Brave): " }, function(input)
    input = input and vim.trim(input) or ""
    if input:match("^https?://") then
      save_url(name, input)
      send(input)
    elseif input ~= "" then
      vim.notify("That isn't a link. It should start with https://", vim.log.levels.WARN, { title = "CP" })
    end
  end)
end

return M
