MacOS is shipped with a default installation of ruby under `/usr/bin/ruby`. At the time of writing this blog entry, the version shipped with my laptop is

```
> /usr/bin/ruby -v
ruby 2.6.8p205 (2021-07-07 revision 67951) [universal.x86_64-darwin21]
```

In addition to being out-of-date, the default installation of Ruby also comes with a default installation of Ruby's package manager `gem` that installs packages to privileged paths. When I attempt to install Jekyll with the `gem` found under `/usr/bin/gem`, the following error message ensues

```
ERROR:  While executing gem ... (Gem::FilePermissionError)
    You don't have write permissions for the /Library/Ruby/Gems/2.6.0 directory.
```

For managing a Jekyll project, we will install Ruby from Homebrew. After the installation completes, add `ruby` and `gem` to `PATH`:

{% highlight bash %}
brew install ruby
echo 'export PATH="/usr/local/opt/ruby/bin:$PATH"' > ~/.zshrc
source ~/.zshrc
ruby -v  # should return version 3.1+
gem -v # should return version 3.3+
{% endhighlight %}

We can now install `bundler` and `jekyll` and add their executable to path

{% highlight bash %}
gem install bundler jekyll
export PATH="/usr/local/lib/ruby/gems/3.1.0/bin:$PATH"
{% endhighlight %}

Jekyll is now ready:

{% highlight bash %}
jekyll new docs
cd docs
bundler add webrick  # Check https://github.com/jekyll/jekyll/issues/8523
bundler exec jekyll serve
{% endhighlight %}