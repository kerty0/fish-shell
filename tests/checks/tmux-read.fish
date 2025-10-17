#RUN: %fish %s
#REQUIRES: command -v tmux
# #REQUIRES: test -z "$CI"

isolated-tmux-start -C '
    function fish_greeting
        set -l name (read)
        echo hello $name
    end
'

tmux-send name enter
tmux-send 'echo foo' Enter
tmux-capture
# CHECK: read> name
# CHECK: hello name
# CHECK: prompt 0> echo foo
# CHECK: foo
# CHECK: prompt 1>
