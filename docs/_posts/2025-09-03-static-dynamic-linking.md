---
layout: post
title:  "Static and dynamic linking"
date: 2025-09-03 14:29:18 -0400
categories: miscellaneous
---

This is a sloppy personal note on the basic of static and dynamic libraries in C programming.

# Compile directly from source
Suppose I have a simple program at `hello.c`

```c
/* hello.c */
#include <stdio.h>

int main(int argc, char *argv[]) {
    printf("你好，🌍!\n");
    return 0;
}

```

The OS-native C compiler can compile it straight into an executable:

```bash
cc hello.c -o hello
# Should print the message
./hello
```

Sometimes functionalities need to be split into two source files.
Consider the following example with two files:
- `libhello.c` which contains the function `void *hello(const char *name)`
- `hello.c`, which is the main program.

```c
/* libhello.c */
#include <stdio.h>

void greet(const char *name) {
    printf("你好，%s!\n", name);
}
```

For `hello.c` to use `greet`, some declaration is required.
One way is to use the `extern` keyword.

```c
#include <stdio.h>

extern void greet(const char *name);

int main(int argc, char *argv[]) {
    greet("🌍");
    return 0;
}
```

If there is no declaration, the compiler will complain:

> error: call to undeclared function 'greet'

If there is a declaration but no implementation, then the linker will complain:

```
Undefined symbols for architecture arm64:
  "_greet", referenced from:
      _main in hello-45e4f0.o
ld: symbol(s) not found for architecture arm64
clang: error: linker command failed with exit code 1 (use -v to see invocation)
```

Note that it is okay to declare a function without implementation *if the function is never called*.

Typically, the library developers are a different group from the library users.
Developers can use a header file to "advertise" the public API of the library, 
so the user does not have to declare the functions manually.

A header file looks like this:

```c
/* libhello.h */
#ifndef LIBHELLO_H
#define LIBHELLO_H

void greet(const char *name);

#endif /* LIBHELLO_H */
```

The compiler needs to be aware of where the header file is located.
In this example, `libhello.h` is located at `include/libhello/libhello.h`,
so we need to add the `include/` directory to the compiler command:

```bash
cc -I$(pwd)/include src/libhello.c src/hello.c
```

With the `-I/path/to/include` flag, `hello.c` can use `libhello.h` using an include statement:

```c
#include "libhello/libhello.h"
```

Clangd can be configured to discover header via `.clangd`:

```yml
CompileFlags:
  Add: ["-I/path/to/your/include"]
```

# Static linking
The library developer can compile the library code into a static library (`.a` on UNIX systems),
then provide the user with the `libhello.h` header and the `libhello.a` library file.

```bash
# Use -c flag to compile libhello.c into object file
cc -c src/libhello.c -o build/libhello.o

# Insert the object file (r flag) into archive file, create if not exist (c flag),
# create index for faster linking (s flag)
ar rcs build/libhello.a build/libhello.o 

# Compile binary using the static library instead of the source code
cc -I$(pwd)/include src/hello.c build/libhello.a -o build/hello
```

Check the size of the binary `ls -lh build/hello`. Mine shows `33464` bytes.

Time the execution of the binary with `time build/hello`:

```
build/hello  0.00s user 0.01s system 2% cpu 0.329 total
```

# Dynamic linking
With dynamic linking, the function `greet` will be loaded at program runtime instead of compile time.

First, compile the library code into a shared library with the `-shared` flag.
GPT 4.0-mini says that the `-fPIC` flag (position independent code) is necessary,
but I am not sure why.

```bash
cc -shared -fPIC -o build/libhello.so src/libhello.c
```

Next, compile the program `hello`. 
Compiler needs to know the directory of the library via the `-L` flag,
and the name of the library via the `-l` flag.
If the `.so` file's name start with `lib`, then this prefix can be omitted;
if not, then the full name is needed.

```bash
cc -I$(pwd)/include -L$(pwd)/build -lhello src/hello.c -o build/hello

# alternatively, specify the full path
cc -I$(pwd)/include -L$(pwd)/build build/libhello.so src/hello.c -o build/hello
```

When running the program, the dynamic linker needs to know where the dynamic library is.
This can be specified using the `LD_LIBRARY_PATH` variable:

```bash
LD_LIBRARY_PATH=$(pwd)/build:$LD_LIBRARY_PATH ./build/hello
```

The dynamically-linked binary `build/hello` is slightly smaller than the statically linked binary: 33432 vs 33464 bytes.

But the program used more CPU:

```
build/hello  0.00s user 0.00s system 74% cpu 0.007 total
```