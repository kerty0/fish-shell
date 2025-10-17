#RUN: %fish %s
#REQUIRES: command -v tmux

isolated-tmux-start -C '
    function usr1_handler --on-signal SIGUSR1
        echo Got SIGUSR1
        # This repaint is not needed but make sure it is coalesced.
        commandline -f repaint
    end
'

tmux-send 'kill -SIGUSR1 $fish_pid' Enter
tmux-capture
# CHECK: prompt 0> kill -SIGUSR1 $fish_pid
# CHECK: Got SIGUSR1
# CHECK: prompt 1>
