local M = {}

local function has_file(path)
  return vim.fn.filereadable(path) == 1
end

local function dir_has(dir, file)
  return has_file(dir .. "/" .. file)
end

local function append_tasks(target, tasks)
  for _, task in ipairs(tasks) do
    table.insert(target, task)
  end
end

local function detect_task_templates()
  local cwd = vim.fn.getcwd()
  local templates = {}

  if dir_has(cwd, "package.json") then
    append_tasks(templates, {
      { name = "npm: dev", cmd = "npm run dev", kind = "run" },
      { name = "npm: build", cmd = "npm run build", kind = "build" },
      { name = "npm: test", cmd = "npm test", kind = "test" },
      { name = "npm: lint", cmd = "npm run lint", kind = "lint" },
    })
  end

  if dir_has(cwd, "angular.json") then
    append_tasks(templates, {
      { name = "angular: serve", cmd = "npm run start", kind = "run" },
      { name = "angular: build", cmd = "npm run build", kind = "build" },
      { name = "angular: test", cmd = "npm test", kind = "test" },
    })
  end

  if dir_has(cwd, "gradlew") then
    append_tasks(templates, {
      { name = "gradle: bootRun", cmd = "./gradlew bootRun", kind = "run" },
      { name = "gradle: build", cmd = "./gradlew build", kind = "build" },
      { name = "gradle: test", cmd = "./gradlew test", kind = "test" },
      { name = "gradle: clean", cmd = "./gradlew clean", kind = "clean" },
    })
  elseif dir_has(cwd, "build.gradle") or dir_has(cwd, "build.gradle.kts") then
    append_tasks(templates, {
      { name = "gradle: build", cmd = "gradle build", kind = "build" },
      { name = "gradle: test", cmd = "gradle test", kind = "test" },
      { name = "gradle: run", cmd = "gradle run", kind = "run" },
    })
  end

  if dir_has(cwd, "mvnw") then
    append_tasks(templates, {
      { name = "maven: spring-boot:run", cmd = "./mvnw spring-boot:run", kind = "run" },
      { name = "maven: package", cmd = "./mvnw package", kind = "build" },
      { name = "maven: test", cmd = "./mvnw test", kind = "test" },
    })
  elseif dir_has(cwd, "pom.xml") then
    append_tasks(templates, {
      { name = "maven: package", cmd = "mvn package", kind = "build" },
      { name = "maven: test", cmd = "mvn test", kind = "test" },
    })
  end

  return templates
end

function M.run_command(cmd, name)
  local ok, overseer = pcall(require, "overseer")
  if not ok then
    vim.notify("Overseer não está disponível.", vim.log.levels.WARN)
    return
  end

  overseer.new_task({
    name = name or cmd,
    cmd = "bash",
    args = { "-lc", cmd },
    cwd = vim.fn.getcwd(),
    components = { "default" },
  }, function(task)
    if not task then
      vim.notify("Falha ao criar task no Overseer.", vim.log.levels.WARN)
      return
    end
    task:start()
    overseer.open({ enter = false })
  end)
end

function M.run_template_picker()
  local templates = detect_task_templates()
  if #templates == 0 then
    vim.notify("Sem templates automáticos neste projeto. Usa <leader>oR.", vim.log.levels.INFO)
    return
  end

  vim.ui.select(templates, {
    prompt = "Escolhe uma task",
    format_item = function(item)
      return item.name .. "  ->  " .. item.cmd
    end,
  }, function(choice)
    if not choice then
      return
    end
    M.run_command(choice.cmd, choice.name)
  end)
end

function M.run_preset(kind)
  local templates = detect_task_templates()
  for _, task in ipairs(templates) do
    if task.kind == kind then
      M.run_command(task.cmd, task.name)
      return
    end
  end

  vim.notify("Preset '" .. kind .. "' não encontrado neste projeto.", vim.log.levels.INFO)
end

return M
