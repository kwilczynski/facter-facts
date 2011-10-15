#
# location.rb
#

require 'facter'

#
# We choose location based on simple network to country look-up were we
# use common ISO country codes as follows ...
#
# Location can be anything: a place, a data centre, etc; same in regards
# to the country.
#
location = {
  '10.0.0'    => { :country => 'uk', :location => 'cambridge' },
  '192.168.0' => { :country => 'uk', :location => 'london'    }
}

if Facter.value(:kernel) == 'Linux'
  # When we cannot match anything this will stand-out ...
  this_country, this_location = 'UNKNOWN', 'UNKNOWN'

  # We will store IP address of the machine we run on here ...
  this_address = ''

  #
  # We utilise rely on "cat" for reading values from entries under "/proc".
  # This is due to some problems with IO#read in Ruby and reading content of
  # the "proc" file system that was reported more than once in the past ...
  #
  # This will only select first matching IP address and in that regards
  # it is very similar to the "ipaddress" fact from Facter ...
  #
  Facter::Util::Resolution.exec('/sbin/ifconfig 2> /dev/null').each_line do |line|
    # Remove bloat!
    line.strip!

    # Skip new and empty lines ...
    next if line.match(/^(\r\n|\n|\s*)$|^$/)

    # Process output and capture details about IP addresses only ...
    if match = line.match(/inet addr:((?:[0-9]+\.){3}[0-9]+)/)
      this_address = match[1]
      # We are not interested in local host ...
      break unless this_address.match(/^127\./)
    else
      # Skip irrelevant entries ...
      next
    end
  end

  # We only consider first three octets from within the IP address ...
  this_address = this_address.split('.').slice(0, 3).join('.')

  if location.has_key?(this_address)
    this_country  = location[this_address][:country]
    this_location = location[this_address][:location]
  end

  Facter.add('country') do
    confine :kernel => :linux
    setcode { this_country }
  end

  Facter.add('location') do
    confine :kernel => :linux
    setcode { this_location }
  end
end

# vim: set ts=2 sw=2 et :
# encoding: utf-8
