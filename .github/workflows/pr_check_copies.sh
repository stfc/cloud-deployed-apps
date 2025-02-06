#!/bin/bash
# Script to check if the changed files to promote are a direct copy of earlier environment

# Function to compare the files, file1 is our original file passed to the script followed by two possible further files
compare_files() {
    file1=$1
    file2=$2
    
    # Check if the second file exists
    if [ -f "$file2" ]; then
        if cmp -s "$file1" "$file2"; then
            return 0  # Files are identical
        else
            echo "Difference found between $file1 and $file2"
            return 1  # Files are different
        fi
    else
        echo "File $file2 does not exist"
        return 1  # Second file doesn't exist
    fi
}

# Check the file path to determine if it's from staging or prod folder
path=$1
curr_env=$2
comp_env=$3

# Compare files and exit with its return code
compare_files "$1" "${path/$curr_env/"$comp_env"}"
exit $?  # Exit with the return code from compare_files