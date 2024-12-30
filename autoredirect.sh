#!/bin/bash

# Function to process each URL
process_url() {
  local url=$1
  local output_file=$2

  # Parse the base URL (protocol + domain)
  local base_url=$(echo $url | sed -E 's|^(https?://[^/?]+).*|\1|')
  local path=$(echo $url | sed -E 's|https?://[^/]+(/[^?]+).*|\1|')
  local query=$(echo $url | sed -E 's|https?://[^?]+\?(.*)|\1|')

  # Check if the URL has query parameters
  if [[ -n "$query" ]]; then
    # If query exists, split the parameters
    IFS='&' read -r -a params <<< "$query"
    
    # Iterate over each parameter
    for (( i=0; i<${#params[@]}; i++ )); do
      local modified_query=""
      
      # Rebuild the query string, replacing only the current parameter
      for (( j=0; j<${#params[@]}; j++ )); do
        if [[ $i -eq $j ]]; then
          # Replace the current parameter value with FUZZ
          local param_name=$(echo ${params[$j]} | cut -d '=' -f 1)
          modified_query+="${param_name}=FUZZ"
        else
          # Keep the other parameters as is
          modified_query+="${params[$j]}"
        fi
        
        # Add '&' separator except for the last parameter
        if [[ $j -lt $((${#params[@]} - 1)) ]]; then
          modified_query+="&"
        fi
      done

      # Construct the modified URL
      local modified_url="${base_url}${path}?${modified_query}"
      
      # Output the modified URL to the specified output file
      echo "$modified_url" >> "$output_file"
    done
  else
    # If no query parameters, append FUZZ to the path
    local modified_url="${base_url}${path}/FUZZ"
    echo "$modified_url" >> "$output_file"
  fi
}

# Check if the user provided both input and output files
if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <url_file> <output_file>"
  exit 1
fi

url_file=$1
output_file=$2

# Check if the input file exists
if [[ ! -f "$url_file" ]]; then
  echo "File not found: $url_file"
  exit 1
fi

# Create or clear the output file
> "$output_file"

# Read the file line by line and process each URL
while IFS= read -r url; do
  # Process each URL and save the result to the output file
  process_url "$url" "$output_file"
done < "$url_file"

echo "Results saved to $output_file"
