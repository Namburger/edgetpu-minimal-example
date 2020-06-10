# edgetpu-minimal-example
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![made-with-coral](https://img.shields.io/badge/Made%20with-Coral-orange)](https://coral.ai/)
[![made-with-c++](https://img.shields.io/badge/Made%20with-C%2B%2B-red)](https://www.cplusplus.com/)
[![made-with-tflite](https://img.shields.io/badge/Made%20with-Tensorflow--Lite-orange)](https://www.tensorflow.org/lite/)
[![made-with-cmake](https://img.shields.io/badge/Made%20with-cmake-Black)](https://cmake.org/)
[![ai-with-ai](https://img.shields.io/badge/AI%20with-AI-brightgreen)](https://en.wikipedia.org/wiki/Artificial_intelligence)

This repo demonstrate how to build [google-coral/edgetpu minimal example](https://github.com/google-coral/edgetpu/blob/master/src/cpp/examples/minimal.cc) natively. The code was modified slightly to supports CPU models and take in a label file. Since bazel doesn't have great supports for arm platform, we'll use cmake (the CMakeLists.txt is based on [this repo](https://github.com/google-coral/edgetpu/pull/88/commits/a5fdb413eb7492abfbec3c0dbc8a5543e7f84874)). Platform tested on are x86_64, armv7l, and aarch64.

## Build Instructions
Note: you are reading this on the experimental branch that allows you to pick any tensorflow version you want, 
if you are not feeling advengerous, switch to master :)

First clone this repo and checkout this branch:
```
$ git clone https://github.com/Namburger/edgetpu-minimal-example.git && cd edgetpu-minimal-example
$ git checkout custom-tensorflow-build
```

Second clone libedgetpu (please do this from the root dir of this repo).
```
$ git clone https://github.com/google-coral/libedgetpu
```
Open `libedgetpu/WORKSPACE`, change `TENSORFLOW_COMMIT` and `TENSORFLOW_SHA256` with the commit of tensorflow you want to use. Then build `libedgetpu`:
```
$ make (note that libedgepu build will requires bazel at this time)
```

Now open CMakeLists.txt and then change the `TENSORFLOW_COMMIT` to match with the commit you chose in libedgepu/WORKSPACE.

```
$ ./scripts/install_cmake.sh // install cmake if needed
$ ./scripts/make2gbswap.sh //  [Optional] increase swap to avoid OOM killer
$ mkdir build && cd build
$ cmake ..
$ make
```
This process may takes ~ 30 -> 45 mins on the Coral Dev Board and the RPI since it'll build the `libtensorflow-lite.a`, `libglog.a`, and `libabsl*.a`.

## Run

With edgetpu:

`$ ../out/aarch64/minimal ../test_data/mobilenet_v1_1.0_224_quant_edgetpu.tflite ../test_data/resized_cat.bmp ../test_data/imagenet_labels.txt`

Without edgetpu:

`$ ../out/aarch64/minimal ../test_data/mobilenet_v1_1.0_224_quant.tflite ../test_data/resized_cat.bmp ../test_data/imagenet_labels.txt`
