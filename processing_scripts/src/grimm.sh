#!/bin/bash


# Column names: 
  # J :    0.25     0.28     0.30     0.35     0.40     0.45     0.50     0.58
  # J ;    0.65     0.70     0.80     1.00     1.30     1.60     2.00     2.50




if [[ x"$1" == x || x"$2" == x ]]; then exit 1; fi

mitrap_station=$1
BUCKET=$2

DIRECTORY="/mnt/incoming/$mitrap_station/sambashare/GrimmOPC107"


for file in "$DIRECTORY"/*.txt "$DIRECTORY"/*.TXT; do

  while IFS= read -r line; do

    # Match the line for the patterns of cC and P
    if [[ "$line" =~ (P[[:space:]]) || "$line" =~ (c[0-9]+) || "$line" =~ (C[0-9]+) ]]; then

      # Extract the match and remove everything before it
      cleaned=$(echo "$line" | sed -E 's/.*\b(P[[:space:]]|[cC][0-9]+)//')

      # Prepend the match back (since we removed it in sed)
      if [[ "$line" =~ (P[[:space:]]) ]]; then
        echo "P ${cleaned}"
      elif [[ "$line" =~ (c[0-9]+) ]]; then
        match="${BASH_REMATCH[1]}"
        echo "${match}${cleaned}"
      elif [[ "$line" =~ (C[0-9]+) ]]; then
        match="${BASH_REMATCH[1]}"
        echo "${match}${cleaned}"
      fi
    fi
  done < "$file"
done

