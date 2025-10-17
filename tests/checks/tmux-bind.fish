#RUN: %fish %s
#REQUIRES: command -v tmux

isolated-tmux-start

# Test moving around with up-or-search on a multi-line commandline.
tmux-send 'echo 12' alt-Enter 'echo ab' ctrl-p 345 ctrl-n cde
tmux-wait "echo abcde"
tmux-capture
# CHECK: prompt 0> echo 12345
# CHECK: echo abcde

tmux-send begin Enter 'echo 1' Enter e n d ctrl-p 23
tmux-wait "echo 123"
tmux-capture
# CHECK: prompt 0> begin
# CHECK: echo 123
# CHECK: end

# regression test
tmux-send 'bind S begin-selection' Enter ctrl-l
tmux-send 'echo one two threeS' ctrl-u ctrl-y
tmux-capture
# CHECK: prompt 1> echo one two three
