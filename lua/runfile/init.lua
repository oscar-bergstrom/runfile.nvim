local M = {}

-- Öppna en floating terminal och kör ett kommando
local function open_term(cmd)
  local buf = vim.api.nvim_create_buf(false, true)
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
  })

  vim.fn.termopen(cmd)
  vim.api.nvim_buf_set_keymap(buf, "n", "q", "<cmd>bd!<CR>", { nowait = true, noremap = true, silent = true })
end

-- Hjälpfunktion för att plocka namn från treesitter
local function get_node_name(node, valid_child_types)
  for child in node:iter_children() do
    if vim.tbl_contains(valid_child_types, child:type()) then
      return vim.treesitter.get_node_text(child, 0)
    end
  end
  return nil
end

-- Hämta klassnamn (Python + C++)
local function get_class_name()
  local ts_utils = require("nvim-treesitter.ts_utils")
  local node = ts_utils.get_node_at_cursor()

  while node do
    local t = node:type()
    if t == "class_definition" or t == "class_declaration"
       or t == "class_specifier" or t == "struct_specifier" then
      return get_node_name(node, { "identifier", "name", "type_identifier" })
    end
    node = node:parent()
  end
  return nil
end

-- Hämta funktionsnamn (Python + C++)
local function get_function_name()
  local ts_utils = require("nvim-treesitter.ts_utils")
  local node = ts_utils.get_node_at_cursor()

  while node do
    local t = node:type()
    if t == "function_definition" or t == "function_declaration"
       or t == "method_definition" or t == "function_declarator" then
      return get_node_name(node, { "identifier", "name" })
    end
    node = node:parent()
  end
  return nil
end

-- Kör bara filen
function M.run_current_file()
  local file = vim.fn.expand("%:p")
  open_term({ "bash", "run.sh", file })
end

-- Kör filen + klass
function M.run_current_file_with_class()
  local file = vim.fn.expand("%:p")
  local class_name = get_class_name()

  if class_name then
    open_term({ "bash", "run.sh", file, class_name })
  else
    print("Ingen klass hittades vid markören")
  end
end

-- Kör filen + metod/funktion
function M.run_current_file_with_method()
  local file = vim.fn.expand("%:p")
  local method_name = get_function_name()

  if method_name then
    open_term({ "bash", "run.sh", file, method_name })
  else
    print("Ingen funktion/metod hittades vid markören")
  end
end

-- Öppna en floating terminal (ren shell)
function M.open_terminal_float()
  local buf = vim.api.nvim_create_buf(false, true)
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
  })

  vim.fn.termopen(vim.o.shell or "bash")
  vim.cmd("startinsert")

  vim.api.nvim_buf_set_keymap(buf, "n", "q", "<cmd>bd!<CR>", { nowait = true, noremap = true, silent = true })
end

-- Registrera kommandon
function M.setup_commands()
  vim.api.nvim_create_user_command("RunFile", function()
    M.run_current_file()
  end, {})

  vim.api.nvim_create_user_command("RunClass", function()
    M.run_current_file_with_class()
  end, {})

  vim.api.nvim_create_user_command("RunMethod", function()
    M.run_current_file_with_method()
  end, {})

  vim.api.nvim_create_user_command("RunTerminal", function()
    M.open_terminal_float()
  end, {})
end

return M
