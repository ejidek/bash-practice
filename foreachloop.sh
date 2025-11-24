#!/usr/bin/env bash

# Improved for-loop examples for daily DevOps tasks
# Shows: safe array iteration, indexed iteration, iterating files,
# reading lines, and counting words/characters per item.

set -euo pipefail

MY_FIRST_ARRAY=(one "two words" three "four-five" "six and seven")

echo "1) Safe array iteration (handles spaces):"
total_chars=0
for item in "${MY_FIRST_ARRAY[@]}"; do
	len=${#item}
	printf "  %-25s chars=%3d\n" "$item" "$len"
	total_chars=$((total_chars + len))
done
printf "  Total chars: %d\n\n" "$total_chars"

echo "2) Indexed iteration (access index and value):"
for idx in "${!MY_FIRST_ARRAY[@]}"; do
	printf "  index=%d value=%s\n" "$idx" "${MY_FIRST_ARRAY[$idx]}"
done
echo

# Directory to iterate (optional argument)
DIR="${1:-.}"

echo "3) Iterate files in directory: $DIR"
# enable nullglob so the pattern expands to nothing if no files
shopt -s nullglob
file_count=0
for f in "$DIR"/*; do
	# skip non-regular files
	[ -f "$f" ] || continue
	file_count=$((file_count+1))
	words=$(wc -w < "$f" 2>/dev/null || echo 0)
	chars=$(wc -m < "$f" 2>/dev/null || echo 0)
	printf "  %-40s words=%4s chars=%6s\n" "$(basename "$f")" "$words" "$chars"
done
shopt -u nullglob
if [ "$file_count" -eq 0 ]; then
	echo "  (no regular files found in $DIR)"
fi
echo

echo "4) Read lines safely (preserves spaces and backslashes):"
n=0
while IFS= read -r line; do
	n=$((n+1))
	printf "  Line %2d: %s\n" "$n" "$line"
done <<'EOF'
example line one
line with   multiple   spaces
line-with-special-chars: $PATH
EOF

echo
echo "Tips:"
echo " - Use \"\${arr[@]}\" to preserve elements with spaces." 
echo " - Use \"\${!arr[@]}\" to iterate indexes." 
echo " - Prefer 'while IFS= read -r' for reading lines from files or pipelines."

exit 0
