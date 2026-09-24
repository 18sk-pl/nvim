-- ============================================================
-- 1. core 
-- ============================================================
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.have_nerd_font = false -- Set to true if your terminal uses a Nerd Font

vim.o.number = true
vim.o.relativenumber = true
vim.o.signcolumn = 'yes'
vim.o.cursorline = true
vim.o.termguicolors = true
vim.o.scrolloff = 8

vim.o.expandtab = true
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.softtabstop = 4
vim.o.smartindent = true
vim.o.breakindent = true

vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.undofile = true
vim.o.updatetime = 250
vim.o.timeoutlen = 300
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.clipboard = 'unnamedplus'

-- ============================================================
-- 2. keymaps 
-- ============================================================
local map = vim.keymap.set

map('n', '<Esc>', '<cmd>nohlsearch<CR>')

map('n', '<C-h>', '<C-w><C-h>', { desc = 'Focus left window' })
map('n', '<C-l>', '<C-w><C-l>', { desc = 'Focus right window' })
map('n', '<C-j>', '<C-w><C-j>', { desc = 'Focus lower window' })
map('n', '<C-k>', '<C-w><C-k>', { desc = 'Focus upper window' })

map('v', '<C-c>', '"+y', { desc = 'Copy to clipboard' })
map('v', '<C-x>', '"+d', { desc = 'Cut to clipboard' })
map('i', '<C-v>', '<Esc>"+pa', { desc = 'Paste from clipboard' })

local term_buf, term_win = nil, nil
local function toggle_terminal()
  if term_win and vim.api.nvim_win_is_valid(term_win) then
    vim.api.nvim_win_close(term_win, true)
    term_win = nil
    return
  end

  vim.cmd 'botright 12split'
  if not term_buf or not vim.api.nvim_buf_is_valid(term_buf) then
    vim.cmd 'terminal'
    term_buf = vim.api.nvim_get_current_buf()
  else
    vim.api.nvim_win_set_buf(0, term_buf)
  end
  term_win = vim.api.nvim_get_current_win()
  vim.cmd 'startinsert'
end

map('n', '<leader>t', toggle_terminal, { desc = '[T]oggle Terminal' })
map('t', '<Esc><Esc>', [[<C-\><C-n>]], { desc = 'Exit terminal mode' })

-- ============================================================
-- 3. lazy
-- ============================================================
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system {
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable',
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)

-- ============================================================
-- 4. lazy conf 
-- ============================================================
require('lazy').setup({
  {
    'folke/tokyonight.nvim',
    priority = 1000,
    config = function()
      vim.cmd.colorscheme 'tokyonight-night'
    end,
  },

  {
    'folke/which-key.nvim',
    event = 'VimEnter',
    opts = {
      spec = {
        { '<leader>s', group = '[S]earch' },
        { '<leader>c', group = '[C]ode / LSP' },
        { '<leader>d', group = '[D]ocument' },
      },
    },
  },

  { 'echasnovski/mini.nvim', version = false, config = function()
      require('mini.statusline').setup { use_icons = vim.g.have_nerd_font }
      require('mini.surround').setup()
      require('mini.ai').setup()
    end,
  },

  { 'lewis6991/gitsigns.nvim', opts = {} },

  { 'windwp/nvim-autopairs', event = 'InsertEnter', opts = {} },

  {
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    branch = '0.1.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make', cond = function() return vim.fn.executable 'make' == 1 end },
    },
    config = function()
      local builtin = require 'telescope.builtin'
      map('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
      map('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
      map('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      map('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Existing Buffers' })
    end,
  },

  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    main = 'nvim-treesitter.configs',
    opts = {
      ensure_installed = { 'c', 'cpp', 'asm', 'lua', 'vim', 'vimdoc', 'bash', 'markdown' },
      auto_install = true,
      highlight = { enable = true },
      indent = { enable = true },
    },
  },

  {
    'saghen/blink.cmp',
    version = 'v0.*',
    opts = {
      keymap = { preset = 'default' },
      sources = { default = { 'lsp', 'path', 'snippets', 'buffer' } },
      signature = { enabled = true },
    },
  },

  {
    'neovim/nvim-lspconfig',
    dependencies = {
      'williamboman/mason.nvim',
      'williamboman/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      'saghen/blink.cmp',
    },
    config = function()
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('user-lsp-attach', { clear = true }),
        callback = function(event)
          local buf_map = function(keys, func, desc)
            vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          buf_map('gd', vim.lsp.buf.definition, '[G]oto [D]efinition')
          buf_map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
          buf_map('gr', vim.lsp.buf.references, '[G]oto [R]eferences')
          buf_map('gi', vim.lsp.buf.implementation, '[G]oto [I]mplementation')
          buf_map('K', vim.lsp.buf.hover, 'Hover Documentation')
          buf_map('<leader>cr', vim.lsp.buf.rename, '[R]ename Symbol')
          buf_map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')
          buf_map('<leader>cd', vim.diagnostic.open_float, 'Show [D]iagnostics')
          buf_map('[d', vim.diagnostic.goto_prev, 'Previous Diagnostic')
          buf_map(']d', vim.diagnostic.goto_next, 'Next Diagnostic')
        end,
      })

      local capabilities = require('blink.cmp').get_lsp_capabilities()

      local servers = {
        clangd = {
          cmd = {
            'clangd',
            '--background-index',
            '--clang-tidy',
            '--header-insertion=iwyu',
            '--completion-style=detailed',
          },
        },
        lua_ls = {
          settings = {
            Lua = {
              diagnostics = { globals = { 'vim' } },
              workspace = { checkThirdParty = false },
            },
          }
        },
      }

    require('mason').setup()
    require('mason-tool-installer').setup { ensure_installed = { 'lua_ls' } }



      require('mason-lspconfig').setup {
        handlers = {
          function(server_name)
            local server = servers[server_name] or {}
            server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
            require('lspconfig')[server_name].setup(server)
          end,
        },
      }
    end,
  },
})
