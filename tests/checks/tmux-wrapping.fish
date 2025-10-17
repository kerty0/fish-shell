#RUN: %fish %s
#REQUIRES: command -v tmux

isolated-tmux-start -C '
    function fish_prompt; echo \'$ \'; end
    bind ctrl-g "commandline -i \'echo \'(printf %0(math \$COLUMNS - (string length \'\$ echo \'))d 0)"
'

tmux-send ctrl-g Enter
tmux-capture | awk 'NR <= 4 {print NR ":" $0}'

# CHECK: 1:$ echo 0000000000000000000000000000000000000000000000000000000000000000000000000
# CHECK: 2:0000000000000000000000000000000000000000000000000000000000000000000000000
# CHECK: 3:$
# CHECK: 4:
