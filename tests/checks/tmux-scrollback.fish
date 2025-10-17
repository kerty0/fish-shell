#RUN: %fish %s
#REQUIRES: command -v tmux

isolated-tmux-start
tmux-send 'bind ctrl-g "commandline -f scrollback-push scrollback-push clear-screen"' Enter
tmux-send ctrl-g
tmux-capture
# CHECK: prompt 1>
