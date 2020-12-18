#!/usr/bin/env bash

module load python/3.8.6 cmake/gcc-8.2.0/3.16.2 openmpi/mlnx/gcc/64/2.0.2a1 ffmpeg/gcc-4.8.5/3.2.4 zlib/gcc-8.2.0/1.2.11 atlas/3.10.3 blas/gcc/64/3.7.0 blacs/openmpi/open64/64/1.1patch03 blast/2.5.0 cuda/gcc-4.8.5/8.0.44 lapack/gcc/64/3.7.0 openblas/dynamic/0.2.18 libjpeg/gcc-8.2.0/9c

CAFFE_USE_MPI=${1:-OFF}
CAFFE_MPI_PREFIX=${MPI_PREFIX:-""}


# install common dependencies: OpenCV
# adpated from OpenCV.sh
version="3.4.2"

echo "Building OpenCV" $version
[[ -d 3rd-party ]] || mkdir 3rd-party/
cd 3rd-party/

if [ ! -d "opencv-$version" ]; then

    echo "Downloading OpenCV" $version
    wget -O OpenCV-$version.zip https://github.com/Itseez/opencv/archive/$version.zip

    echo "Extracting OpenCV" $version
    unzip OpenCV-$version.zip
fi

echo "Building OpenCV" $version
cd opencv-$version
[[ -d build ]] || mkdir build
cd build
cmake -D CMAKE_BUILD_TYPE=RELEASE -D WITH_TBB=ON  -D WITH_V4L=ON ..
if make -j32 ; then
    cp lib/cv2.so ../../../
    echo "OpenCV" $version "built."
else
    echo "Failed to build OpenCV. Please check the logs above."
    exit 1
fi

# build dense_flow
cd ../../../

echo "Building Dense Flow"
cd lib/dense_flow
[[ -d build ]] || mkdir build
cd build
OpenCV_DIR=../../../3rd-party/opencv-$version/build/ cmake .. -DCUDA_USE_STATIC_CUDA_RUNTIME=OFF
if make -j ; then
    echo "Dense Flow built."
else
    echo "Failed to build Dense Flow. Please check the logs above."
    exit 1
fi

# build caffe
echo "Building Caffe, MPI status: ${CAFFE_USE_MPI}"
cd ../../caffe-action
[[ -d build ]] || mkdir build
cd build
if [ "$CAFFE_USE_MPI" == "MPI_ON" ]; then
OpenCV_DIR=../../../3rd-party/opencv-$version/build/ cmake .. -DUSE_MPI=ON -DMPI_CXX_COMPILER="${CAFFE_MPI_PREFIX}/bin/mpicxx" -DCUDA_USE_STATIC_CUDA_RUNTIME=OFF
else
OpenCV_DIR=../../../3rd-party/opencv-$version/build/ cmake .. -DCUDA_USE_STATIC_CUDA_RUNTIME=OFF
fi
if make -j32 install ; then
    echo "Caffe Built."
    echo "All tools built. Happy experimenting!"
    cd ../../../
else
    echo "Failed to build Caffe. Please check the logs above."
    exit 1
fi
