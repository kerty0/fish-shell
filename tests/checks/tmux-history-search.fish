#RUN: %fish %s
#REQUIRES: command -v tmux
# #REQUIRES: test -z "$CI"

# The default history-delete binding is shift-delete which
# won't work on terminals that don't support CSI u, so rebind.
isolated-tmux-start -C '
    set -g fish_autosuggestion_enabled 0
    bind alt-d history-delete
'

tmux-send 'true needle' Enter
# CHECK: prompt 0> true needle
tmux-send 'true hay ee hay' Enter
# CHECK: prompt 1> true hay ee hay
tmux-send ctrl-p ctrl-a alt-f alt-f alt-f alt-.
# CHECK: prompt 2> true hay needle hay
tmux-capture

tmux-send true Up Up Escape
tmux-capture --no-clear
# CHECK: prompt 2> true
tmux-send ctrl-z _
tmux-wait _
tmux-capture
# CHECK: prompt 2> _

# When history pager fails to find a result, copy the search field to the command line.
tmux-send ctrl-r
tmux-send "echo no such command in history"
tmux-wait "echo no such command in history"
tmux-send Enter
tmux-capture
# CHECK: prompt 2> echo no such command in history

tmux-send ctrl-r hay/shmay
tmux-send ctrl-w ctrl-h
tmux-wait "true hay ee hay"
tmux-send Enter
tmux-capture
# CHECK: prompt 2> true hay ee hay

tmux-send 'echo 1' Enter 'echo 2' Enter 'echo 3' Enter ctrl-l
tmux-send echo Up alt-d
tmux-capture
#CHECK: prompt 5> echo 2

tmux-send "echo sdifjsdoifjsdoifj" Enter
tmux-capture
# CHECK: prompt 5> echo sdifjsdoifjsdoifj
# CHECK: sdifjsdoifjsdoifj
# CHECK: prompt 6>

tmux-send ctrl-r "echo sdifjsdoifjsdoifj"
tmux-wait "► echo sdifjsdoifjsdoifj"
tmux-send alt-d
tmux-wait "(no matches)"
tmux-capture
# CHECK: prompt 6>
# CHECK: search: echo sdifjsdoifjsdoifj
# CHECK: (no matches)

tmux-send "echo foo" Enter
tmux-capture
# CHECK: prompt 6> echo foo
# CHECK: foo
# CHECK: prompt 7>
