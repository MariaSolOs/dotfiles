#
# ~/.bashrc
#

# If not running interactively, don't do anything.
[[ $- != *i* ]] && return

# Drop into fish if:
# - The parent process isn't fish.
# - Not running a command like `bash -c 'echo foo'`.
if [[ $(ps --no-header --pid=$PPID --format=comm) != "fish" && -z ${BASH_EXECUTION_STRING} ]]; then
  # Let fish whether it's a login shell.
  shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=''

  exec fish $LOGIN_OPTION
fi
