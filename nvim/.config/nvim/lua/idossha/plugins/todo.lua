return {
    'idossha/nvim-todo',
    config = function()
        require('nvim-todo').setup({
            todo_dir = "/Users/idohaber/Silicon_Mind/Todo",
            active_todo_file = "todos.md",
            completed_todo_file = "completed_todos.md"
        })
    end
}
