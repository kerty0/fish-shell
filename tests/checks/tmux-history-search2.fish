#RUN: %fish %s
#REQUIRES: command -v tmux
# #REQUIRES: test -z "$CI"

isolated-tmux-start

tmux-send ': 1' Enter
tmux-send ': ' alt-Up alt-Down alt-Up alt-Up alt-Up alt-Down Enter
tmux-send 'echo still alive' Enter
tmux-capture
# CHECK: prompt 0> : 1
# CHECK: prompt 1> : 1
# CHECK: prompt 2> echo still alive
# CHECK: still alive
# CHECK: prompt 3>

tmux-send 'complete : -xa "foobar foobaz"' Enter ctrl-l
tmux-send ': fooba' Enter
tmux-send Up Tab
tmux-capture
# CHECK: prompt 4> : fooba
# CHECK: prompt 5> : fooba
# CHECK: foobar  foobaz
