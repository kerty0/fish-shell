#RUN: %fish %s
#REQUIRES: command -v tmux
# #REQUIRES: test -z "$CI"

isolated-tmux-start

# Check no collapse
mkdir -p a/b
echo >a/b/f1
echo >a/b/f2
tmux-send 'HOME=$PWD ls ~/a/b/' Tab
tmux-capture
# CHECK: prompt 0> HOME=$PWD ls ~/a/b/f
# CHECK: ~/a/b/f1  ~/a/b/f2

# Check collapse
mkdir -p dddddd/eeeeee
echo >dddddd/eeeeee/file1
echo >dddddd/eeeeee/file2
tmux-send 'HOME=$PWD ls ~/dddddd/eeeeee/' Tab
tmux-capture
# CHECK: prompt 0> HOME=$PWD ls ~/dddddd/eeeeee/file
# CHECK: …/file1  …/file2
