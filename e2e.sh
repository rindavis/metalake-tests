#!/bin/bash

if ! [ -x "$(command -v newman)" ]; then
	echo "[ERROR] Could not find command 'newman'. Please install with \"npm install -g newman\" to proceed."
	exit 1
fi

function usage {
	echo "Run end-to-end tests for Metadata Lake via Postman."
    echo "usage: ./e2e.sh -h <url> -d <dgc url> -u <username> -p <password> -s <stage> [-g <global-variable>=<value>]"
    echo "  -h      instance url"
	echo "  -d      dgc url"
    echo "  -u      username for DGC login (read/write)"
    echo "  -p      password for DGC login (read/write)"
	echo "  -g 		additional global variable(s)"
    echo "  -s      test stage"
    echo "            provider - run basic 'providers' tests, including mappings"
	echo "            asset - run basic 'assets' tests, including search"
	echo "            file-ingest - run file ingestion"
	echo "            push-ingest - run asset ingestion and relation ingestion"
	echo "            edge-ingest - run edge ingestion using a specified edge site"
	echo "            all - run all above stages consecutively"
    exit 1
}

[ -z $1 ] && { usage; }

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

postman_globals+=("--global-var rw_username=${username}")
postman_globals+=("--global-var rw_password=${password}")
postman_globals+=("--global-var api_url=${url}")
postman_globals+=("--global-var dgc_url=${dgc_url}")
for key_val in "${globals[@]}"; do
	postman_globals+=("--global-var $key_val")
done

function provider {
	echo "[WARN] 'provider' test stage is not yet supported." || exit 2
}

function asset {
	echo "[WARN] 'asset' test stage is not yet supported." || exit 3

}

# TODO: RDD - parameterize test bucket info (?)
# TODO: RDD - add more validation after ingestion completes
function file_ingest {
	echo "[INFO] Starting file ingestion tests."
	newman run collections/file-ingestion.metalake.postman_collection.json ${postman_globals[@]} \
		--verbose --reporters cli,json --reporter-json-export reports/file-ingest.json || exit 4
	echo "[INFO] Completed file ingestion tests."
}

function push_ingest {
	echo "[WARN] 'push-ingest' test stage is not yet supported." || exit 5
}

function edge_ingest {
	correlation_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
	echo "[WARN] 'edge-ingest' test stage is not yet supported." || exit 6
}

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
elif [ ${stage} == "all" ]; then
	provider
	asset
	file_ingest
	push_ingest
	edge_ingest
fi
