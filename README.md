# xuganyu96.github.io
My personal website: xuganyu96.github.io

## Managing dot files
From the project root, run the following commands:

```bash
# Copy over neovim config
ln -s $(pwd)/neovim ~/.config/nvim

# Copy over tmux config
ln -s $(pwd)/tmux.conf ~/.tmux.conf

# Copy over global gitignore
ln -s $(pwd)/global.gitignore ~/.gitignore
git config --global core.excludesFile "~/.gitignore"
```

# What's next: cryptography engineering
I really like cryptography. Mathematics and engineering mix at just the right ratio in this field, and making a career in engineering cryptographic software is less competitive than traditional web dev while being simultaneous more promising. I consider myself extremely lucky to have found a professional interest that can pay well and that I, fingers crossed, enjoy tremendously.

Both a blessing and a curse, there is an enormous amount of work that can be done in cryptography. From implementing novel primitives to building secure applications, the number of possibilities is dizzying to look at. Choosing a good place to start and stick with it seems rather important, lest I end up wandering in circles and burning myself out, wasting this precious chance of making a successful career in engineering cryptography.

There are two main areas that I find to intrigue me the most. One is lattice-based cryptography, an area that has a wealth of theory but scant implementation. It is also the most promising candidate for post-quantum cryptography, so it is a great idea to learn more about it. The second is elliptic curve cryptography, which I find interesting largely thanks to [`djao`](https://djao.math.uwaterloo.ca/). These are the two theoretical subjects that I aim to specialize. With lattice, I will need to study on my own, but with EC there should be many mathematicians and computer science experts I can turn to for help.

Based on personal experience, I can also identify a few key technologies commonly used: a system-leveling programming language like C/C++, and a high-level computer algebraic system such as SageMath. While I don't have time to learn all of them at the same time, I do know Rust and have used `sympy` a few times, so I can begin by working in the RustCrypto ecosystem and familiarize myself with `sympy` for doing algebra on a computer.

- Make contribution to the RustCrypto ecosystem
    - [Minor issues](https://github.com/RustCrypto/crypto-bigint/issues/268) for `RustCrypto/crypto-bigint`
- Self-study lattice cryptography
- Self-study elliptic curve cryptography
- Learn C/C++