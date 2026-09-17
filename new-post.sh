#!/bin/sh
# POSIX sh; only standard system utilities (date and mkdir) are needed.
set -eu

# Locate the project even when invoked from another directory.
script_path=$0
case $script_path in
  */*) ;;
  *) script_path=$(command -v "$script_path") ;;
esac
script_dir=${script_path%/*}
case $script_dir in
  /*) ;;
  *) script_dir=./$script_dir ;;
esac
script_dir=$(CDPATH= cd -P "$script_dir" && pwd)
mkdir -p "$script_dir/_posts"

timestamp=$(date -u '+%Y-%m-%d %H:%M:%S +0000')
base=$script_dir/_posts/${timestamp%% *}-post-title
post_path=$base.md
number=1
while [ -e "$post_path" ] || [ -L "$post_path" ]; do
  post_path=$base-$number.md
  number=$((number + 1))
done

# Also prevent overwrites if another process creates the file meanwhile.
set -C
cat_placeholder() {
  printf '%s\n' '---' 'layout: post' 'title: "POST-TITLE"'
  printf 'date: %s\n' "$timestamp"
  printf '%s\n' 'categories: CATEGORY-1 CATEGORY-2' '---' '' 'Write your article here using **Markdown**.'
}
cat_placeholder > "$post_path"
printf 'Created: %s\n' "$post_path"
