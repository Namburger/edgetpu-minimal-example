cmake_minimum_required(VERSION 3.11)
project(minimal-edgetpu-example)

set(CMAKE_C_FLAGS "-Wall -pthread")
set(CMAKE_C_FLAGS_DEBUG "-g -O0")
set(CMAKE_C_FLAGS_RELEASE "-O3")
set(CMAKE_CXX_FLAGS "${CMAKE_C_FLAGS} -std=c++17 -lstdc++")
set(CMAKE_CXX_FLAGS_DEBUG ${CMAKE_C_FLAGS_DEBUG})
set(CMAKE_CXX_FLAGS_RELEASE ${CMAKE_C_FLAGS_RELEASE})

# Pick the tensorflow commit that you want to use, 
# make sure that this commit matches what you will be using for libedgetpu.
set(TENSORFLOW_COMMIT f394a768719a55b5c351ed1ecab2ec6f16f99dd4)

# GET CPU Architechture
if(${CMAKE_SYSTEM_PROCESSOR} STREQUAL "x86_64")
    set(EDGE_ARCH "k8")
    set(TF_COMMAND make -j8 BUILD_WITH_NNAPI=false -C ${CMAKE_BINARY_DIR}/tensorflow/src/tf -f tensorflow/lite/tools/make/Makefile lib)
    set(TF_INSTALL_PREFIX "linux_x86_64")
elseif(${CMAKE_SYSTEM_PROCESSOR} STREQUAL "aarch64")
    set(EDGE_ARCH "${CMAKE_SYSTEM_PROCESSOR}")
    set(TF_INSTALL_PREFIX "generic-aarch64_armv8-a")
    set(CROSS_PREFIX "aarch64-linux-gnu-")
    set(TF_COMMAND make -j4 TARGET=generic-aarch64 TARGET_ARCH=armv8-a -C ${CMAKE_BINARY_DIR}/tensorflow/src/tf -f tensorflow/lite/tools/make/Makefile CC=${CROSS_PREFIX}g++ CXX=${CROSS_PREFIX}g++ AR=${CROSS_PREFIX}ar CFLAGS=-fpermissive lib)
elseif(${CMAKE_SYSTEM_PROCESSOR} STREQUAL "armv7l")
    message("We are going to assume that this build is for the rpi")
    set(EDGE_ARCH "${CMAKE_SYSTEM_PROCESSOR}")
    set(TF_INSTALL_PREFIX "rpi_armv7l")
    set(CROSS_PREFIX "arm-linux-gnueabihf-")
    set(TF_COMMAND make -j4 TARGET=rpi TARGET_ARCH=armv7l -C ${CMAKE_BINARY_DIR}/tensorflow/src/tf -f tensorflow/lite/tools/make/Makefile CC=${CROSS_PREFIX}g++ CXX=${CROSS_PREFIX}g++ AR=${CROSS_PREFIX}ar CFLAGS=-fpermissive lib)
else()
	message(FATAL_ERROR "Not implemented to build for: ${CMAKE_SYSTEM_PROCESSOR}")
endif()

message("System ARCH is ${CMAKE_SYSTEM_PROCESSOR} ${EDGE_ARCH}")

include(ExternalProject)

ExternalProject_Add(absl_src
    GIT_REPOSITORY https://github.com/abseil/abseil-cpp
    GIT_PROGRESS 1
    GIT_SHALLOW 1
    PREFIX "absl"
    PATCH_COMMAND sed -i /ABSL_RANDOM_HWAES_X64_FLAGS/d
    ${CMAKE_BINARY_DIR}/absl/src/absl_src/absl/copts/AbseilConfigureCopts.cmake
    && sed -i /random/d ${CMAKE_BINARY_DIR}/absl/src/absl_src/absl/CMakeLists.txt
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/absl_install -DCMAKE_INSTALL_LIBDIR=lib
    BUILD_BYPRODUCTS libabsl_synchronization.a libabsl_symbolize.a
)
set(ABSL_LIBS absl_synchronization absl_stacktrace absl_symbolize absl_demangle_internal absl_debugging_internal absl_dynamic_annotations absl_time absl_time_zone absl_graphcycles_internal absl_failure_signal_handler absl_malloc_internal absl_base absl_spinlock_wait)

ExternalProject_Add(glog_src
    GIT_REPOSITORY https://github.com/google/glog
    GIT_PROGRESS 1
    GIT_SHALLOW 1
    CMAKE_ARGS -DWITH_GFLAGS=OFF
    -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/glog_install
    -DCMAKE_INSTALL_LIBDIR=lib
    PREFIX "glog_src"
    BUILD_BYPRODUCTS  libglog.a
)
set(LIBGLOG ${CMAKE_BINARY_DIR}/glog_install/lib/libglog.a)

ExternalProject_Add(tf
    GIT_REPOSITORY https://github.com/tensorflow/tensorflow
    GIT_TAG ${TENSORFLOW_COMMIT}
    PREFIX "tensorflow"
    CONFIGURE_COMMAND ./tensorflow/lite/tools/make/download_dependencies.sh
    BUILD_IN_SOURCE 1
    BUILD_COMMAND ${TF_COMMAND}
    BUILD_BYPRODUCTS libtensorflow-lite.a ${CMAKE_BINARY_DIR}/tensorflow/src/tf/tensorflow/lite/tools/make/downloads/fft2d/fftsg.c
    BUILD_BYPRODUCTS libtensorflow-lite.a ${CMAKE_BINARY_DIR}/tensorflow/src/tf/tensorflow/lite/tools/optimize/sparsity/format_converter.cc
    INSTALL_COMMAND cp -f ${CMAKE_BINARY_DIR}/tensorflow/src/tf/tensorflow/lite/tools/make/gen/${TF_INSTALL_PREFIX}/lib/libtensorflow-lite.a ${CMAKE_BINARY_DIR}/
)

# libedgetpu has armv7l as armv7a.
if(${EDGE_ARCH} STREQUAL "armv7l")
    set(EDGE_ARCH "armv7a")
endif()

configure_file(${CMAKE_SOURCE_DIR}/libedgetpu/out/direct/${EDGE_ARCH}/libedgetpu.so.1.0  ${CMAKE_BINARY_DIR} COPYONLY)
configure_file(${CMAKE_SOURCE_DIR}/libedgetpu/out/direct/${EDGE_ARCH}/libedgetpu.so.1  ${CMAKE_BINARY_DIR} COPYONLY)

set(EDGETPU_LIB "${CMAKE_BINARY_DIR}/libedgetpu.so.1.0")
set(TF_LITE_LIB "${CMAKE_BINARY_DIR}/libtensorflow-lite.a")
include_directories(${CMAKE_SOURCE_DIR}/)
include_directories(${CMAKE_SOURCE_DIR}/src/)
include_directories(${CMAKE_SOURCE_DIR}/include/)
include_directories(${CMAKE_SOURCE_DIR}/libedgetpu/tflite/public/)
include_directories(${CMAKE_BINARY_DIR}/tensorflow/src/tf/)
include_directories(${CMAKE_BINARY_DIR}/tensorflow/src/tf/tensorflow/lite/tools/make/downloads/absl/)
include_directories(${CMAKE_BINARY_DIR}/tensorflow/src/tf/tensorflow/lite/tools/make/downloads/flatbuffers/include/)
include_directories(${CMAKE_BINARY_DIR}/glog_install/include)
link_directories(${CMAKE_BINARY_DIR})
link_directories(${CMAKE_BINARY_DIR}/absl_install/lib)
link_directories(${CMAKE_BINARY_DIR}/glog_install/lib)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/out/${EDGE_ARCH})

add_library(model_utils
  src/model_utils.cc
  include/model_utils.h)
target_link_libraries(model_utils ${TF_LITE_LIB})
add_dependencies(model_utils tf)

add_executable(minimal
  src/minimal.cc
  ${CMAKE_BINARY_DIR}/tensorflow/src/tf/tensorflow/lite/tools/make/downloads/fft2d/fftsg.c
  ${CMAKE_BINARY_DIR}/tensorflow/src/tf/tensorflow/lite/tools/optimize/sparsity/format_converter.cc
)
target_link_libraries(minimal model_utils ${TF_LITE_LIB} ${EDGETPU_LIB})
add_dependencies(minimal model_utils tf)
