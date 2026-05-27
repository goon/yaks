#!/usr/bin/env bash

INPUT_FILE="$1"
THEME_ID="$2"
OUTPUT_FILE="$3"

if [ -z "$INPUT_FILE" ] || [ -z "$THEME_ID" ] || [ -z "$OUTPUT_FILE" ]; then
    echo "Usage: $0 <input_file> <theme_id> <output_file>"
    exit 1
fi

mkdir -p "$(dirname "$OUTPUT_FILE")"

EXTENSION="${OUTPUT_FILE##*.}"
FILENAME=$(basename "$OUTPUT_FILE" ."$EXTENSION")
DIRNAME=$(dirname "$OUTPUT_FILE")
TEMP_FILE="$DIRNAME/${FILENAME}_temp.${EXTENSION}"

rm -f "$TEMP_FILE"

if cat "$INPUT_FILE" | gowall convert - - --theme "$THEME_ID" > "$TEMP_FILE"; then
    mv "$TEMP_FILE" "$OUTPUT_FILE"
    exit 0
else
    rm -f "$TEMP_FILE"
    exit 1
fi
