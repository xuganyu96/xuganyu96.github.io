---
layout: post
title:  "ASCII diagram cheatsheet"
date:   2026-05-22 11:59:11 -0400
categories: other
---

Here's a reference of commonly used Unicode box-drawing and arrow characters, organized by category.

---

### Light Box Drawing

| Char | Name | Unicode | UTF-8 Bytes (hex) |
|------|------|---------|-------------------|
| `─` | Horizontal | U+2500 | `E2 94 80` |
| `│` | Vertical | U+2502 | `E2 94 82` |
| `┌` | Down and Right | U+250C | `E2 94 8C` |
| `┐` | Down and Left | U+2510 | `E2 94 90` |
| `└` | Up and Right | U+2514 | `E2 94 94` |
| `┘` | Up and Left | U+2518 | `E2 94 98` |
| `├` | Vertical and Right | U+251C | `E2 94 9C` |
| `┤` | Vertical and Left | U+2524 | `E2 94 A4` |
| `┬` | Down and Horizontal | U+252C | `E2 94 AC` |
| `┴` | Up and Horizontal | U+2534 | `E2 94 B4` |
| `┼` | Vertical and Horizontal | U+253C | `E2 94 BC` |

---

### Heavy Box Drawing

| Char | Name | Unicode | UTF-8 Bytes (hex) |
|------|------|---------|-------------------|
| `━` | Heavy Horizontal | U+2501 | `E2 94 81` |
| `┃` | Heavy Vertical | U+2503 | `E2 94 83` |
| `┏` | Heavy Down and Right | U+250F | `E2 94 8F` |
| `┓` | Heavy Down and Left | U+2513 | `E2 94 93` |
| `┗` | Heavy Up and Right | U+2517 | `E2 94 97` |
| `┛` | Heavy Up and Left | U+251B | `E2 94 9B` |

---

### Double Box Drawing

| Char | Name | Unicode | UTF-8 Bytes (hex) |
|------|------|---------|-------------------|
| `═` | Double Horizontal | U+2550 | `E2 95 90` |
| `║` | Double Vertical | U+2551 | `E2 95 91` |
| `╔` | Double Down and Right | U+2554 | `E2 95 94` |
| `╗` | Double Down and Left | U+2557 | `E2 95 97` |
| `╚` | Double Up and Right | U+255A | `E2 95 9A` |
| `╝` | Double Up and Left | U+255D | `E2 95 9D` |
| `╠` | Double Vertical and Right | U+2560 | `E2 95 A0` |
| `╣` | Double Vertical and Left | U+2563 | `E2 95 A3` |
| `╦` | Double Down and Horizontal | U+2566 | `E2 95 A6` |
| `╩` | Double Up and Horizontal | U+2569 | `E2 95 A9` |
| `╬` | Double Vertical and Horizontal | U+256C | `E2 95 AC` |

---

### Rounded Corners

| Char | Name | Unicode | UTF-8 Bytes (hex) |
|------|------|---------|-------------------|
| `╭` | Arc Down and Right | U+256D | `E2 95 AD` |
| `╮` | Arc Down and Left | U+256E | `E2 95 AE` |
| `╯` | Arc Up and Left | U+256F | `E2 95 AF` |
| `╰` | Arc Up and Right | U+2570 | `E2 95 B0` |

---

### Dashed Lines

| Char | Name | Unicode | UTF-8 Bytes (hex) |
|------|------|---------|-------------------|
| `┄` | Light Triple Dash Horizontal | U+2504 | `E2 94 84` |
| `┆` | Light Triple Dash Vertical | U+2506 | `E2 94 86` |
| `┈` | Light Quadruple Dash Horizontal | U+2508 | `E2 94 88` |
| `┊` | Light Quadruple Dash Vertical | U+250A | `E2 94 8A` |
| `╌` | Light Double Dash Horizontal | U+254C | `E2 95 8C` |
| `╎` | Light Double Dash Vertical | U+254E | `E2 95 8E` |

---

### Arrows

| Char | Name | Unicode | UTF-8 Bytes (hex) |
|------|------|---------|-------------------|
| `←` | Left Arrow | U+2190 | `E2 86 90` |
| `↑` | Up Arrow | U+2191 | `E2 86 91` |
| `→` | Right Arrow | U+2192 | `E2 86 92` |
| `↓` | Down Arrow | U+2193 | `E2 86 93` |
| `↔` | Left-Right Arrow | U+2194 | `E2 86 94` |
| `↕` | Up-Down Arrow | U+2195 | `E2 86 95` |
| `⇐` | Double Left Arrow | U+21D0 | `E2 87 90` |
| `⇒` | Double Right Arrow | U+21D2 | `E2 87 92` |
| `⇑` | Double Up Arrow | U+21D1 | `E2 87 91` |
| `⇓` | Double Down Arrow | U+21D3 | `E2 87 93` |

---

### Arrowheads / Pointers

| Char | Name | Unicode | UTF-8 Bytes (hex) |
|------|------|---------|-------------------|
| `▲` | Black Up-Pointing Triangle | U+25B2 | `E2 96 B2` |
| `▶` | Black Right-Pointing Triangle | U+25B6 | `E2 96 B6` |
| `▼` | Black Down-Pointing Triangle | U+25BC | `E2 96 BC` |
| `◀` | Black Left-Pointing Triangle | U+25C0 | `E2 97 80` |
| `▴` | Small Up-Pointing Triangle | U+25B4 | `E2 96 B4` |
| `▸` | Small Right-Pointing Triangle | U+25B8 | `E2 96 B8` |
| `▾` | Small Down-Pointing Triangle | U+25BE | `E2 96 BE` |
| `◂` | Small Left-Pointing Triangle | U+25C2 | `E2 97 82` |

---

### UTF-8 Encoding Quick Reference

All characters above are in the Unicode range U+0800–U+FFFF, so they always encode to **3 bytes** using the pattern:

```
1110xxxx  10xxxxxx  10xxxxxx
  byte 1    byte 2    byte 3
```

For example, `─` (U+2500 = `0010 0101 0000 0000` in binary):
```
1110 0010  10 010100  10 000000
  E2         94         80
```