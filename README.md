# edgetpu-minimal-example

This repo demonstrate how to build [google-coral/edgetpu minimal example](https://github.com/google-coral/edgetpu/blob/master/src/cpp/examples/minimal.cc)natively. The code was modified slightly to supports non CPU model and take in a label file. Since bazel doesn't have great supports for arm platform, we'll use cmake (the CMakeLists.txt is based on [this](https://github.com/google-coral/edgetpu/pull/88/commits/a5fdb413eb7492abfbec3c0dbc8a5543e7f84874)). Platform tested on are x86_64, armv7l, and aarch64.

## Build Instructions
```
$ git clone https://github.com/Namburger/edgetpu-minimal-example.git && cd edgetpu-minimal-example
$ ./scripts/install_cmake.sh // install cmake if needed
$ ./scripts/make2gbswap.sh //  [Optional] increase swap to avoid OOM killer
$ mkdir build && cd build
$ cmake ..
$ make
```
This process may takes ~ 30 -> 45 mins on the Coral Dev Board and the RPI since it'll build the `libtensorflow-lite.a`, `libglog.a`, and `libabsl*.a`.

## Run
** With edgetpu:**
`$ ../out/aarch64/minimal ../test_data/mobilenet_v1_1.0_224_quant_edgetpu.tflite ../test_data/resized_cat.bmp ../test_data/imagenet_labels.txt`
** With out edgetpu:**
`$ ../out/aarch64/minimal ../test_data/mobilenet_v1_1.0_224_quant.tflite ../test_data/resized_cat.bmp ../test_data/imagenet_labels.txt`
