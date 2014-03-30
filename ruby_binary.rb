#
# ruby_binary.rb
#
# This fact provides information about where Ruby binary is located on
# the underlying file system ...
#

if Facter.value(:kernel) == 'Linux'
  #
  # We add our fact as single word "rubybinary" instead of "ruby_binary"
  # purely to maintain compliance with other Ruby-related facts ...
  #
  Facter.add('rubybinary') do
    confine :kernel => :linux
    setcode do
      config = RbConfig::CONFIG
      File.join(config['bindir'], config['ruby_install_name'])
    end
  end
end

# vim: set ts=2 sw=2 et :
# encoding: utf-8
