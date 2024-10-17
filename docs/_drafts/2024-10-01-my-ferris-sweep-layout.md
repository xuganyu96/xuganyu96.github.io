---
layout: post
title:  "My Ferris Sweep layout"
date: 2024-10-07 10:32:47 -0400
categories: miscellaneous
---

In August this year I had a scary few days when my right wrist developed bad pains. In a neutral position it felt okay, but whenever I try to type on a keyboard, the twisting motion would trigger the pain. I've watched a few keyboard ergonomics videos on Youtube to know that there are two major bones in a human's forearm called the Ulna and the Radius, and in those a few days I felt as if turning the wrist to type really did cause the two bones to scissor something in my wrist. Sometimes it can even produce an audible click.

Fortunately, after a few days, the pain went away as it nothing really happened, but I was alarmed enough to start researching ergonomic keyboard. The primary objective is to find a keyboard with which I can type without moving my wrists outside the neutral position. My first choice was the [ZSA Moonlander](https://www.zsa.io/moonlander): it was very well-made, the [software experience](https://configure.zsa.io/) is superb, and it had **built-in tenting legs**.

![My Moonlander](/assets/imgs/my-moonlander.jpg)

For really surprised me was the speed at which I got used to the ortholinear/column-staggered layout of the Moonlander. In fact, I felt really fast when typing on or near the homerow, which made me feel slow and uncertain when trying to reach the other keys that require me to move my hand away from the homerow. After binge watching [Ben Vallack's videos on small keyboard layouts](https://www.youtube.com/watch?v=8wZ8FRwOzhU), I started removing keys from the Moonlander's default layout. After a month I shrank it down to 42 keys, then to 36, then to 34:

<div style="padding-top: 60%; position: relative;">
	<iframe src="https://configure.zsa.io/embed/moonlander/layouts/9pREN/latest/0" style="border: 0; height: 100%; left: 0; position: absolute; top: 0; width: 100%"></iframe>
</div>

At this point, the Moonlander is starting to feel unwieldy: for a keyboard with almost 80 physical keys, I'm only using less than half of them. After I found [this deal on Keebmaker](https://keebmaker.com/collections/mystery-box-keyboards), I put my Moonlander on sale and bought a 42-key Corne.

# The open-source keyboard experience
!["Myster" Corne MX 42](/assets/imgs/corne-42.jpeg)

The biggest hurdle to clear when moving from a ZSA product to an open-source keyboard, even a pre-built one, is the firmware experience. Keebmaker's hardware seemed very well made, and the keyboard was pre-flashed with [VIA](https://www.usevia.app/) so it can be customized straight out of the box. However, I quickly learned that VIA is missing combos and "CAPS Word", two features I found useful when configuring my ZSA keyboard. After some tinkering, I got QMK set up on my laptop, and wrote my [first QMK keymap in C](https://github.com/xuganyu96/qmk_firmware/tree/xuganyu96/keyboards/crkbd/keymaps/xuganyu96). About a week later, I also learned to display layer information and the status of the "CAPS Word" lock. Finally, although the Corne doesn't have tenting built in, some cheap laptop tenting legs from Amazon are sufficient to create a comfortable angle:

![Corne 34](/assets/imgs/corne-34.jpeg)

At around the time I got comfortable with my 34-key Corne, I bought a [Ferris Sweep](https://github.com/davidphilipbarr/Sweep) off Ebay for some 80 Canadian dollars. From the look alone, the sweep definitely looks like a hobbyist DIY job, but everything works, so after flashing it with the same keymap as the 34-key Corne, I started daily driving it in my office.

![Ferris Sweep](/assets/imgs/ferris-sweep-tenting.jpeg)

# My 34-key layout
My 34-key layout primarily evolved from the default keymap of the ZSA Moonlander, with the primary objective being to minimize movements from the home row. I also want to keep the number of layers small so as to not get lost. After some experimentation, I decided that home row mods and tap dance both make the affected keys feel sluggish and are prone to misfire, but home row mods are useful so I kept them, while tap dance is entirely replaced with layers. Finally, I played with keyboard combos for tab, escape, backspace, and enter, but they didn't feel comfortable enough, so I ended up not using them at all.

![Layer 0](/assets/imgs/ferris-sweep-l0.png)

The primary alphabetical layer with a standard QWERTY layout. Home row mods cover CMD (my daily drivers are MacBooks), OPT, and CTL on both sides. My thumbs naturally rest on the space key and the enter key, the latter of which doubles as the trigger for layer 1 when held down. The secondary thumb button is a **one-shot left shift**, which I found to be much more comfortable than having to hold down a shift key when capitalizing a letter. I also configured this one-shot left shift to activate CAPS Word when double tapped. It is worth noting that CAPS Word works as if the shift key is held down, so unlike CAPS Lock, if CAPS Word is activated, clicking the hyphen key will give me an underscore, which is immensely helpful with typing C macros.

![Layer 1](/assets/imgs/ferris-sweep-l1.png)

This layer is where my layout deviates from most other 34-key layouts I've read about (such as [Miryoku](https://github.com/manna-harbour/miryoku/tree/master/docs/reference)). Instead of having separate symbol and number layers, my layout integrates all symbols and numbers into a single layer, with many symbols accessible from using a "shift + number" combo. Some notable placements are:

1. Parenthesis, brackets, braces, and angle brackets are placed at the most accessible locations under my left index and middle finger. Braces are accessed by "shift + bracket", just like in a normal QWERTY layout
2. An extra "period" on the left hand side despite the fact that "period" already exists on Layer 0. This is such that I can type decimal number without leaving this layer
3. Another set of home row mods on the right-hand side so I can do navigation combos like "cmd + tab" or "ctl + backtick"

I was inspired by the aforementioend Ben Vallack video to have a predictable way to return to the default layer. With all other layers, the primary left thumb key always return back to layer 0. However, layer 1 is special because it can only be accessed by holding down the right thumb key, meaning that there is no way for layer 1 to stay permanently activated, hence no need for a dedicated "return home" button. Instead, the left thumb key is simply transparent.

![Layer 2](/assets/imgs/ferris-sweep-l2.png)

The mouse-navigation layer contains mouse keys on the left-hand side and arrow keys on the right-hand side. Unfortunately, I found using key preses for mouse movement rather difficult, so I mostly use an actual mouse/trackpad to do that (though I do use Vim as my main IDE so I didn't need to use mouse when programming).

![Layer 3](/assets/imgs/ferris-sweep-l3.png)

The final layer is dedicated to the reset button so I can flash my sweep without having to press a physical button and/or shorting pins on the microcontroller.

Something worth mentioning is that while the Corne (with a Pro Micro?) is flashed with the caterina bootloader, the Ferris Sweep (with an Elite C) uses the dfu bootloader. This means that after setting up my local QMK repository to work with the Corne by default, I need to add a `-bl dfu` argument when flashing the sweep. In the end, I made a shell alias so I don't have to worry about supplying the correct arguments:

```bash
alias flashferris="qmk flash -kb ferris/sweep -km xuganyu96 -bl dfu"
```

On [monkeytype.com](monkeytype.com) I can get to 80-90 WPM comfortably. On [keybr.com](https://www.keybr.com/) with some capitalization and punctuation turned on, I can get to 50-60 words consistently. I have since experimented with moving things around, but always come back to this layout, so it seemed to be my preference now.

This layout is of course not perfect. The biggest challenge at this moment is the difficulty of typing mixed letters and symbols, such as `var += 12.33` and `for (int i = 0; i <= arr.length; i++)`. Another difficulty is with accessing the arrow keys where Vim bindings are not present/supported. On the other hand, I still have a few unused keys on layer 1, and the escape key in layer 0 is largely unused, so improvements are definitely possible.