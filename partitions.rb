#
# partitions.rb
#

require 'thread'
require 'facter'

if Facter.value(:kernel) == 'Linux'

  # Support for the following requires magic to be added ...
  exclude = %w( cciss dm loop )

  #
  # Modern Linux kernels provide "/proc/partitions" as for example:
  #
  #  major minor  #blocks  name
  #
  #     8        0  244198584 sda
  #     8        1    3148708 sda1
  #     8        2  123804922 sda2
  #     8        3  116214210 sda3
  #     8        4    1028160 sda4
  #

  partitions = {}

  mutex = Mutex.new

  result = %x{ cat /proc/partitions 2> /dev/null }

  result.each do |l|
    l = l.strip

    # Line of interest should start with a number ...
    next if l.empty? or l.match(/^[a-zA-Z]+/)

    partition = l.split(/\s+/)[3]
    disk      = partition.scan(/[a-zA-Z]+/)[0]

    # Apply our device type filter ...
    next if exclude.include?(disk)

    mutex.synchronize do
      # A disk is not a partition, is it not?
      (partitions[disk] ||= []) << partition unless partition == disk
    end
  end

  disks = partitions.keys.join(',')

  Facter.add('disks') do
    confine :kernel => :linux

    setcode { disks }
  end

  partitions.each do |k, v|
    v = v.sort.join(',')

    Facter.add("partitions_#{k}") do
      confine :kernel => :linux

      setcode { v }
    end
  end
end

# vim: set ts=2 sw=2 et :
