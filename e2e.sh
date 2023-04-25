#!/bin/bash

if ! [ -x "$(command -v newman)" ]; then
  echo "[ERROR] Could not find command 'newman'. Please install with \"npm install -g newman\" to proceed."
  exit 1
fi

function usage {
    echo "Run end-to-end tests for Metadata Lake via Postman."
    echo "usage: ./e2e.sh -h <url> -d <dgc url> -u <username> -p <password> -s <stage> [-g <global-variable>=<value>]"
    echo "  -h    instance url"
    echo "  -d    dgc url"
    echo "  -u    username for DGC login (read/write)"
    echo "  -p    password for DGC login (read/write)"
    echo "  -g    additional global variable(s)"
    echo "  -s    test stage"
    echo "            provider       run basic 'providers' tests, including mappings"
    echo "            asset          run basic 'assets' tests, including search"
    echo "                           please provide -g asset_id=<existing asset id>"
    echo "            file-ingest    run file ingestion"
    echo "                           please provide -g aws_id=<aws id> -g aws_secret=<aws key>"
    echo "            push-ingest    run asset ingestion and relation ingestion"
    echo "            edge-ingest    run edge ingestion using a specified edge site"
    echo "                           please provide -g db_conn_id=<database connection id> -g must_cancel=<true if job must be cancelled to complete>"
    echo "            promote        run promotion for a provider"
    echo "            all            run all above stages consecutively"
    exit 1
}

[ -z $1 ] && { usage; }

# PARSE OPTIONS

while getopts "h:u:p:s:d:g:" option; do
    case $option in
         h)
           url=${OPTARG};;
         d)
           dgc_url=${OPTARG};;
         u)
           username=${OPTARG};;
         p)
           password=${OPTARG};;
         s)
           stage=${OPTARG};;
         g)
           globals+=(${OPTARG});;
         \?)
           echo "[ERROR] Unrecognized option"
           exit;;
    esac
done

# CHECK FOR REQUIRED FIELDS

if [ -z $url ]; then
  echo "[ERROR] Metadata Lake url was not specified with '-h'. Please specify url to proceed."
  exit 1
fi

if [ -z $dgc_url ]; then
  echo "[ERROR] DGC url was not specified with '-d'. Please specify dgc url to proceed."
  exit 1
fi

if [ -z $username ]; then
  echo "[ERROR] Username was not specified with '-u'. Please specify username to proceed."
  exit 1
fi

if [ -z $password ]; then
  echo "[ERROR] Password was not specified with '-p'. Please specify password to proceed."
  exit 1
fi

if [ -z $stage ]; then
  echo "[ERROR] Stage was not specified with '-s'. Please specify stage to proceed."
  exit 1
fi

# COLLECT ALL INPUT GLOBAL VARIABLES

postman_globals+=("--global-var rw_username=${username}")
postman_globals+=("--global-var rw_password=${password}")
postman_globals+=("--global-var api_url=${url}")
postman_globals+=("--global-var dgc_url=${dgc_url}")
for key_val in "${globals[@]}"; do
  postman_globals+=("--global-var $key_val")
done

# TODO: RDD - add more checks for mappings, types
function provider {
  echo "[INFO] Starting provider tests."
  newman run collections/provider.metalake.postman_collection.json ${postman_globals[@]} \
  --verbose --reporters cli,json --reporter-json-export reports/provider.json || exit 2
  echo "[INFO] Completed provider tests."
}

# TODO: RDD - create asset automatically instead of requiring input id
# TODO: RDD - add more checks for attributes
function asset {
  echo "[INFO] Starting asset tests."
  newman run collections/asset.metalake.postman_collection.json ${postman_globals[@]} \
  --verbose --reporters cli,json --reporter-json-export reports/asset.json || exit 3
  echo "[INFO] Completed asset tests."
}

# TODO: RDD - parameterize test bucket info (?)
# TODO: RDD - add more validation after ingestion completes
function file_ingest {
  echo "[INFO] Starting file ingestion tests."
  newman run collections/file-ingestion.metalake.postman_collection.json ${postman_globals[@]} \
  --verbose --reporters cli,json --reporter-json-export reports/file-ingest.json || exit 4
  echo "[INFO] Completed file ingestion tests."
}

# TODO: RDD - add push test collection
function push_ingest {
  echo "[WARN] 'push-ingest' test stage is not yet supported." || exit 5
}

# TODO: RDD - refine page body and verify results
function edge_ingest {
  correlation_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
  echo "[INFO] Starting edge ingestion tests with correlation id '${correlation_id}'."
  newman run collections/edge-ingestion.metalake.postman_collection.json --global-var "edge_ingest_corr_id=${correlation_id}" ${postman_globals[@]} \
  --verbose --reporters cli,json --reporter-json-export reports/edge-ingest.json || exit 6
  echo "[INFO] Completed edge ingestion tests."
}

# TODO: RDD - add promote test collection
function promote {
  echo "[WARN] 'promote' test stage is not yet supported." || exit 7
}

# RUN TESTS

if [ ${stage} == "provider" ]; then
  provider
elif [ ${stage} == "asset" ]; then
  asset
elif [ ${stage} == "file-ingest" ]; then
  file_ingest
elif [ ${stage} == "push-ingest" ]; then
  push_ingest
elif [ ${stage} == "edge-ingest" ]; then
  edge_ingest
elif [ ${stage} == "promote" ]; then
  promote
elif [ ${stage} == "all" ]; then
  provider
  asset
  file_ingest
  push_ingest
  edge_ingest
  promote
fi
