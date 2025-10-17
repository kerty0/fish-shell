#RUN: %fish %s
#REQUIRES: command -v tmux

isolated-tmux-start

tmux-send 'echo "foo bar baz"' Enter ctrl-l
tmux-send 'echo '
tmux-wait "foo bar baz"
tmux-send alt-Right
tmux-capture
# CHECK: prompt 1> echo "foo bar baz"

touch COMPL

# Regression test.
tmux-send ': sometoken' alt-b c
tmux-wait ': csometoken'
tmux-capture
# CHECK: prompt 1> : csometoken

# Test that we get completion autosuggestions also when the cursor is not at EOL.
tmux-send 'complete nofilecomp -f' Enter ctrl-l
tmux-send 'nofilecomp ./CO' ctrl-a alt-d :
tmux-wait ': ./COMPL'
tmux-capture
# CHECK: prompt 2> : ./COMPL

tmux-send ': ./CO'
tmux-wait ': ./COMPL'
tmux-send A ctrl-h
tmux-wait ': ./COMPL'
tmux-capture
# CHECK: prompt 2> : ./COMPL

# CHECK: prompt {{\d+}}> echo still alive
tmux-send 'ech {' Left Left o
tmux-send ctrl-e ctrl-h 'still alive' Enter
tmux-capture
# CHECK: still alive
# CHECK: prompt {{\d+}}>

tmux-send 'echo (echo)' Enter ctrl-l
tmux-send 'echo ('
tmux-wait 'echo (echo)'
tmux-capture
# CHECK: prompt {{\d+}}> echo (echo)
