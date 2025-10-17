#RUN: %fish %s
#REQUIRES: command -v tmux

isolated-tmux-start -C '
    function fish_prompt
        printf "prompt $status_generation> <status=$status> <$prompt_var> "
        set prompt_var
    end
    function on_prompt_var --on-variable prompt_var
        commandline -f repaint
    end
    function token-info
        __fish_echo echo "current token is <$(commandline -t)>"
    end
    bind ctrl-g token-info
'

tmux-capture --no-clear
# CHECK: prompt 0> <status=0> <>

set -U prompt_var changed
tmux-send Enter
# CHECK: prompt 0> <status=0> <changed>

tmux-send "echo 123"
tmux-wait 123
tmux-send ctrl-g
tmux-capture
# CHECK: prompt 0> <status=0> <> echo 123
# CHECK: current token is <123>
# CHECK: prompt 0> <status=0> <> echo 123

tmux-send '
    function fish_prompt
        printf "full line prompt\nhidden<----------------------------------------------two-last-characters-rendered->!!"
    end
' Enter ctrl-l
tmux-send 'test "
indent"'
tmux-wait indent
tmux-capture
# CHECK: full line prompt
# CHECK: …<----------------------------------------------two-last-characters-rendered->!!
# CHECK: test "
# CHECK: indent"

tmux-send '
    function fish_prompt
        string repeat (math $COLUMNS) x
    end
' Enter ctrl-l
tmux-send 'echo hello'
tmux-wait 'echo hello'
tmux-capture
# CHECK: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
# CHECK: echo hello

tmux-send '
    function fish_prompt
        seq (math $LINES + 1)
    end
    function fish_right_prompt
        echo test
    end
' Enter
tmux-send Enter
tmux-capture -S -11
# CHECK: 1
# CHECK: 2
# CHECK: 3
# CHECK: 4
# CHECK: 5
# CHECK: 6
# CHECK: 7
# CHECK: 8
# CHECK: 9
# CHECK: 10
# CHECK: 11                                                                          test
# CHECK: 2
# CHECK: 3
# CHECK: 4
# CHECK: 5
# CHECK: 6
# CHECK: 7
# CHECK: 8
# CHECK: 9
# CHECK: 10
# CHECK: 11                                                                          test
