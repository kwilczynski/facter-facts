#
# bonding.rb
#
# This fact provides a list of all available bonding interfaces that are
# currently present in the system including details about their current
# configuration in terms of per-interface status, current primary and
# active slave as well as a list of slaves interfaces attached ...
#

require 'thread'
require 'facter'

if Facter.value(:kernel) == 'Linux'

  mutex = Mutex.new

  # We capture per-bonding interface configuration here ...
  configuration = Hash.new { |k,v| k[v] = {} }

  # We search for the "/proc/net/bonding" directory and everything inside ...
  bonding_directory = "/proc/net/bonding"
  search_pattern    = "#{bonding_directory}/*"

  #
  # Modern Linux kernels provide entries under "/proc/net/bonding" directory
  # in the following format.  An example of "/proc/net/bonding/bond0":
  #
  #   Ethernet Channel Bonding Driver: v3.5.0 (November 4, 2008)
  #
  #   Bonding Mode: fault-tolerance (active-backup)
  #   Primary Slave: None
  #   Currently Active Slave: eth0
  #   MII Status: up
  #   MII Polling Interval (ms): 100
  #   Up Delay (ms): 200
  #   Down Delay (ms): 200
  #
  #   Slave Interface: eth0
  #   MII Status: up
  #   Link Failure Count: 0
  #   Permanent HW addr: 68:b5:99:c0:56:74
  #
  #   Slave Interface: eth1
  #   MII Status: up
  #   Link Failure Count: 0
  #   Permanent HW addr: 00:25:b3:02:b3:18
  #

  # Check whether there is anything to do at all ...
  if File.exists?(bonding_directory)
    # Process all known bonding interfaces ...
    Dir[search_pattern].each do |interface|
      # We store name of the slave interfaces on the side ...
      slaves = []

      #
      # We utilise rely on "cat" for reading values from entries under "/proc".
      # This is due to some problems with IO#read in Ruby and reading content of
      # the "proc" file system that was reported more than once in the past ...
      #
      %x{ cat "#{interface}" 2> /dev/null }.each do |line|
        # Remove bloat ...
        line.strip!

        # Skip new and empty lines ...
        next if line.match(/^(\r\n|\n|\s*)$|^$/)

        # Strip surplus path from the name ...
        interface = File.basename(interface)

        # Process configuration line by line ...
        case line
        when /Primary Slave:\s/
          # Take the value only  ...
          value = line.split(':')[1].strip

          mutex.synchronize do
            configuration[interface].update(:primary_slave => value)
          end
        when /Currently Active Slave:\s/
          # Take the value only ...
          value = line.split(':')[1].strip

          mutex.synchronize do
            configuration[interface].update(:active_slave => value)
          end
        when /MII Status:\s/
          # Take the value only ...
          value = line.split(':')[1].strip

          mutex.synchronize do
            configuration[interface].update(:status => value)
          end
        when /Slave Interface:\s/
          # Take the value only ...
          value = line.split(':')[1].strip

          mutex.synchronize do
            slaves << value
          end
        else
          # Skip irrelevant entries ...
          next
        end
      end

      #
      # No slaves?  Then set to "none" otherwise ensure proper sorting order
      # by the interface name ...  This is to ensure consistency between active
      # and inactive bonding interface ...  In other words if the bonding
      # interface is "down" we still set relevant fact about its slaves ...
      #
      slaves = slaves.empty? ? 'none' : slaves.sort_by { |i| i.match(/\d+/)[0].to_i }

      mutex.synchronize do
        configuration[interface].update(:slaves => slaves)
      end
    end

    # To ensure proper sorting order by the interface name ...
    interfaces = configuration.keys.sort_by { |i| i.match(/\d+/)[0].to_i }

    Facter.add('bonding_interfaces') do
      confine :kernel => :linux
      setcode { interfaces.join(',') }
    end

    # Process per-interface configuration and add fact about it ...
    interfaces.each do |interface|
      configuration[interface].each do |k,v|
        # Check whether we deal with a list of slaves or not ...
        value = v.is_a?(Array) ? v.join(',') : v

        # Make everything lower-case for consistency sake ...
        value.tr!('A-Z', 'a-z')

        # Add fact relevant to a particular bonding interface ...
        Facter.add("bonding_#{interface}_#{k.to_s}") do
          confine :kernel => :linux
          setcode { value }
        end
      end
    end
  end
end

# vim: set ts=2 sw=2 et :
