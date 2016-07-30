#!/bin/bash -e

cd `tmux display-message -p -F "#{pane_current_path}"`
user_name=`git config --get user.name`
email_address=`git config --get user.email`

echo "[${user_name} | ${email_address}]"
