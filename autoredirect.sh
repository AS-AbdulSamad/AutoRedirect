#!/bin/bash

# Function to display usage
usage() {
    echo "Usage: $0 -u <input_file> -o <output_file>"
    exit 1
}

# Parse command-line arguments
while getopts "u:o:" opt; do
    case "$opt" in
        u) input_file="$OPTARG" ;;
        o) output_file="$OPTARG" ;;
        *) usage ;;
    esac
done

# Check if both input and output files are provided
if [[ -z "$input_file" || -z "$output_file" ]]; then
    usage
fi

# Check if input file exists
if [[ ! -f "$input_file" ]]; then
    echo "Input file not found: $input_file"
    exit 1
fi

# Clear the output file
> "$output_file"

# Process each URL in the input file
while read -r url; do
    # Skip empty lines
    [[ -z "$url" ]] && continue

    # Extract the base domain and path/query part
    base_url=$(echo "$url" | awk -F'/' '{print $1 "//" $3}')
    path_query_part=${url#"$base_url"}

    # Handle URLs with or without query parameters
    if [[ "$path_query_part" == "$url" ]]; then
        # No query parameters, process paths only
        echo "${url%/}/FUZZ" >> "$output_file" # Add FUZZ to the end
        echo "${base_url}/FUZZ" >> "$output_file" # Add FUZZ at the base level
    else
        # Separate the path and query string
        base_path="${path_query_part%%\?*}"
        query_string="${path_query_part#*\?}"

        # Add FUZZ at the end of the base path
        echo "${base_url}${base_path}/FUZZ" >> "$output_file"
        echo "${base_url}/FUZZ" >> "$output_file"

        # If query parameters exist, process them
        if [[ "$query_string" != "$path_query_part" ]]; then
            IFS='&' read -ra params <<< "$query_string"
            for ((i = 0; i < ${#params[@]}; i++)); do
                modified_params=("${params[@]}")
                key_value="${modified_params[$i]}"
                key="${key_value%%=*}"

                # Replace the value of each parameter with FUZZ
                modified_params[$i]="${key}=FUZZ"
                modified_query=$(IFS='&'; echo "${modified_params[*]}")
                echo "${base_url}${base_path}?${modified_query}" >> "$output_file"
            done
        fi
    fi
done < "$input_file"

echo "Processing complete. Results saved in $output_file."
