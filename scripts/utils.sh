add_if_not_exists() {
  local line="$1"
  local file="$2"
  grep -qxF "$line" "$file" || echo "$line" >>"$file"
}

add_block_if_not_exists() {
  local source_file="$1"
  local target_file="$2"

  # Read the content of source file
  content=$(cat "$source_file")

  # Use awk to search for exact block
  if ! awk -v block="$content" 'BEGIN {p=1} index($0,block){p=0} END{exit p}' "$target_file"; then
    echo "$content" >>"$target_file"
    echo "Content added"
  else
    echo "Content already exists"
  fi
}
