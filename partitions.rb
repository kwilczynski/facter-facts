#
# partitions.rb
#

require 'thread'
require 'facter'

if Facter.value(:kernel) == 'Linux'

  mutex = Mutex.new

  disks      = []
  partitions = Hash.new { |k,v| k[v] = [] }

  #
  # Support for the following might not be of interest ...
  #
  # MMC is Multi Media Card which can be either SD or microSD, etc ...
  # MTD is Memory Technology Device also known as Flash Memory
  #
  exclude = %w( backdev.* dm loop md mmcblk mtdblock ramzswap )

  #
  # Modern Linux kernels provide "/proc/partitions" in the following format:
  #
  #  major minor  #blocks  name
  #
  #     8        0  244198584 sda
  #     8        1    3148708 sda1
  #     8        2  123804922 sda2
  #     8        3  116214210 sda3
  #     8        4    1028160 sda4
  #

  # Make regular expression form our patterns ...
  exclude = Regexp.union(exclude.collect { |i| Regexp.new(i) })

  %x{ cat /proc/partitions 2> /dev/null }.each do |l|
    # Remove bloat ...
    l.strip!

    # Line of interest should start with a number ...
    next if l.empty? or l.match(/^[a-zA-Z]+/)

    # We have something, so let us apply our device type filter ...
    next if l.match(exclude)

    # Only disks and partitions matter ...
    partition = l.split(/\s+/)[3]

    if partition.match(/^cciss/)
      #
      # Special case for Hewlett-Packard Smart Array which probably
      # nobody is using any more nowadays anyway ...
      #
      partition = partition.split('/')[1]
      disk      = partition.scan(/^([a-zA-Z0-9]+)[pP][0-9]/)
    else
      # Everything else ...
      disk = partition.scan(/^[a-zA-Z]+/)
    end

    disk = disk.to_s

    # We have something rather odd that did not parse at all, so ignore ...
    next if disk.empty?

    mutex.synchronize do
      # All disks ... This might even be sda, sdaa, sdab, sdac, etc ...
      disks << disk
      # A disk is not a partition, therefore we ignore ...
      partitions[disk] << partition unless partition == disk
    end
  end

  Facter.add('disks') do
    confine :kernel => :linux
    setcode { disks.sort.uniq.join(',') }
  end

  partitions.each do |k,v|
    Facter.add("partitions_#{k}") do
      confine :kernel => :linux
      setcode { v.sort.join(',') }
    end
  end
end

# vim: set ts=2 sw=2 et :
