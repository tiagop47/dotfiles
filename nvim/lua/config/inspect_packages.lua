local M = {}

local function show_floating_content(title, lines)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"

  local width = math.min(90, math.floor(vim.o.columns * 0.8))
  local height = math.min(math.max(#lines + 2, 5), math.floor(vim.o.lines * 0.75))
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " " .. title .. " ",
    title_pos = "center",
  })

  local close_keys = { "q", "<Esc>", "<CR>", "<RightMouse>" }
  for _, key in ipairs(close_keys) do
    vim.keymap.set("n", key, function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end, { buffer = buf, silent = true, nowait = true })
  end
end

local function find_upwards(start_dir, pattern)
  local cur = start_dir
  while cur and #cur > 0 do
    local matches = vim.fn.globpath(cur, pattern, false, true)
    if #matches > 0 then
      return matches[1]
    end
    local parent = vim.fs.dirname(cur)
    if not parent or parent == cur then
      break
    end
    cur = parent
  end
  return nil
end

local function inspect_csproj(csproj_path)
  local lines = vim.fn.readfile(csproj_path)
  local packages = {}
  local project_refs = {}
  local target_framework = nil

  for _, line in ipairs(lines) do
    local tf = line:match("<TargetFramework>([^<]+)</TargetFramework>") or line:match("<TargetFrameworks>([^<]+)</TargetFrameworks>")
    if tf then target_framework = tf end

    local pkg, ver = line:match('<PackageReference%s+Include="([^"]+)"%s+Version="([^"]+)"')
    if not pkg then
      pkg = line:match('<PackageReference%s+Include="([^"]+)"')
      ver = line:match('Version="([^"]+)"') or "implícita / build"
    end
    if pkg then
      table.insert(packages, { name = pkg, version = ver or "latest" })
    end

    local proj_ref = line:match('<ProjectReference%s+Include="([^"]+)"')
    if proj_ref then
      local proj_name = vim.fs.basename(proj_ref:gsub("\\", "/"))
      table.insert(project_refs, proj_name)
    end
  end

  local output = {
    "# Projeto .NET: " .. vim.fs.basename(csproj_path),
    "Caminho: `" .. csproj_path .. "`",
    "",
  }

  if target_framework then
    table.insert(output, "**Target Framework:** " .. target_framework)
    table.insert(output, "")
  end

  table.insert(output, "## Project References (" .. #project_refs .. ")")
  if #project_refs == 0 then
    table.insert(output, "  _(nenhuma referência de projeto interna)_")
  else
    for _, ref in ipairs(project_refs) do
      table.insert(output, "  - 📦 " .. ref)
    end
  end
  table.insert(output, "")

  table.insert(output, "## NuGet Packages (" .. #packages .. ")")
  if #packages == 0 then
    table.insert(output, "  _(nenhum pacote NuGet externo referenciado)_")
  else
    for _, pkg in ipairs(packages) do
      table.insert(output, string.format("  - 🔹 **%-35s** `%s`", pkg.name, pkg.version))
    end
  end

  table.insert(output, "")
  table.insert(output, "_[Pressiona 'q' ou 'Esc' para fechar]_")

  show_floating_content("Pacotes & Referências .NET", output)
end

local function inspect_package_json(pkg_path)
  local content = table.concat(vim.fn.readfile(pkg_path), "\n")
  local ok, data = pcall(vim.json.decode, content)
  if not ok or type(data) ~= "table" then
    vim.notify("Não foi possível processar o package.json", vim.log.levels.WARN)
    return
  end

  local output = {
    "# Módulo Web / Angular: " .. (data.name or vim.fs.basename(vim.fs.dirname(pkg_path))),
    "Caminho: `" .. pkg_path .. "`",
    "",
  }

  local deps = data.dependencies or {}
  local dev_deps = data.devDependencies or {}

  local dep_keys = vim.tbl_keys(deps)
  table.sort(dep_keys)
  table.insert(output, "## Dependencies (" .. #dep_keys .. ")")
  if #dep_keys == 0 then
    table.insert(output, "  _(nenhuma dependência de produção)_")
  else
    for _, k in ipairs(dep_keys) do
      table.insert(output, string.format("  - 🔹 **%-35s** `%s`", k, deps[k]))
    end
  end
  table.insert(output, "")

  local dev_keys = vim.tbl_keys(dev_deps)
  table.sort(dev_keys)
  table.insert(output, "## DevDependencies (" .. #dev_keys .. ")")
  if #dev_keys == 0 then
    table.insert(output, "  _(nenhuma dependência de desenvolvimento)_")
  else
    for _, k in ipairs(dev_keys) do
      table.insert(output, string.format("  - 🛠️  **%-35s** `%s`", k, dev_deps[k]))
    end
  end

  table.insert(output, "")
  table.insert(output, "_[Pressiona 'q' ou 'Esc' para fechar]_")

  show_floating_content("Dependências package.json", output)
end

function M.inspect_node(node)
  if not node or not node.path then
    return
  end

  local path = node.path
  local dir = node.type == "directory" and path or vim.fs.dirname(path)

  -- 1. Se o próprio ficheiro for .csproj ou package.json
  if path:match("%.csproj$") then
    inspect_csproj(path)
    return
  elseif vim.fs.basename(path) == "package.json" then
    inspect_package_json(path)
    return
  end

  -- 2. Procura .csproj na diretoria ou acima
  local csproj = find_upwards(dir, "*.csproj")
  local pkg_json = find_upwards(dir, "package.json")

  -- Se for um ficheiro C# (.cs) ou estiver dentro de um projeto .NET
  if path:match("%.cs$") or (csproj and not pkg_json) then
    if csproj then
      inspect_csproj(csproj)
      return
    end
  end

  -- Se for um ficheiro TS/HTML/CSS/JSON ou tiver package.json mais próximo
  if pkg_json then
    inspect_package_json(pkg_json)
    return
  end

  if csproj then
    inspect_csproj(csproj)
    return
  end

  vim.notify("Nenhum .csproj ou package.json associado a este componente.", vim.log.levels.INFO)
end

return M
