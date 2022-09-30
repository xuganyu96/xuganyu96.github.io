-- Sane defaults
vim.cmd("set mouse=a")
vim.cmd("set laststatus=2")
vim.cmd("set number")
vim.cmd("set tabstop=4")
vim.cmd("set shiftwidth=4")
vim.cmd("set expandtab")
vim.cmd("set autoindent")
vim.cmd("set backspace=indent,eol,start")
vim.cmd("set clipboard^=unnamed,unnamedplus")
vim.cmd("set nowrap")
vim.cmd("nohlsearch")
vim.cmd("set incsearch")
-- vim.cmd("set colorcolumn=80,120")  duplicate of status line
vim.cmd("set signcolumn=number")
vim.cmd("set nohlsearch")
vim.cmd("set cursorline")

-- Hours between 9 am and 6 pm, use light theme; else use dark theme
load_dt = os.date("*t", os.time())
light_hour_start = 9
light_hour_stop = 18

if load_dt.hour >= light_hour_start and load_dt.hour < light_hour_stop then
    print("Use light theme")
    vim.cmd("colorscheme PaperColor")
    vim.cmd("set bg=light")
else
    print("Use dark theme")
    vim.cmd("colorscheme gruvbox")
    vim.cmd("set bg=dark")
end

