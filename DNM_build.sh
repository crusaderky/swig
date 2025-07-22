#!/bin/bash
set -o errexit
set -o pipefail

git clean -fdx
. ~/miniforge3/bin/activate
mamba create -y -n swig-main python-freethreading=3.13 gcc_linux-64 gxx_linux-64 pcre2
. ~/miniforge3/bin/activate swig-main
./autogen.sh
./configure --prefix=$CONDA_PREFIX
make
make install
make check-python-version
export SWIG_FEATURES=-nogil
make check-python-examples
