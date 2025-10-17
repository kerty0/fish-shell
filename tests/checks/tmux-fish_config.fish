#RUN: %fish %s

#REQUIRES: command -v tmux
#REQUIRES: command -v wget

isolated-tmux-start

tmux-send "BROWSER=true fish_config" enter
tmux-wait "Hit ENTER to stop"
# CHECK: prompt 0> BROWSER=true fish_config
# CHECK: Web config started at file://{{.*}}.html
# CHECK: If that doesn't work, try opening http://localhost:{{(\d{4})}}/{{\w+}}/
# CHECK: Hit ENTER to stop.

# Extract the URL from the output
set -l base_url (tmux-capture --no-sync -J | string match -r 'http://localhost:\d{4}/\w+/$')
or exit
set -l host_port (dirname $base_url)

# Check a bad URL (http://host:port/invalid_auth/)
wget -q -O - $host_port/invalid_auth/ &>/dev/null
# CHECK: {{.*}} code 403, message Forbidden, path /invalid_auth/

set -l last_status $status
# Busybox's wget does not return the same code as GNU's. Currently this affects
# the Alpine CI. If the Alpine image is update to GNU wget, we should be able to
# safely assume everybody uses GNU's (until we told otherwise)
switch "$(wget --version 2>&1)"
    case '*GNU*'
        test $last_status -eq 8
    case '*busybox*'
        test $last_status -eq 1
    case '*'
        # Only rely on the fish_config logs, which is the critical test.
        # The status code is only a "nice to have"
        true
end
or echo "Unexpected exit code ($last_status) from wget"

# Check a good URL
set -l workspace_root (path resolve -- (status dirname)/../../)
test "$(cat "$workspace_root/share/tools/web_config/index.html")" = "$(wget -q -O - $base_url 2>/dev/null)"
or echo 1

tmux-send enter
tmux-wait "prompt 1>"
tmux-capture -J
# CHECK: Shutting down.
# CHECK: prompt 1>
