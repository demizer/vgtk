-- source with luafile to run tree sitter test commands in the integrated terminal
-- DEPENDS ON https://github.com/akinsho/toggleterm.nvim

function vim.getVisualSelection()
    vim.cmd('noau normal! "vy"')
    local text = vim.fn.getreg("v")
    vim.fn.setreg("v", {})

    text = string.gsub(text, "\n", "")
    if #text > 0 then
        return text
    else
        return ""
    end
end

TSTEST = ""

vim.api.nvim_set_keymap("n", "<F1>", "<cmd>TermExec cmd='v . && ./vgtk'<CR>", { noremap = true, silent = true })

-- -- run a test with the visually selected string
-- vim.keymap.set("v", "<F2>", function()
--     TSTEST = vim.getVisualSelection()
--     vim.cmd("TermExec cmd='tree-sitter generate && tree-sitter test -d -D -f \"" .. TSTEST .. "\"'<CR>")
-- end, { noremap = true, silent = true })
--
-- -- rerun last visually selected test
-- vim.keymap.set("n", "<F2>", function()
--     vim.cmd("TermExec cmd='tree-sitter generate && tree-sitter test -d -D -f \"" .. TSTEST .. "\"'<CR>")
-- end, { noremap = true, silent = true })
--
-- -- update a test
-- vim.keymap.set("v", "<F3>", function()
--     TSTEST = vim.getVisualSelection()
--     vim.cmd("TermExec cmd='tree-sitter test -d -D -f \"" .. TSTEST .. "\" -u'<CR>")
-- end, { noremap = true, silent = true })
--
-- vim.keymap.set("n", "<F4>", function()
--     TSTEST = vim.getVisualSelection()
--     vim.cmd("TermExec cmd='python script/roadmapgen.py sync --jakt-path ~/src/jakt/jakt'<CR>")
-- end, { noremap = true, silent = true })
--
-- vim.keymap.set("n", "<F5>", function()
--     TSTEST = vim.getVisualSelection()
--     vim.cmd("TermExec cmd='python script/roadmapgen.py check --jakt-path ~/src/jakt/jakt'<CR>")
-- end, { noremap = true, silent = true })
