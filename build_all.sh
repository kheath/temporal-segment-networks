#!/usr/bin/env bash

CAFFE_USE_MPI=${1:-OFF}
CAFFE_MPI_PREFIX=${MPI_PREFIX:-""}


# # install common dependencies: OpenCV
# # adpated from OpenCV.sh
# version="3.4.2"

# echo "Building OpenCV" $version
# [[ -d 3rd-party ]] || mkdir 3rd-party/
# cd 3rd-party/

# if [ ! -d "opencv-$version" ]; then

#     echo "Downloading OpenCV" $version
#     wget -O OpenCV-$version.zip https://github.com/Itseez/opencv/archive/$version.zip

#     echo "Extracting OpenCV" $version
#     unzip OpenCV-$version.zip
# fi

# echo "Building OpenCV" $version
# cd opencv-$version
# [[ -d build ]] || mkdir build
# cd build
# cmake -D CMAKE_BUILD_TYPE=RELEASE -D WITH_TBB=ON  -D WITH_V4L=ON ..
# if make -j32 ; then
#     cp lib/cv2.so ../../../
#     echo "OpenCV" $version "built."
# else
#     echo "Failed to build OpenCV. Please check the logs above."
#     exit 1
# fi

# build dense_flow


echo "Building Dense Flow"
cd lib/dense_flow
[[ -d build ]] || mkdir build
cd build
cmake .. -DCUDA_USE_STATIC_CUDA_RUNTIME=OFF
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
