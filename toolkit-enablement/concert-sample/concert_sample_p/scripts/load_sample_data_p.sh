#!/bin/bash
# Exit on error and for undefined variables.
set -euo pipefail

# ====== Source environment variables ======
ENV_FILE="$(dirname "$0")/../concert_data/sample_data_load_envs_p.variables"
if [ -f "$ENV_FILE" ]; then
    echo "Loading environment variables from $ENV_FILE"
    . "$ENV_FILE"
else
    echo "ERROR: Environment file '$ENV_FILE' not found."
    exit 1
fi

# ====== Configuration ======
# Number of retry attempts and timeout (in seconds) for each API call.
RETRIES=3
CURL_TIMEOUT=30

# Check if required environment variables are set.
if [ -z "${CONCERT_URL:-}" ] || [ -z "${INSTANCE_ID:-}" ] || [ -z "${API_KEY:-}" ]; then
    echo "ERROR: Please ensure CONCERT_URL, INSTANCE_ID, and API_KEY are set in the environment file."
    exit 1
fi

# Directory containing your sample files.
SAMPLE_DIR="$(dirname "$0")/../input_sample_set"

if [ ! -d "$SAMPLE_DIR" ]; then
    echo "ERROR: Directory '$SAMPLE_DIR' does not exist. Please ensure the sample files are placed in '$SAMPLE_DIR'."
    exit 1
fi

# ====== API Endpoints ======
INVENTORY_ENDPOINT="https://${CONCERT_URL}:12443/ingestion/api/v1/power_maintenance/inventory/upload"
RISKS_ENDPOINT="https://${CONCERT_URL}:12443/ingestion/api/v1/power_maintenance/risks/upload"

# ====== Helper function for API calls ======
invoke_api() {
    local description="$1"
    local endpoint="$2"
    local file_path="$3"
    local form_field="$4"   # New parameter for the form field name
    local attempt=1
    local exit_status

    echo "Starting: ${description} using file '${file_path}'"

    while [ $attempt -le $RETRIES ]; do
        echo "Attempt ${attempt}/${RETRIES}..."
        curl --location --insecure --max-time ${CURL_TIMEOUT} "${endpoint}" \
            --header "Authorization: C_API_KEY ${API_KEY}" \
            --header "InstanceId: ${INSTANCE_ID}" \
            --form "${form_field}=@${file_path}" && exit_status=0 || exit_status=$?

        if [ $exit_status -eq 0 ]; then
            echo "Success: ${description}"
            break
        else
            echo "Warning: ${description} failed on attempt ${attempt} with exit status ${exit_status}."
        fi

        attempt=$((attempt + 1))
        sleep 2
    done

    if [ $exit_status -ne 0 ]; then
        echo "ERROR: ${description} failed after ${RETRIES} attempts."
        return 1
    fi
}

# ====== API 1 Invocation ======
SYSTEMS_FILE="${SAMPLE_DIR}/inventory-data.json"
if [ ! -f "$SYSTEMS_FILE" ]; then
    echo "ERROR: File '${SYSTEMS_FILE}' does not exist."
    exit 1
fi

invoke_api "Inventory Upload (inventory-data.json)" "${INVENTORY_ENDPOINT}" "${SYSTEMS_FILE}" "inventory_sample_data_file"

# ====== API 2 Invocation ======
for filename in "viossec-risks-data.json" "firmware-risks-data.json"; do
    FILE_PATH="${SAMPLE_DIR}/${filename}"
    if [ ! -f "$FILE_PATH" ]; then
        echo "Warning: File '${FILE_PATH}' not found; skipping this file."
        continue
    fi
    invoke_api "Risks Upload (${filename})" "${RISKS_ENDPOINT}" "${FILE_PATH}" "risks_sample_data_file"
done

echo "All API invocations are complete."