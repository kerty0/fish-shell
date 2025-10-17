#RUN: %fish %s
#REQUIRES: command -v tmux
# #REQUIRES: uname -r | grep -qv Microsoft
# # cautiously disable because tmux-complete.fish is disabled
# #REQUIRES: test -z "$CI"

isolated-tmux-start

tmux-send 'touch ~/"path with spaces"' Enter
tmux-capture
# CHECK: prompt 0> touch {{.*}}
# CHECK: prompt 1>

tmux-send 'cat ~/space' Tab
tmux-capture
# CHECK: prompt 1> cat ~/path\ with\ spaces

tmux-send '
    set -g fish_autosuggestion_enabled 0
    set -l FISH_TEST_VAR_1 /
    set -l FISH_TEST_VAR_2 /
' Enter ctrl-l
tmux-capture
# Note we keep prompt 1 because the above "set" commands don't bump $status_generation.
# CHECK: prompt 1>

tmux-send 'echo $FISH_TEST_v' Tab
tmux-capture
# CHECK: prompt 1> echo $FISH_TEST_VAR_
# CHECK: $FISH_TEST_VAR_1  (Variable: /)  $FISH_TEST_VAR_2  (Variable: /)
