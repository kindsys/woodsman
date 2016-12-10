gem uninstall woodsman
rm woodsman-*.gem
gem build woodsman.gemspec
gem install `ls woodsman-*.gem`
