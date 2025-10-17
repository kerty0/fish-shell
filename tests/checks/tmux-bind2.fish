#RUN: %fish %s
#REQUIRES: command -v tmux

isolated-tmux-start -C '
    bind alt-delete backward-kill-token
    bind alt-left backward-token
    bind alt-right forward-token
    set fish_autosuggestion_enabled 0
    
    function prepend
        commandline --cursor 0
        commandline -i echo
    end
    bind ctrl-g prepend
'

tmux-send printf ctrl-g Space
tmux-capture
# CHECK: prompt 0> echo printf

tmux-send 'echo ; foo &| ' alt-delete 'bar | baz'
tmux-wait 'bar | baz'
tmux-capture
# CHECK: prompt 0> echo ; bar | baz

# To-do: maybe include the redirection?
tmux-send 'echo >ooba' alt-left f alt-right r
tmux-wait 'echo >foobar'
tmux-capture
# CHECK: prompt 0> echo >foobar
