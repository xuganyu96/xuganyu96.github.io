-- Hours between 9 am and 6 pm, use light theme; else use dark theme
load_dt = os.date("*t", os.time())
light_hour_start = 9
light_hour_stop = 9

if load_dt.hour >= light_hour_start and load_dt.hour < light_hour_stop then
    vim.cmd("colorscheme PaperColor")
    vim.cmd("set bg=light")
else
    vim.cmd("colorscheme gruvbox")
    vim.cmd("set bg=dark")
end

vim.cmd("highlight Normal ctermbg=none")
vim.cmd("highlight NonText ctermbg=none")
