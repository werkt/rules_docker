#!/bin/bash
set -ex

function guess_runfiles() {
    if [ -d ${BASH_SOURCE[0]}.runfiles ]; then
        # Runfiles are adjacent to the current script.
        echo "$( cd ${BASH_SOURCE[0]}.runfiles && pwd )"
    else
        # The current script is within some other script's runfiles.
        mydir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
        echo $mydir | sed -e 's|\(.*\.runfiles\)/.*|\1|'
    fi
}

RUNFILES="${PYTHON_RUNFILES:-$(guess_runfiles)}"

# Resolve the docker tool path
DOCKER="%{docker_tool_path}"

if [[ -z "$DOCKER" ]]; then
    echo >&2 "error: docker not found; do you need to manually configure the docker toolchain?"
    exit 1
fi

# Load the image and remember its name
image_id=$(%{image_id_extractor_path} %{image_tar})
$DOCKER load -i %{image_tar}

# Run the builder image.
cid=$($DOCKER run -w="/" -d --privileged $image_id sh -c $'%{download_commands}')
$DOCKER attach $cid
$DOCKER cp $cid:%{installables}_packages.tar %{output}
$DOCKER cp $cid:%{installables}_metadata.csv %{output_metadata}
# Cleanup
$DOCKER rm $cid
