---
layout: post
title:  "Getting started with WolfSSL on Raspberry Pi Pico 2 W"
date: 2025-04-06 11:50:48 -0400
categories: cryptography
---

In this post documents the process by which I built an example firmware for the [Raspberry Pi Pico 2 W(])(https://www.raspberrypi.com/products/raspberry-pi-pico-2/) that uses the WolfSSL library to perform a handshake with some public server.

Make sure we have `cmake` and `arm-none-eabi-gcc`. Use the command `arm-none-eabi-gcc -v -E -x c - < /dev/null` to find the location of the standard libraries.

Make sure `$PICO_SDK_PATH` points to the pico SDK source code. Copy `pico-sdk/external/pico_sdk_import.cmake` to the project repository. It is also very helpful to have [`picotool`](https://github.com/raspberrypi/picotool) installed.

```bash
cp $PICO_SDK_PATH/external/pico_sdk_import.cmake ./
```

Set up the template CMake list file.

```cmake
cmake_minimum_required(VERSION 3.13)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(PICO_BOARD pico2_w)

include(pico_sdk_import.cmake)
project(pico-wolfssl C CXX ASM)
pico_sdk_init()

# example client
add_executable(tls13client src/tls13client.c)
pico_enable_stdio_uart(tls13client 0)
pico_enable_stdio_usb(tls13client 1)
target_link_libraries(tls13client pico_stdlib)
pico_add_extra_outputs(tls13client)

```

Compile an empty program to make sure that the build system works:

```c
// src/tls13client.c
#include <stdio.h>
#include <pico/stdlib.h>

int main(void) {
    stdio_init_all();

    while(1) {
        printf("Hello, world!\n");
        sleep_ms(1000);
    }
}
```

Configure build system with CMake, then build with make:

```bash
mkdir build && cd build
cmake ..
# `make` should output the firmware `tls13client.elf` and `tls13client.uf2`
make
```

To load the firmware, hold down the BOOTSEL button on the board and plug it in (after plugging in the button can be released). The board should show up as a mass storage device. Drag and drop the `.uf2` file into the device and it should reboot into application mode automatically and start executing the program. To read the serial output, one can use `minicom`:

```bash
minicom -b 115200 -o -D /dev/tty.usbmodem -C serial.log
```

## (Optional) Configuring dev environment for Neovim
`clangd` in Neovim needs to know where the ARM GCC standard library headers are and where the pico SDK headers are:

```yaml
# find the system includes using `arm-none-eabi-gcc -v -E -x c - < /dev/null`
CompileFlags:
  Add: [
    -I/opt/homebrew/Cellar/arm-none-eabi-gcc@8/8.5.0_2/lib/arm-none-eabi-gcc/8/gcc/arm-none-eabi/8.5.0/include,
    -I/opt/homebrew/Cellar/arm-none-eabi-gcc@8/8.5.0_2/lib/arm-none-eabi-gcc/8/gcc/arm-none-eabi/8.5.0/include-fixed,
    -I/opt/homebrew/Cellar/arm-none-eabi-gcc@8/8.5.0_2/arm-none-eabi/include
  ]
  CompilationDatabase: build/
```

Sometimes the pico SDK headers are not immediately discoverable to `clangd`. In this case you need to add the library to the target binaries, then re-run `cmake ..`, which will allow `clangd` to discover the headers using `build/compile_commands.json`.

# TCP/IP stack
The Pico 2 W comes with a wireless module that can connect to Wifi, and pico SDK includes the driver source code that can be used directly

- Include `lwipopts.h`, [example](https://raw.githubusercontent.com/raspberrypi/pico-examples/refs/heads/master/pico_w/wifi/lwipopts_examples_common.h)
- add `src/` to `include_directories` so `make` can find `lwipopts.h`
- add `pico_cyw43_arch_lwip_threadsafe_background` to `target_link_libraries`, run `cmake ..`, then start using `#include "pico/cyw43_arch.h"`