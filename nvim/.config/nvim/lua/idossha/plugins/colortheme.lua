
return {

    -- Nightfox (Carbonfox DEFAULT THEME)
    {
        "EdenEast/nightfox.nvim",
        lazy = false,
        priority = 2000,  -- highest priority
        config = function()
            require("nightfox").setup({
                options = {
                    transparent = true,
                }
            })
            vim.cmd("colorscheme carbonfox")
        end
    },

    -- Kanagawa (installed, not default)
    {
        "rebelot/kanagawa.nvim",
        priority = 1000,
        config = function()
            require("kanagawa").setup({
                transparent = true,
                terminalColors = true,
                theme = "wave",
            })
            -- to use: :colorscheme kanagawa
        end
    },

    -- Gruvbox
    {
        "ellisonleao/gruvbox.nvim",
        priority = 900,
        config = function()
            require("gruvbox").setup({
                bold = false,
                italic = {
                    strings = false,
                    emphasis = true,
                    comments = true,
                    operators = false,
                    folds = false,
                },
                contrast = "hard",
                overrides = {
                    WhichKey = { bg = "NONE" },
                    WhichKeyNormal = { bg = "NONE" },
                    NormalFloat = { bg = "NONE" },
                    BlinkCmpMenu = { bg = "NONE" },
                    Pmenu = { bg = "NONE" },
                    PmenuThumb = { bg = "NONE" }
                },
                transparent_mode = true,
            })
            -- to use: :colorscheme gruvbox
        end
    },

    -- VSCode Theme
    {
        "Mofiqul/vscode.nvim",
        priority = 800,
        -- Uncomment if you ever want it as default:
        -- config = function()
        --     vim.cmd("colorscheme vscode")
        -- end
    },

}

