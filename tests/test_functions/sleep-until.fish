function sleep-until
    argparse -i -x output,regex -S output= regex= error= -- $argv

    set -l condition
    if set -q _flag_output
        set condition 'string match -q  -- "*$_flag_output*" "$(eval $argv)"'
    else if set -q _flag_regex
        set condition 'string match -qr -- "$_flag_regex"    "$(eval $argv)"'
    else
        set condition $argv
    end

    set -q CI; and set -l sleep 0.3
    or set -l sleep 0.1

    for i in (seq 50)
        eval $condition &>/dev/null
        and return
        sleep $sleep
    end

    if set -q _flag_error
        echo "error: $_flag_error." >&2
    else if set -q _flag_output
        echo "error: time out waiting for \"$argv\" to output \"$_flag_output\"." >&2
    else if set -q _flag_regex
        echo "error: time out waiting for \"$argv\" to match \"$_flag_regex\"." >&2
    else
        echo "error: time out waiting for \"$argv\"." >&2
    end

    echo "Output of \"$argv\":" >&2
    eval $argv >&2
    exit 1
end
