#!/bin/bash

# ==============================================================================
# SCRIPT: md_normalize.sh
# DESCRIPTION: Normalizes any Markdown file to adhere strictly to MDRULES.md
#              (Human Readability First visual spacing constraints).
# ==============================================================================

set -euo pipefail

echo "================================================================================"
echo "[RUN] Starting Markdown normalization engine..."
echo "================================================================================"

if [ "$#" -ne 1 ]; then
  echo "  [ x ] Error: Invalid syntax."
  echo "        Usage: $0 <path_to_markdown_file.md>"
  echo "================================================================================"
  echo "[ERR] Normalization aborted due to missing arguments."
  echo "================================================================================"
  exit 1
fi

INPUT_FILE="$1"

if [ ! -f "$INPUT_FILE" ]; then
  echo "  [ x ] Error: File '$INPUT_FILE' not found."
  echo "================================================================================"
  echo "[ERR] Normalization aborted due to missing target file."
  echo "================================================================================"
  exit 1
fi

echo "  [ . ] Processing layout geometries for: $INPUT_FILE"

# Create a temporary file for processing
TMP_FILE=$(mktemp)
trap 'rm -f "$TMP_FILE"' EXIT

# ------------------------------------------------------------------------------
# STEP 1: Process file using a robust two-pass block cleaner in awk
# ------------------------------------------------------------------------------

awk '
BEGIN {
  H2_SEPARATOR = "________________________________________________________________________________"
  idx = 0
}

function trim(str) {
  gsub(/^[ \t\r\n]+|[ \t\r\n]+$/, "", str)
  return str
}

# --- PASS 1: Stream and strip all formatting artifact elements ---
{
  trimmed = trim($0)
  if (trimmed == "&nbsp;" || trimmed ~ /^_____________________+$/) {
    next
  }
  idx++
  raw_lines[idx] = $0
  clean_trimmed[idx] = trimmed
}

# --- PASS 2: Reconstruct exact layout geometries ---
END {
  output_idx = 0
  
  for (i = 1; i <= idx; i++) {
    t = clean_trimmed[i]
    line = raw_lines[i]
    
    # --------------------------------------------------------------------------
    # H2 HEADER PATTERN
    # --------------------------------------------------------------------------
    if (t ~ /^## /) {
      # Strip any trailing empty lines added by the previous text blocks
      while (output_idx > 0 && out_pool[output_idx] == "") {
        output_idx--
      }
      # Apply clean architectural spacing if not the absolute start of file
      if (output_idx > 0) {
        output_idx++; out_pool[output_idx] = ""
        output_idx++; out_pool[output_idx] = ""
        output_idx++; out_pool[output_idx] = "&nbsp;"
        output_idx++; out_pool[output_idx] = "&nbsp;"
        output_idx++; out_pool[output_idx] = ""
        output_idx++; out_pool[output_idx] = ""
        output_idx++; out_pool[output_idx] = H2_SEPARATOR
      }
      output_idx++; out_pool[output_idx] = ""
      output_idx++; out_pool[output_idx] = line
      output_idx++; out_pool[output_idx] = ""
      continue
    }
    
    # --------------------------------------------------------------------------
    # H3 HEADER PATTERN
    # --------------------------------------------------------------------------
    if (t ~ /^### /) {
      while (output_idx > 0 && out_pool[output_idx] == "") {
        output_idx--
      }
      if (output_idx > 0) {
        output_idx++; out_pool[output_idx] = ""
        output_idx++; out_pool[output_idx] = ""
        output_idx++; out_pool[output_idx] = "&nbsp;"
        output_idx++; out_pool[output_idx] = ""
      }
      output_idx++; out_pool[output_idx] = ""
      output_idx++; out_pool[output_idx] = line
      output_idx++; out_pool[output_idx] = ""
      continue
    }
    
    # --------------------------------------------------------------------------
    # H4 HEADER PATTERN
    # --------------------------------------------------------------------------
    if (t ~ /^#### /) {
      while (output_idx > 0 && out_pool[output_idx] == "") {
        output_idx--
      }
      if (output_idx > 0) {
        output_idx++; out_pool[output_idx] = ""
        output_idx++; out_pool[output_idx] = "&nbsp;"
      }
      output_idx++; out_pool[output_idx] = ""
      output_idx++; out_pool[output_idx] = line
      output_idx++; out_pool[output_idx] = ""
      continue
    }
    
    # --------------------------------------------------------------------------
    # H5 & H6 HEADERS
    # --------------------------------------------------------------------------
    if (t ~ /^##### / || t ~ /^###### /) {
      if (output_idx > 0 && out_pool[output_idx] != "") {
        output_idx++; out_pool[output_idx] = ""
      }
      output_idx++; out_pool[output_idx] = line
      continue
    }
    
    # --------------------------------------------------------------------------
    # STANDARD TEXT / CODE BLOCKS
    # --------------------------------------------------------------------------
    if (t == "") {
      if (output_idx > 0 && out_pool[output_idx] != "") {
        output_idx++; out_pool[output_idx] = ""
      }
    } else {
      output_idx++; out_pool[output_idx] = line
    }
  }
  
  # Flush out pool to temp file
  for (i = 1; i <= output_idx; i++) {
    print out_pool[i]
  }
}
' "$INPUT_FILE" > "$TMP_FILE"

# ------------------------------------------------------------------------------
# STEP 2: Safe Overwrite
# ------------------------------------------------------------------------------
cp "$TMP_FILE" "$INPUT_FILE"

echo "================================================================================"
echo "  [ v ] File has been successfully normalized to visual standards."
echo "================================================================================"
echo "[OKK] Normalization workflow finished."
echo "================================================================================"
exit 0
