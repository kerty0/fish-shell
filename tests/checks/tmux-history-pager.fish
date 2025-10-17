#RUN: %fish %s
#REQUIRES: command -v tmux
# #REQUIRES: test -z "$CI"

# The default history-delete binding is shift-delete which
# won't work on terminals that don't support CSI u, so rebind.
isolated-tmux-start -C '
    set -g fish_autosuggestion_enabled 0
    bind alt-d history-delete 

    # Set up history
    for i in (seq 50 -1 1)
        history append "true $i$(if test $(math $i % 2) = 1; echo !; end)"
    end
'

tmux-send ctrl-r
tmux-wait "prompt 0> true 1!"
tmux-send ctrl-s
tmux-capture --no-clear
# CHECK: prompt 0> true 1!
# CHECK: search:
# CHECK: ► true 1!  ► true 3!  ► true 5!  ► true 7!  ► true 9!  ► true 11!
# CHECK: ► true 2   ► true 4   ► true 6   ► true 8   ► true 10  ► true 12
# CHECK: Items 1 to 12 of 50

tmux-send ctrl-r
tmux-wait "prompt 0> true 13!"
tmux-capture --no-clear
# CHECK: prompt 0> true 13!
# CHECK: search:
# CHECK: ► true 13!  ► true 15!  ► true 17!  ► true 19!  ► true 21!  ► true 23!
# CHECK: ► true 14   ► true 16   ► true 18   ► true 20   ► true 22   ► true 24
# CHECK: Items 13 to 24 of 50

tmux-send ctrl-s ctrl-s
tmux-wait "prompt 0> true 1!"
tmux-capture --no-clear
# CHECK: prompt 0> true 1!
# CHECK: search:
# CHECK: ► true 1!  ► true 3!  ► true 5!  ► true 7!  ► true 9!  ► true 11!
# CHECK: ► true 2   ► true 4   ► true 6   ► true 8   ► true 10  ► true 12
# CHECK: Items 1 to 12 of 50

tmux-send ctrl-r
tmux-wait "prompt 0> true 13!"
tmux-send ctrl-r
tmux-wait "prompt 0> true 25!"
tmux-capture --no-clear
# CHECK: prompt 0> true 25!
# CHECK: search:
# CHECK: ► true 25!  ► true 27!  ► true 29!  ► true 31!  ► true 33!  ► true 35!
# CHECK: ► true 26   ► true 28   ► true 30   ► true 32   ► true 34   ► true 36
# CHECK: Items 25 to 36 of 50

tmux-send ctrl-s
tmux-wait "prompt 0> true 13!"
tmux-capture --no-clear
# CHECK: prompt 0> true 13!
# CHECK: search:
# CHECK: ► true 13!  ► true 15!  ► true 17!  ► true 19!  ► true 21!  ► true 23!
# CHECK: ► true 14   ► true 16   ► true 18   ► true 20   ► true 22   ► true 24
# CHECK: Items 13 to 24 of 50

tmux-send ! ctrl-s
tmux-wait "prompt 0> true 1!"
tmux-capture --no-clear
# CHECK: prompt 0> true 1!
# CHECK: search: !
# CHECK: ► true 1!  ► true 5!  ► true 9!   ► true 13!  ► true 17!  ► true 21!
# CHECK: ► true 3!  ► true 7!  ► true 11!  ► true 15!  ► true 19!  ► true 23!
# CHECK: Items 1 to 24 of 50

tmux-send ctrl-r
tmux-wait "prompt 0> true 25!"
tmux-capture --no-clear
# CHECK: prompt 0> true 25!
# CHECK: search: !
# CHECK: ► true 25!  ► true 29!  ► true 33!  ► true 37!  ► true 41!  ► true 45!
# CHECK: ► true 27!  ► true 31!  ► true 35!  ► true 39!  ► true 43!  ► true 47!
# CHECK: Items 25 to 48 of 50

tmux-send ctrl-r ctrl-r
tmux-wait "prompt 0> true 49!"
tmux-capture --no-clear
# CHECK: prompt 0> true 49!
# CHECK: search: !
# CHECK: ► true 49!
# CHECK: Items 49 to 50 of 50

tmux-send alt-d
tmux-wait "prompt 0> true 47!"
tmux-send ctrl-r
tmux-capture --no-clear
# CHECK: prompt 0> true 47!
# CHECK: search: !
# CHECK: ► true 25!  ► true 29!  ► true 33!  ► true 37!  ► true 41!  ► true 45!
# CHECK: ► true 27!  ► true 31!  ► true 35!  ► true 39!  ► true 43!  ► true 47!
# CHECK: Items 25 to 49 of 49

tmux-send ctrl-s
tmux-wait "prompt 0> true 1!"
tmux-send ctrl-r
tmux-wait "prompt 0> true 25!"
tmux-send alt-d
tmux-wait "prompt 0> true 27!"
tmux-capture --no-clear
# CHECK: prompt 0> true 27!
# CHECK: search: !
# CHECK: ► true 27!  ► true 31!  ► true 35!  ► true 39!  ► true 43!  ► true 47!
# CHECK: ► true 29!  ► true 33!  ► true 37!  ► true 41!  ► true 45!
# CHECK: Items 26 to 48 of 48

for i in (seq 10)
    tmux-send alt-d
    tmux-wait "prompt 0> true $(math 27 + 2 \* $i)!"
end

tmux-send alt-d
tmux-wait "prompt 0> true 23!"
tmux-send Up
tmux-wait "prompt 0> true 21!"
tmux-send alt-d
tmux-wait "prompt 0> true 23!"
tmux-capture --no-clear
# CHECK: prompt 0> true 23!
# CHECK: search: !
# CHECK: ► true 1!  ► true 5!  ► true 9!   ► true 13!  ► true 17!  ► true 23!
# CHECK: ► true 3!  ► true 7!  ► true 11!  ► true 15!  ► true 19!

tmux-send !
tmux-wait "(no matches)"
tmux-capture --no-clear
# CHECK: prompt 0>
# CHECK: search: !!
# CHECK: (no matches)

tmux-send ctrl-u
tmux-wait "prompt 0> true 1!"
tmux-send alt-d
tmux-wait "prompt 0> true 2"
tmux-capture --no-clear
# CHECK: prompt 0> true 2
# CHECK: search:
# CHECK: ► true 2   ► true 4   ► true 6   ► true 8   ► true 10   ► true 12
# CHECK: ► true 3!  ► true 5!  ► true 7!  ► true 9!  ► true 11!  ► true 13!
# CHECK: Items 1 to 12 of 35

tmux-send - Escape
tmux-capture --no-clear
# CHECK: prompt 0>
