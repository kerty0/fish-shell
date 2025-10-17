#RUN: %fish %s
#REQUIRES: command -v tmux

isolated-tmux-start -C '
    set -g fish_key_bindings fish_vi_key_bindings
    bind -M insert \u91,s,y,n,c "tmux wait-for -S sync"
    bind -M insert \u91,e,s,c,a,p,e "set fish_bind_mode default"
'

tmux-send 'echo 124' Escape v b y p i 3
tmux-wait 'echo 1241234'
tmux-capture --no-clear
# CHECK: [I] prompt 0> echo 1241234

tmux-send Escape e r 5
tmux-capture --no-clear
# CHECK: [N] prompt 0> echo 1241235
