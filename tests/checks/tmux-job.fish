#RUN: %fish %s
#REQUIRES: command -v tmux

isolated-tmux-start

mkfifo pipe
tmux-send "cat pipe &" Enter
tmux-send "echo hello"
tmux-wait "echo hello"
echo >pipe
tmux-wait "fish: Job 1, 'cat pipe &' has ended"
tmux-send Space world
tmux-wait "echo hello world"
tmux-capture
# CHECK: prompt 0> cat pipe &
# CHECK: prompt 0> echo hello
# CHECK: fish: Job 1, 'cat pipe &' has ended
# CHECK: prompt 0> echo hello world

tmux-send "cat pipe | cat &" Enter
tmux-send "bg %1" Enter
tmux-capture
# CHECK: prompt 0> cat pipe | cat &
# CHECK: prompt 0> bg %1
# CHECK: Send job 1 'cat pipe | cat &' to background
# CHECK: prompt 1>
