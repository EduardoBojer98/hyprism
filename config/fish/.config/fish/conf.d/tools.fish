# Interactive shell tools (CachyOS's fish config already provides the eza/ls aliases).
#   starship  prompt (config: ~/.config/starship.toml)
#   zoxide    `z proj` jumps to the most used matching folder, `zi` picks one with fzf
#   fzf       Ctrl+R history, Ctrl+T files, Alt+C folders
status is-interactive; or exit

command -q starship; and starship init fish | source
command -q zoxide; and zoxide init fish | source
command -q fzf; and fzf --fish | source

set -gx FZF_DEFAULT_COMMAND "fd --type f --hidden --exclude .git"
set -gx FZF_DEFAULT_OPTS "--height 40% --layout reverse --border rounded \
--color=bg+:#363a4f,bg:-1,spinner:#f4dbd6,hl:#ed8796,fg:#cad3f5,header:#ed8796,info:#c6a0f6,pointer:#f4dbd6,marker:#b7bdf8,fg+:#cad3f5,prompt:#c6a0f6,hl+:#ed8796,border:#494d64"
