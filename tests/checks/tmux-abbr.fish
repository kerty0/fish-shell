#RUN: %fish %s
#REQUIRES: command -v tmux

isolated-tmux-start -C '
    set -g fish_autosuggestion_enabled 0
    function abbr-test
    end
    abbr -g abbr-test "abbr-test [expanded]"
'

# Expand abbreviations on space.
# CHECK: prompt {{\d+}}> abbr-test [expanded] arg1
tmux-send abbr-test Space arg1 Enter

# Expand abbreviations at the cursor when executing.
# CHECK: prompt {{\d+}}> abbr-test [expanded]
tmux-send abbr-test Enter

# Use Control+Z right after abbreviation expansion, to keep going without expanding.
# CHECK: prompt {{\d+}}> abbr-test arg2
tmux-send abbr-test Space ctrl-z arg2 Enter

# Same with a redundant space; it does not expand abbreviations.
# CHECK: prompt {{\d+}}> abbr-test  arg2
tmux-send abbr-test Space ctrl-z Space arg2 Enter

# Or use Control+Space to the same effect.
# CHECK: prompt {{\d+}}> abbr-test arg3
tmux-send abbr-test ctrl-Space arg3 Enter

# Do not expand abbreviation if the cursor is not at the command, even if it's just white space.
# This makes the behavior more consistent with the above two scenarios.
# CHECK: prompt {{\d+}}> abbr-test
# CHECK: prompt {{\d+}}>
tmux-send abbr-test ctrl-Space Enter

tmux-capture
