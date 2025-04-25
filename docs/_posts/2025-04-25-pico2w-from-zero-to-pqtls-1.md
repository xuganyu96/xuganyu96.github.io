---
layout: post
title:  "From zero to embedded post-quantum TLS: part 1"
date: 2025-04-25 14:35:27 -0400
categories: cryptography
---

Since the beginning of this month I have been tinkering with the Raspberry Pi Pico 2 W. My goal is make it into a post-quantum TLS client, and perhaps even a TLS server. Here are a few constraints that I plan to work within:

1. use the [C SDK](https://github.com/raspberrypi/pico-sdk/tree/master), no RTOS
1. use [WolfSSL](https://github.com/wolfSSL/wolfssl) for cryptography and TLS
1. stick with Neovim as my IDE

# Toolchain and dependencies
> If the Neoivm constraint is not a concern, then the [official Pico plugin on VSCode](https://marketplace.visualstudio.com/items?itemName=raspberry-pi.raspberry-pi-pico) is far more convenient.

The first set of pre-requiresites include a cross compiler `arm-none-eabi-gcc` and the build tool `cmake`.

```bash
brew install arm-none-eabi-gcc cmake
```

Verify the installation with the commands `arm-none-eabi-gcc -v` and `cmake --version`

```
gcc version 8.5.0 (Homebrew ARM GCC 8.5.0_2)
cmake version 4.0.0
```

Next we need to set up the [Pico C/C++ SDK](https://github.com/raspberrypi/pico-sdk/tree/master). Begin by cloning the repository. Later we will need to reference the source code in this repository, using the environment variable `PICO_SDK_PATH`, so now is a good time to export it and put it into the shell profile.

```bash
# --recurse-submodules clones cyw43, lwip, and tinyusb, which we will need
git clone https://github.com/raspberrypi/pico-sdk.git --recurse-submodules
cd pico-sdk
echo "export PICO_SDK_PATH=$(pwd)" >> ~/.zshrc
source ~/.zshrc
```

# Project setup
Because the C/C++ SDK requires using CMake to set up the build system, our project has to use CMake as well. The core of a CMake project is the `CMakeLists.txt` file (called the list file for short), which is used to describe build instructions.

My project will be organized as follows:

```
project root
- CMakeLists.txt
- src/
- include/
- config/
```

Where `src/` will contain the source files (`.c` files), `include/` will contain the header files, and `config/` will contain build configuration header files, which I will explain in a later post.

We can test the build setup with an example program that [blinks the onboard LED](https://github.com/raspberrypi/pico-examples/blob/master/pico_w/wifi/blink/picow_blink.c). This program will use the standard libraries from the cross compiler, the Pico-SDK, and the `cyw43` wifi driver. The source file will be placed in `src/blink.c`, and a minimal list file is provided below.

```cmake
# A minimal CMakeLists.txt to be placed under project root
# we will add to this file later

cmake_minimum_required(VERSION 3.13)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)
# export compile commands is important for language server
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(PICO_BOARD pico2_w CACHE STRING "Board type")
# this file should be copied into project root from 
# $PICO_SDK_PATH/external/pico_sdk_import.cmake
include(pico_sdk_import.cmake)

project(myproject C CXX ASM)
pico_sdk_init()

add_executable(blink src/blink.c)
target_link_libraries(blink
    pico_stdlib 
    pico_cyw43_arch_none
)
pico_add_extra_outputs(blink)
```

We can verify that Pico-SDK and cmake are good to go with a first test build:

```bash
mkdir build
cd build
cmake ..
make
```

This should produce firmware such as `blink.uf2`, which can be [flashed onto the board](https://www.raspberrypi.com/documentation/microcontrollers/c_sdk.html#your-first-binaries).

# Neovim
I use Neovim as my text editor and `clangd` (installed from [Mason.nvim](https://github.com/williamboman/mason.nvim)) as the language server. After calling `cmake ..` from within the `build` directory, CMake will export the compile commands to `build/compile_commands.json`, which `clangd` can automatically parse to locate the source and header files from Pico-SDK. However, we still need to specify the location of the cross compiler's standard libraries, or headers like `<stdio.h>` will not be recognized:

![Clangd not recognizing stdio header](/assets/imgs/neovim-pico2w-missing-stdlib.png)

There are [many ways to address this problem](https://www.reddit.com/r/raspberrypipico/comments/m5lsmw/nvim_for_picosdk_and_c/). My solution is to put a `.clangd` file at project root:

```yaml
# find the system includes using `arm-none-eabi-gcc -v -E -x c - < /dev/null`
CompileFlags:
  Add: [
    -I/opt/homebrew/Cellar/arm-none-eabi-gcc@8/8.5.0_2/lib/arm-none-eabi-gcc/8/gcc/arm-none-eabi/8.5.0/include,
    -I/opt/homebrew/Cellar/arm-none-eabi-gcc@8/8.5.0_2/lib/arm-none-eabi-gcc/8/gcc/arm-none-eabi/8.5.0/include-fixed,
    -I/opt/homebrew/Cellar/arm-none-eabi-gcc@8/8.5.0_2/arm-none-eabi/include,
  ]
  CompilationDatabase: build/
```

Restart LSP with `:LspRestart` and the standard libraries should be recognized:

![Clangd recognizing stdio header](/assets/imgs/neovim-recognizing-stdlib.png)

In part 2 I want to talk about writing a bare-metal DNS/NTP/TCP stack using `cyw43` and `lwip`.