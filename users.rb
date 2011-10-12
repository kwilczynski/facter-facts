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

  # We store a list of users which are not an essential systems users here ...
  users = []

  #
  # We use "getent" binary first if possible to look-up what users are currently
  # available on system.  This is possibly due to an issue in Puppet "user" type
  # which causes Facter to delay every Puppet run substantially especially when
  # LDAP is in place to provide truth source about users etc ...
  #
  # In the unlikely event in which the "getent" binary is not available we simply
  # fall-back to using Puppet "user" type ...
  #
  if File.exists?('/usr/bin/getent')
    #
    # We utilise rely on "cat" for reading values from entries under "/proc".
    # This is due to some problems with IO#read in Ruby and reading content of
    # the "proc" file system that was reported more than once in the past ...
    #
    Facter::Util::Resolution.exec('/usr/bin/getent passwd').each_line do |line|
      # Remove bloat!
      line.strip!

      #
      # Modern Linux distributions provide "/etc/passwd" in the following format:
      #
      #  root:x:0:0:root:/root:/bin/bash
      #  (...)
      #
      # Above line has the follwing fields separated by the ":" (colon):
      #
      #  <user name>:<password>:<user ID>:<group ID>:<comment>:<home directory>:<command shell>
      #
      # We only really care about "user name" and "user ID" fields.
      #
      user = line.split(':')

      # Add user to list only if the user is not an essential system user ...
      users << user[0] unless user[2].to_i < 500
    end
  else
    Puppet::Type.type('user').instances.each do |user|
      # Get details about the user from the corresponding instance ...
      instance = user.retrieve

      mutex.synchronize do
        # Add user to list only if the user is not an essential system user ...
        users << user.name unless instance[user.property(:uid)].to_i < 500
      end
    end
  end

  Facter.add('users') do
    confine :kernel => :linux
    setcode { users.sort.join(',') }
  end
end

# vim: set ts=2 sw=2 et :
