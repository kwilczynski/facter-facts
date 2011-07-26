#
# users.rb
#
# This fact provides an alphabetic list of users on a Linux system host.
#
# The assumption is that users have UID greater than 500 and anything
# below that is nothing of our concern ...
#

require 'thread'
require 'facter'
require 'puppet'

if Facter.value(:kernel) == 'Linux'

  mutex = Mutex.new

  users = []

  Puppet::Type.type('user').instances.each do |user|
    # Get details about the user from the corresponding instance ...
    instance = user.retrieve

    mutex.synchronize do
      # Add user to list only if the user is not an essential system user ...
      users << user.name unless instance[user.property(:uid)].to_i < 500
    end
  end

  Facter.add('users') do
    confine :kernel => :linux
    setcode { users.sort.join(',') }
  end
end

# vim: set ts=2 sw=2 et :
