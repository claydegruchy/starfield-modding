#!/bin/bash

# Initialize variables with default values
config_directory=""
template_file=""
output_directory=""
base_config_file=""
cli_tool="jinja2"

# Function to create a new directory for each permutation
create_output_directory() {
    mkdir -p "$1"
}

# Function to run the CLI tool and save the output
run_cli_tool_and_save_output() {
    $cli_tool "$template_file" "$config_file" > "$output_file"
}

# Function to clean up the merged config file
cleanup_merged_config() {
    if [ -e "$merged_config_file" ]; then
        rm "$merged_config_file"
    fi
}

# Function to merge YAML files using yq
merge_yaml_files() {
    echo "Merging configuration files: $base_config_file and $config_file"
    yq '. *= load("'"$config_file"'")' "$base_config_file" > "$merged_config_file"
}

# Parse command-line arguments
while getopts "d:t:o:b:" opt; do
    case "$opt" in
        d) config_directory="$OPTARG";;
        t) template_file="$OPTARG";;
        o) output_directory="$OPTARG";;
        b) base_config_file="$OPTARG";;
        \?) echo "Usage: $0 -d <config_directory> -t <template_file> [-o <output_directory>] [-b <base_config_file>]"; exit 1;;
    esac
done

# Check if both directory and template file are provided
if [ -z "$config_directory" ] || [ -z "$template_file" ]; then
    echo "Usage: $0 -d <config_directory> -t <template_file> [-o <output_directory>] [-b <base_config_file>]"
    exit 1
fi

# Use the current directory as the output directory if not provided
if [ -z "$output_directory" ]; then
    output_directory="."
fi

# Iterate over each config file in the directory
for config_file in "$config_directory"/*.yaml; do
    # Check if the file exists
    if [ -e "$config_file" ]; then
        # Extract the base name of the configuration file (excluding .yaml)
        config_name=$(basename "$config_file" .yaml)

        # Merge the current config with the base config using yq
        if [ -n "$base_config_file" ]; then
            merged_config_file="/tmp/merged_config.yaml"
            merge_yaml_files
            config_file="$merged_config_file"
        fi

        echo "Creating directory for: $config_name"
        # Create a new directory for each permutation
        permutation_output_dir="$output_directory/$config_name"
        create_output_directory "$permutation_output_dir"

        echo "Running CLI tool for: $config_name"
        # Run the CLI tool and save the output
        output_file="$permutation_output_dir/$(basename "$template_file")"
        run_cli_tool_and_save_output

        # Clean up the merged config file
        cleanup_merged_config

        echo "Finished processing: $config_name"
    fi
done
