function isolated-tmux-start --wraps fish
    set -l tmpdir (mktemp -d)
    cd $tmpdir

    echo 'set -g mode-keys emacs' >.tmux.conf

    function isolated-tmux --inherit-variable tmpdir --wraps tmux
        # tmux can't handle session sockets in paths that are too long, and macOS has a very long
        # $TMPDIR, so use a relative path - except macOS doesn't have `realpath --relative-to`...
        # Luckily, we don't need to call tmux from other directories, so just make sure no one
        # does by accident.
        if test $PWD != $tmpdir
            echo "error: isolated-tmux must always be run from the same directory." >&2
            return 1
        end
        tmux -S .tmux-socket -f .tmux.conf $argv
    end

    function isolated-tmux-cleanup --on-event fish_exit --inherit-variable tmpdir
        isolated-tmux kill-server
        rm -r $tmpdir
    end

    function tmux-timeout
        sh -c "$argv" &
        sleep-until "! jobs $last_pid"
    end

    function tmux-sync
        isolated-tmux send-keys \u0091sync
        tmux-timeout tmux -S .tmux-socket wait-for sync
    end

    function tmux-wait
        sleep-until "isolated-tmux capture-pane -p" --output "$argv"
    end

    function tmux-capture
        argparse -Si no-clear no-sync -- $argv

        set -q _flag_no_sync
        or tmux-sync

        isolated-tmux capture-pane -p $argv

        set -q _flag_no_sync || set -q _flag_no_clear
        or isolated-tmux send-keys \u0091clear C-l
    end

    function tmux-send
        set -l args
        for arg in $argv
            switch $arg
                case Enter
                    set -q args[1]
                    and isolated-tmux send-keys $args
                    and set args
                    isolated-tmux send-keys \u0091enter
                    tmux-timeout tmux -S .tmux-socket wait-for enter
                    continue
                case Escape
                    # Remove ambiguity with alt modifier and \e
                    set arg \u0091escape
                case ctrl-c
                    # Because of enabled ISIG 0x03 not at the end sequence are not reported. 
                    set arg \u0091clear
                case "*"
                    set arg "$(string replace -r -- '^((alt-|shift-)*)ctrl-' '$1C-' $arg)"
                    set arg "$(string replace -r -- '^((C-|shift-)*)alt-'    '$1M-' $arg)"
                    set arg "$(string replace -r -- '^((C-|M-)*)shift-'      '$1S-' $arg)"
            end
            set -a args $arg
        end
        set -q args[1]
        and isolated-tmux send-keys $args
    end

    set -l fish (status fish-path)
    set -l size -x 80 -y 10
    isolated-tmux new-session $size -d $fish -C '
        # This is similar to "tests/interactive.config".
        function fish_greeting; end
        function fish_prompt; printf "prompt $status_generation> "; end
        # No autosuggestion from older history.
        set fish_history ""
        # No transient prompt.
        set fish_transient_prompt 0
        
        # bind ctrl-j "commandline -i \\n"
        bind \u91,c,l,e,a,r clear-commandline
        bind \u91,e,s,c,a,p,e cancel
        bind \u91,s,y,n,c "tmux wait-for -S sync"
        bind \u91,e,n,t,e,r execute "tmux wait-for -S enter"
    ' $argv
    # Set the correct permissions for the newly created socket to allow future connections.
    # This is required at least under WSL or else each invocation will return a permissions error.
    chmod 777 .tmux-socket

    # Resize window so we can attach to tmux session without changing panel size.
    isolated-tmux resize-window $size

    # Sleep until we get an initial prompt.
    sleep-until "isolated-tmux capture-pane -p" --regex ".+" \
        --error "isolated-tmux-start timed out waiting for non-empty first prompt"
end
