# GitHub repository setup

Repository creation and remote coordination use the shared
[git-collaboration skill](../agent/skills/git-collaboration/SKILL.md). The external agentic-rules
playbook owns commit/release conventions; each project owns its test and delivery commands.

The legacy `init_github_repo.sh` publisher is retired and exits 2 without side effects. It combined
broad staging, implicit public visibility and pushing with shell evaluation of a description.
There is no replacement publishing pipeline in this directory. Use `gh-axi` for authorized GitHub
operations and SSH Git remotes; inspect its help for the installed command surface.
