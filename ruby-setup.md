Install `rbenv` and `ruby-build`
```bash
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build
```

Initialize the environment:

```bash
echo 'eval "$(~/.rbenv/bin/rbenv init - zsh)"' >> ~/.zshrc
```

Restart the shell, then install Ruby 3.1.3. There is something that doesn't work out-of-the box about the installing Ruby 3.2.0 since it requires `libyaml` and `libyaml-devel`, the latter of which is not readily available through `brew`.

```bash
rbenv install 3.1.3
```

Set the user-installed version to be the default:

```bash
rbenv global 3.1.3
```

Restart the shell again, then navigate to the Jekyll project directory. First install the gems specified by the Gemfile, then serve the project

```bash
bundle install
bundle exec jekyll serve
```