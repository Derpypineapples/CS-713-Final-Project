#!/bin/sh
echo -ne '\033c\033]0;AWS Project\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/AWS Project Server.x86_64" "$@"
