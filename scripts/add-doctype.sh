#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <filename>"
  exit 1
fi

FILE="$1"

if [ ! -f "$FILE" ]; then
  echo "Error: File '$FILE' not found."
  exit 1
fi

tmpfile=$(mktemp)
echo -e '<?xml version="1.0" encoding="UTF-8"?>\n<!DOCTYPE html>' > "$tmpfile"
cat "$FILE" >> "$tmpfile"
mv "$tmpfile" "$FILE"

echo "DOCTYPE successfully added to '$FILE'"
