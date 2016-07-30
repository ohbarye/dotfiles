#!/bin/bash -e

cd `tmux display-message -p -F "#{pane_current_path}"`
branch_name=`git branch | grep \*.* | sed -e 's/\*\ //'`

[ ! -z ${branch_name} ] && echo "[${branch_name}]"
