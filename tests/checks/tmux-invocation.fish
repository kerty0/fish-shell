#RUN: fish=%fish %fish %s
#REQUIRES: command -v tmux

isolated-tmux-start

# Implicit interactive but output is redirected.
touch output
tmux-send '$fish >output' enter
sleep-until 'cat output' --output 'prompt 1>'
tmux-send 'status is-interactive && printf %s i n t e r a c t i v e \n' enter ctrl-d
# Extract the line where command output starts.
sleep-until 'cat output' --regex '\e\]133;C'
string match <output -re '\e\]133;C'
# CHECK: {{.*}}interactive{{$}}

tmux-send '$fish -c "read; cat"' enter
tmux-wait 'read>'
tmux-send 'read-value ' enter
tmux-wait read-value\nread-value
tmux-send cat1 enter
tmux-wait cat1\ncat1
tmux-send cat2 enter
tmux-wait cat2\ncat2
tmux-capture --no-sync -S 2
# CHECK: read> read-value
# CHECK: read-value cat1
# CHECK: cat1
# CHECK: cat2
# CHECK: cat2
