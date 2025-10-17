#RUN: %fish %s
#REQUIRES: command -v tmux && ! tmux -V | grep -qE '^tmux (next-3.4|3\.[0123][a-z]*($|[.-]))'
#REQUIRES: command -v less && ! less --version 2>&1 | grep -q BusyBox
# # disable on github actions because it's flakey
# #REQUIRES: test -z "$CI"

isolated-tmux-start -C '
    set -g fish_autosuggestion_enabled 0
    function fish_prompt
        printf "prompt-line-1\\nprompt-line-2> "
        commandline -f repaint
    end
'

tmux-send ': 1' Enter
tmux-send ': 3' Enter
tmux-send ': 5' Enter

# Screen looks like

# [y=0] prompt-line-1
# [y=1] prompt-line-2> : 1
# [y=2] prompt-line-1
# [y=3] prompt-line-2> : 3
# [y=4] prompt-line-1
# [y=5] prompt-line-2> : 5
# [y=6] prompt-line-1
# [y=7] prompt-line-2>

sleep-until "isolated-tmux display-message -p '#{cursor_y}'" --output 7
isolated-tmux copy-mode
sleep-until "isolated-tmux display-message -p '#{copy_cursor_y}'" --output 7
isolated-tmux send-keys -X previous-prompt
sleep-until "isolated-tmux display-message -p '#{copy_cursor_y}'" --output 6
isolated-tmux send-keys -X previous-prompt
sleep-until "isolated-tmux display-message -p '#{copy_cursor_y}'" --output 4
isolated-tmux display-message -p '#{copy_cursor_y} #{copy_cursor_line}'
# CHECK: 4 prompt-line-1

# Test that the prevd binding does not break the prompt.
tmux-send escape
tmux-send alt-left
tmux-capture -S 5
# CHECK: prompt-line-2> : 5
# CHECK: prompt-line-1
# CHECK: prompt-line-2>

# Test repainting after running an external program that uses the alternate screen.
tmux-send "bind ctrl-r 'echo | less -+F -+X +q; commandline \"echo Hello World\"'" Enter ctrl-l
tmux-send ctrl-r
tmux-send Enter
tmux-capture
# CHECK: prompt-line-1
# CHECK: prompt-line-2> echo Hello World
# CHECK: Hello World
# CHECK: prompt-line-1
# CHECK: prompt-line-2>

# Test that transient prompt does not break the prompt.
tmux-send "set fish_transient_prompt 1" Enter
tmux-send : Enter Enter
tmux-capture
# CHECK: prompt-line-1
# CHECK: prompt-line-2> set fish_transient_prompt 1
# CHECK: prompt-line-1
# CHECK: prompt-line-2> :
# CHECK: prompt-line-1
# CHECK: prompt-line-2>
# CHECK: prompt-line-1
# CHECK: prompt-line-2>
