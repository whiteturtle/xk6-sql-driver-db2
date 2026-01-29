#!/bin/bash
# Wrapper script to run k6 with the DB2 CLI driver library path set

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set the DB2 CLI driver library path
export IBM_DB_HOME="${SCRIPT_DIR}/../../clidriver"
export DYLD_LIBRARY_PATH="${SCRIPT_DIR}/../../clidriver/lib"

# Run k6 with all arguments passed to this script
"${SCRIPT_DIR}/k6" "$@"
