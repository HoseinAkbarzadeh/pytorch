#!/bin/bash
set -ex
export PATH="/c/Program Files/CMake/bin;/c/Program Files/7-Zip;/c/ProgramData/chocolatey/bin;/c/Program Files/Git/cmd;/c/Program Files/Amazon/AWSCLI;/c/Program Files/Amazon/AWSCLI/bin;$PATH"

# Install Miniconda3
export INSTALLER_DIR="$SCRIPT_HELPERS_DIR"/installation-helpers

LINUX_TMP_DIR_WIN=$(cygpath -u "${TMP_DIR_WIN}")

# Miniconda has been installed as part of the Windows AMI with all the dependencies.
# We just need to activate it here
# shellcheck disable=SC1091
source "$INSTALLER_DIR"/activate_miniconda3.sh

# PyTorch is now installed using the standard wheel on Windows into the conda environment.
# However, the test scripts are still frequently referring to the workspace temp directory
# build\torch. Rather than changing all these references, making a copy of torch folder
# from conda to the current workspace is easier. The workspace will be cleaned up after
# the job anyway
cp -r "$CONDA_PARENT_DIR/Miniconda3/Lib/site-packages/torch" "$LINUX_TMP_DIR_WIN/build/torch/"

pushd .
if [[ -z "$VC_VERSION" ]]; then
    "/c/Program Files (x86)/Microsoft Visual Studio/$VC_YEAR/$VC_PRODUCT/VC/Auxiliary/Build/vcvarsall.bat" x64
else
    "/c/Program Files (x86)/Microsoft Visual Studio/$VC_YEAR/$VC_PRODUCT/VC/Auxiliary/Build/vcvarsall.bat" x64 "-vcvars_ver=$VC_VERSION"
fi
popd

export DISTUTILS_USE_SDK=1


if [[ "${USE_CUDA}" == "1" ]]; then
    export CUDA_PATH="/c/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v$CUDA_VERSION"

    # version transformer, for example 10.1 to 10_1.
    export VERSION_SUFFIX=${CUDA_VERSION// /.}

    declare "CUDA_PATH_V$VERSION_SUFFIX=$CUDA_PATH"

    export CUDNN_LIB_DIR=$CUDA_PATH/lib/x64
    export CUDA_TOOLKIT_ROOT_DIR=$CUDA_PATH
    export CUDNN_ROOT_DIR=$CUDA_PATH
    export NVTOOLSEXT_PATH="/c/Program Files/NVIDIA Corporation/NvToolsExt"
    export PATH="$CUDA_PATH/bin;$CUDA_PATH/libnvvp;$PATH"
    export NUMBAPRO_CUDALIB=$CUDA_PATH/bin
    export NUMBAPRO_LIBDEVICE=$CUDA_PATH/nvvm/libdevice
    export NUMBAPRO_NVVM=$CUDA_PATH/nvvm/bin/nvvm64_32_0.dll

fi

export PYTHONPATH="$LINUX_TMP_DIR_WIN/build;$PYTHONPATH"
