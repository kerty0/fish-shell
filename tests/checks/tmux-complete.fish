#RUN: %fish %s
#REQUIRES: command -v tmux
# #REQUIRES: uname -r | grep -qv Microsoft
# # disable on github actions because it's flakey
# #REQUIRES: test -z "$CI"

isolated-tmux-start -C '
    set -g fish_autosuggestion_enabled 0
'

# Don't escape existing token (#7526).
echo >file-1
echo >file-2
tmux-send 'HOME=$PWD ls ~/' Tab
tmux-capture
# CHECK: prompt 0> HOME=$PWD ls ~/file-
# CHECK: ~/file-1  ~/file-2

# No pager on single smartcase completion (#7738).
tmux-send 'mkdir cmake CMakeFiles' Enter ctrl-l
tmux-send 'cat cmake' Tab
tmux-capture
# CHECK: prompt 1> cat cmake/

# Correct case in pager when prefixes differ in case (#7743).
tmux-send 'complete -c foo2 -a "aabc aaBd" -f' Enter ctrl-l
tmux-send 'foo2 A' Tab
tmux-capture
# CHECK: prompt 2> foo2 aa
# CHECK: aabc  aaBd

# Check that a larger-than-screen completion list does not stomp a multiline commandline (#8509).
tmux-send 'complete -c foo3 -fa "(seq $LINES)\t(string repeat -n $COLUMNS d)"' Enter ctrl-l
tmux-send begin Enter foo3 Enter "echo some trailing line" ctrl-p ctrl-e Space Tab Tab
tmux-capture
# Assert that we didn't change the command line.
# Also ensure that the pager is actually fully disclosed.
# CHECK: prompt 3> begin
# CHECK:               foo3
# CHECK:               echo some trailing line
# CHECK: 1 {{.+}}
# CHECK: 2 {{.+}}
# CHECK: 3 {{.+}}
# CHECK: 4 {{.+}}
# CHECK: 5 {{.+}}
# CHECK: 6 {{.+}}
# CHECK: rows 1 to {{\d+}} of {{\d+}}

# Canceling the pager removes the inserted completion, no matter what happens in the search field.
# The common prefix remains because it is inserted before the pager is shown.
tmux-send foo2 Space BTab b BSpace b Escape
tmux-capture
# CHECK: prompt 3> foo2 aa

# Check that completion works on unclosed brace with wildcard
tmux-send ': {*,' Tab Tab Space ,
tmux-wait ': {*,cmake/ ,'
tmux-capture
# CHECK: prompt 3> : {*,cmake/ ,

# Enable autosuggestion.
tmux-send "set -g fish_autosuggestion_enabled 1" Enter ctrl-l

# Check that down-or-search works even when the pager is not selected.
tmux-send foo2 Space Tab Down
tmux-wait foo2 aabc aabc
tmux-capture
# Also check that we show an autosuggestion.
# CHECK: prompt 3> foo2 aabc aabc
# CHECK: aabc  aaBd

# Check that a larger-than-screen completion does not break down-or-search.
tmux-send '
    complete -c foo4 -f -a "
        a-long-arg-\"$(seq $LINES | string pad -c_ --width $COLUMNS)\"
        b-short-arg
    "
' Enter ctrl-l
tmux-send foo4 Space Tab Tab Down
tmux-wait foo4 b-short-arg a-long-arg
tmux-capture
# CHECK: prompt 4> foo4 b-short-arg a-long-arg-{{.*}}
# CHECK: a-long-arg-{{.*}}
# CHECK: b-short-arg

# Check that completion pager followed by token search search inserts two separate tokens.
tmux-send echo Space old-arg Enter ctrl-l
tmux-send foo2 Space Tab Tab alt-.
tmux-capture
# CHECK: prompt 5> foo2 aabc old-arg

tmux-send 'echo suggest this' Enter ctrl-l
tmux-send 'echo sug' ctrl-w ctrl-z
tmux-wait 'echo suggest this'
tmux-capture
# CHECK: prompt 6> echo suggest this

tmux-send 'bind ctrl-s forward-single-char' Enter ctrl-l
tmux-send 'echo suggest thi'
tmux-wait 'echo suggest this'
tmux-send ctrl-s ctrl-s
tmux-capture
# CHECK: prompt 7> echo suggest this

tmux-send 'echo sugg' ctrl-a
tmux-wait 'echo suggest this'
tmux-send ctrl-e alt-f Space nothing
tmux-wait 'echo suggest nothing'
tmux-capture
# CHECK: prompt 7> echo suggest nothing

tmux-send 'bind ctrl-s forward-char-passive' Enter
tmux-send 'bind ctrl-b backward-char-passive' Enter
tmux-send 'echo do not accept this' Enter ctrl-l
tmux-send 'echo do not accept thi' ctrl-b ctrl-b DC ctrl-b ctrl-s h
tmux-send ctrl-s ctrl-s ctrl-s x
tmux-wait 'echo do not accept thix'
tmux-capture
# CHECK: prompt 10> echo do not accept thix
