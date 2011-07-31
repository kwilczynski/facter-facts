#
# partitions.rb
#
# This fact provides an alphabetic list of partitions per disk and disks.
#
# We support most of generic SATA and PATA disks, plus Hewlett-Packard
# Smart Array naming format ...  This also should work for systems running
# as Virtual Machine guest at least for Xen and KVM ...
#

require 'thread'
require 'facter'

if Facter.value(:kernel) == 'Linux'

  mutex = Mutex.new

  # We store a list of disks (or block devices if you wish) here ...
  disks = []

  # We store a list of partitions on per-disk basis here ...
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

  #
  # We utilise rely on "cat" for reading values from entries under "/proc".
  # This is due to some problems with IO#read in Ruby and reading content of
  # the "proc" file system that was reported more than once in the past ...
  #
  %x{ cat /proc/partitions 2> /dev/null }.each do |line|
    # Remove bloat ...
    line.strip!

    # Line of interest should start with a number ...
    next if line.empty? or line.match(/^[a-zA-Z]+/)

    # We have something, so let us apply our device type filter ...
    next if line.match(exclude)

    # Only disks and partitions matter ...
    partition = line.split(/\s+/)[3]

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
