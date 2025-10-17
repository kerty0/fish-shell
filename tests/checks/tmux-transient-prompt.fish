#RUN: %fish %s
#REQUIRES: command -v tmux

isolated-tmux-start -C '
    function fish_prompt
        if set -q transient
            printf "> "
            set --erase transient
        else
            printf "> full prompt > "
        end
    end
    bind ctrl-j "set transient true; commandline -f repaint execute"
'

tmux-send 'echo foo' ctrl-j
tmux-wait 'full prompt'
tmux-capture
# CHECK: > echo foo
# CHECK: foo
# CHECK: > full prompt >

# Regression test for transient prompt with single-line prompts.
tmux-send '
    set -g fish_transient_prompt 1
    function fish_prompt
        printf "\$ "
    end
' Enter ctrl-l
tmux-send Enter Enter
tmux-capture
# CHECK: $
# CHECK: $
# CHECK: $

# Test that multi-line transient are properly cleared.
tmux-send '
    function fish_prompt
        if contains -- --final-rendering $argv
            printf "final line%d\n" 1 2
        else
            printf "transient line%d\n" 1 2
        end
    end
' Enter ctrl-l
tmux-send Enter
tmux-capture
# CHECK: final line1
# CHECK: final line2
# CHECK: transient line1
# CHECK: transient line2

# Test that multi-line initial prompt is properly cleared with single-line
# final.
tmux-send '
    function fish_prompt
        if contains -- --final-rendering $argv
            echo "2> "
        else
            echo "transient prompt line"
            echo "1> "
        end
    end
' Enter ctrl-l
tmux-send 'echo foo' Enter
tmux-capture
# CHECK: 2> echo foo
# CHECK: foo
# CHECK: transient prompt line
# CHECK: 1>

# Test that multi-line initial prompt is properly cleared with single-line
# final.
tmux-send 'echo foo \\' Enter
tmux-send bar Enter
tmux-capture
# CHECK: 2> echo foo \
# CHECK:        bar
# CHECK: foo bar
# CHECK: transient prompt line
# CHECK: 1>
