--------------
-- obsidian --
--------------
--
-- >>> oo # from shell, navigate to vault (optional)
--
-- # NEW NOTE
-- >>> on "Note Name" # call my "obsidian new note" shell script (~/bin/on)
-- >>>
-- >>> ))) <leader>on # inside vim now, format note as template
-- >>> ))) # add tag, e.g. fact / blog / video / etc..
-- >>> ))) # add hubs, e.g. [[python]], [[machine-learning]], etc...
-- >>> ))) <leader>of # format title
--
-- # END OF DAY/WEEK REVIEW
-- >>> or # review notes in inbox
-- >>>
-- >>> ))) <leader>ok # inside vim now, move to zettelkasten
-- >>> ))) <leader>odd # or delete
-- >>>
-- >>> og # organize saved notes from zettelkasten into notes/[tag] folders
-- >>> ou # sync local with Notion
--
-- navigate to vault
vim.keymap.set("n", "<leader>oo", ":cd /Users/idohaber/Silicon_Mind<cr>")
--
-- convert note to template and remove leading white space
vim.keymap.set("n", "<leader>on", ":ObsidianTemplate note<cr> :lua vim.cmd([[1,/^\\S/s/^\\n\\{1,}//]])<cr>")
-- strip date from note title and replace dashes with spaces
-- must have cursor on title
vim.keymap.set("n", "<leader>of", ":s/\\(# \\)[^_]*_/\\1/ | s/-/ /g<cr>")
--
-- search for files in full vault
vim.keymap.set("n", "<leader>os", ":Telescope find_files search_dirs={\"/Users/idohaber/Silicon_Mind\"}<cr>")
vim.keymap.set("n", "<leader>oz", ":Telescope live_grep search_dirs={\"/Users/idohaber/Silicon_Mind\"}<cr>")
--
-- search for files in notes (uncomment and modify if you want to limit search to a specific subfolder)
-- vim.keymap.set("n", "<leader>ois", ":Telescope find_files search_dirs={\"/Users/idohaber/Silicon_Mind/notes\"}<cr>")
-- vim.keymap.set("n", "<leader>oiz", ":Telescope live_grep search_dirs={\"/Users/idohaber/Silicon_Mind/notes\"}<cr>")
--
-- for review workflow
-- move file in current buffer to zettelkasten folder (create this folder if it doesn't exist)
vim.keymap.set("n", "<leader>ok", ":!mkdir -p /Users/idohaber/Silicon_Mind/zettelkasten && mv '%:p' /Users/idohaber/Silicon_Mind/zettelkasten<cr>:bd<cr>")
-- delete file in current buffer
vim.keymap.set("n", "<leader>odd", ":!rm '%:p'<cr>:bd<cr>")
