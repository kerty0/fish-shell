#RUN: %fish %s
#REQUIRES: command -v tmux
# # Somehow $LINES is borked on NetBSD?
# #REQUIRES: test $(uname) != NetBSD
# # Haunted under CI
# #REQUIRES: test -z "$CI"

isolated-tmux-start -C '
    set -g fish_autosuggestion_enabled 0
    bind ctrl-q "functions --erase fish_right_prompt" repaint
    bind ctrl-g "__fish_echo commandline --current-job"
    bind ctrl-t \'__fish_echo echo cursor is at offset $(commandline --cursor --current-token) in token\'
'

tmux-send 'echo LINES $LINES' Enter
tmux-capture
# CHECK: prompt 0> echo LINES $LINES
# CHECK: LINES 10
# CHECK: prompt 1>

tmux-send 'bind alt-g "commandline -p -C -- -4"' Enter ctrl-l
tmux-send 'echo bar|cat' alt-g foo
tmux-wait 'echo foobar|cat'
tmux-capture
# CHECK: prompt 2> echo foobar|cat

tmux-send 'commandline -i "\'$(seq $LINES)" scroll_here' Enter
tmux-capture -S -1
# CHECK: prompt 2> commandline -i "'$(seq $LINES)" scroll_here
# CHECK: 2
# CHECK: 3
# CHECK: 4
# CHECK: 5
# CHECK: 6
# CHECK: 7
# CHECK: 8
# CHECK: 9
# CHECK: 10
# CHECK: scroll_here

tmux-send 'function fish_right_prompt; echo right-prompt; end' Enter
tmux-send 'commandline -i ": \'$(seq (math $LINES \* 2))\'"' Enter Enter
tmux-capture -S -12 # TODO: macOS???
# CHECK: prompt 4> commandline -i ": '$(seq (math $LINES \* 2))'"            right-prompt
# CHECK: prompt 5> : '1                                                      right-prompt
# CHECK: 2
# CHECK: 3
# CHECK: 4
# CHECK: 5
# CHECK: 6
# CHECK: 7
# CHECK: 8
# CHECK: 9
# CHECK: 10
# CHECK: 11
# CHECK: 12
# CHECK: 13
# CHECK: 14
# CHECK: 15
# CHECK: 16
# CHECK: 17
# CHECK: 18
# CHECK: 19
# CHECK: 20'
# CHECK: prompt 6>                                                           right-prompt

# Soft-wrapped commandline with omitted right prompt.
# CHECK: prompt {{\d+}}> echo 00000000000000000000000000000000000000000000000000000000000000000
tmux-send 'commandline -i "echo $(printf %0"$COLUMNS"d)"' Enter ctrl-l Enter
tmux-capture
# CHECK: 000000000000000
# CHECK: 00000000000000000000000000000000000000000000000000000000000000000000000000000000
# CHECK: prompt {{\d+}}>                                                           right-prompt

# Disable right prompt
tmux-send ctrl-q

tmux-send 'echo | echo\;' alt-Enter 'another job' ctrl-b ctrl-b ctrl-g
tmux-capture
# CHECK: prompt {{\d+}}> echo | echo;
# CHECK:          another job
# CHECK: another job
# CHECK: prompt {{\d+}}> echo | echo;
# CHECK:          another job

tmux-send 'echo foobar' Left Left Left ctrl-t
tmux-capture
# CHECK: prompt {{\d+}}> echo foobar
# CHECK: cursor is at offset 3 in token
# CHECK: prompt {{\d+}}> echo foobar

tmux-send 'bind ctrl-x,a "__fish_echo echo line=(commandline --line) column=(commandline --column)"' Enter ctrl-l
tmux-send "echo '1" Enter 2
tmux-wait 2
tmux-send ctrl-x a ctrl-a Up ctrl-x a
tmux-capture
# CHECK: prompt {{\d+}}> echo '1
# CHECK: 2
# CHECK: line=2 column=2
# CHECK: prompt {{\d+}}> echo '1
# CHECK: 2
# CHECK: line=1 column=1
# CHECK: prompt {{\d+}}> echo '1
# CHECK: 2
