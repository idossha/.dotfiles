--------------
-- obsidian --
--------------
-- Set vault path for consistency
local VAULT_PATH = "/Users/idohaber/Silicon_Mind"
local INBOX_PATH = VAULT_PATH .. "/inbox"

-- Search for files in vault with Telescope (doesn't change directory)
vim.keymap.set("n", "<leader>os", function()
  vim.cmd("Telescope find_files search_dirs={\"" .. VAULT_PATH .. "\"}")
end, { desc = "Find files in vault" })

-- Search for content in vault with Telescope (doesn't change directory)
vim.keymap.set("n", "<leader>og", function()
  vim.cmd("Telescope live_grep search_dirs={\"" .. VAULT_PATH .. "\"}")
end, { desc = "Search content in vault" })

-- Enhanced template selector with content preview
vim.api.nvim_create_user_command("ObsidianTemplatePreview", function()
  local template_dir = VAULT_PATH .. "/Templates"
  local templates = {}
  local template_content = {}
  
  -- Get templates and their content
  local handle = io.popen("ls -1 " .. template_dir .. " | grep .md")
  if handle then
    for file in handle:lines() do
      -- Remove .md extension for display
      local template_name = file:gsub("%.md$", "")
      table.insert(templates, template_name)
      
      -- Read template content for preview
      local file_path = template_dir .. "/" .. file
      local content_file = io.open(file_path, "r")
      if content_file then
        local content = content_file:read("*all")
        template_content[template_name] = content
        content_file:close()
      else
        template_content[template_name] = "Could not read template content"
      end
    end
    handle:close()
  end
  
  -- Use Telescope with previewer
  require("telescope.pickers").new({}, {
    prompt_title = "Select Template",
    finder = require("telescope.finders").new_table({
      results = templates,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry,
          ordinal = entry,
        }
      end
    }),
    sorter = require("telescope.config").values.generic_sorter({}),
    previewer = require("telescope.previewers").new_buffer_previewer({
      title = "Template Preview",
      define_preview = function(self, entry, status)
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, vim.split(template_content[entry.value] or "", "\n"))
        -- Set filetype to markdown for proper syntax highlighting in the preview
        vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "markdown")
      end
    }),
    attach_mappings = function(prompt_bufnr, map)
      require("telescope.actions").select_default:replace(function()
        local selection = require("telescope.actions.state").get_selected_entry()
        require("telescope.actions").close(prompt_bufnr)
        
        -- Apply the selected template
        if selection and selection.value then
          vim.cmd("ObsidianTemplate " .. selection.value)
          vim.notify("Applied template: " .. selection.value)
          
          -- Save the file immediately
          vim.cmd("write")
        end
      end)
      return true
    end
  }):find()
end, {})

-- Create a function to create a new note directly in inbox
vim.api.nvim_create_user_command("ObsidianNewInInbox", function()
  -- Prompt for the title
  local title = vim.fn.input("Enter note title: ")
  if title == "" then
    vim.notify("Note creation cancelled - empty title", vim.log.levels.WARN)
    return
  end
  
  -- Convert spaces to hyphens for file name
  local file_name = title:gsub(" ", "-")
  
  -- Create the full path in inbox
  local full_path = INBOX_PATH .. "/" .. file_name .. ".md"
  
  -- Ensure inbox directory exists
  vim.fn.mkdir(INBOX_PATH, "p")
  
  -- Create the file with a title
  local file = io.open(full_path, "w")
  if file then
    file:write("# " .. title .. "\n\n")
    file:close()
    
    -- Open the file
    vim.cmd("edit " .. vim.fn.fnameescape(full_path))
    
    -- Wait briefly for the file to be opened
    vim.defer_fn(function()
      -- Open template selector
      vim.cmd("ObsidianTemplatePreview")
    end, 100)
    
    vim.notify("Created new note in inbox: " .. title)
  else
    vim.notify("Failed to create note", vim.log.levels.ERROR)
  end
end, {})

-- Create new note with immediate template selection (accessible from anywhere)
vim.keymap.set("n", "<leader>on", ":ObsidianNewInInbox<CR>", 
  { desc = "Create new note in inbox with template" })

-- Open current file in Obsidian GUI
vim.keymap.set("n", "<leader>oo", function()
  -- Check if we're already in a markdown file
  local current_filetype = vim.bo.filetype
  
  if current_filetype == "markdown" then
    -- Use the Obsidian command directly
    vim.cmd("ObsidianOpen")
  else
    -- Notify the user that this only works with markdown files
    vim.notify("This command only works with markdown files", vim.log.levels.WARN)
  end
end, { desc = "Open in Obsidian" })

-- Delete current file
vim.keymap.set("n", "<leader>odd", function()
  local current_file = vim.fn.expand('%:p')
  local escaped_path = vim.fn.shellescape(current_file)
  
  local confirm = vim.fn.input("Delete " .. current_file .. "? (y/n): ")
  if confirm:lower() == "y" then
    local success = os.execute("rm " .. escaped_path)
    if success then
      vim.cmd("bd")
      vim.notify("File deleted")
    else
      vim.notify("Failed to delete file", vim.log.levels.ERROR)
    end
  else
    vim.notify("File deletion cancelled")
  end
end, { desc = "Delete current file" })

-- Execute oz script separately
vim.keymap.set("n", "<leader>oz", function()
  -- Display a message
  vim.notify("Processing inbox to Zettelkasten...")
  
  -- Execute the oz script
  local result = vim.fn.system("~/bin/oz")
  
  -- Display the result
  vim.notify(result)
end, { desc = "Process inbox to Zettelkasten" })
