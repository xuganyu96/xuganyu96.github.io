---
layout: post
title:  "When does printf flush?"
date:   2025-10-08 10:24:33 -0400
categories: miscellaneous
---

When programming in C, `printf` is usually used to output to the standard output `stdout`.
When the output goes straight to `stdout`, `printf` flushes at new line.
However, when the output is piped into another program's `stdin`, `printf` is fully buffered and needs to be manually flushed.

```c
#include <stdio.h>
#include <unistd.h>

int main(void) {
    printf("before sleep\n");
    sleep(10);
    printf("after sleep\n");
}
```
