#RUN: %fish %s
#REQUIRES: command -v tmux

isolated-tmux-start -C '
    function fish_prompt; end
    function fish_right_prompt
        set -q right_prompt
        and echo right-prompt
    end
    set right_prompt 1
    bind ctrl-g "set right_prompt 1" repaint
    bind alt-g "set -e right_prompt" repaint
'

tmux-send alt-g Enter ctrl-g Enter
tmux-capture | string replace -r '$' '+'
#CHECK: +
#CHECK: right-prompt+
#CHECK: right-prompt+
#CHECK: +
#CHECK: +
#CHECK: +
#CHECK: +
#CHECK: +
#CHECK: +
#CHECK: +

tmux-send alt-g Tab Tab
tmux-wait rows
tmux-capture | string replace -r '$' '+'
#CHECK: +
#CHECK: {{.*}}+
#CHECK: {{.*}}+
#CHECK: {{.*}}+
#CHECK: {{.*}}+
#CHECK: {{.*}}+
#CHECK: {{.*}}+
#CHECK: {{.*}}+
#CHECK: {{.*}}+
#CHECK: rows 1 to {{\d+}} of {{\d+}}+

tmux-send '
    function fish_prompt
        echo left-prompt\n
    end
' Enter ctrl-l
tmux-send Enter ctrl-g Enter
tmux-capture | string replace -r '$' '+'
#CHECK: left-prompt+
#CHECK: +
#CHECK: left-prompt+
#CHECK: right-prompt+
#CHECK: left-prompt+
#CHECK: right-prompt+
#CHECK: +
#CHECK: +
#CHECK: +
#CHECK: +

tmux-send alt-g Tab Tab
tmux-wait rows
tmux-capture | string replace -r '$' '+'
#CHECK: left-prompt+
#CHECK: +
#CHECK: {{.*}}+
#CHECK: {{.*}}+
#CHECK: {{.*}}+
#CHECK: {{.*}}+
#CHECK: {{.*}}+
#CHECK: {{.*}}+
#CHECK: {{.*}}+
#CHECK: rows 1 to {{\d+}} of {{\d+}}+
