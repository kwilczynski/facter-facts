#
# filesystems.rb
#
# This fact provides an alphabetic list of usable file systems that can
# be used for block devices like hard drives, media cards and so on ...
#

require 'thread'
require 'facter'

if Facter.value(:kernel) == 'Linux'

  mutex = Mutex.new

  # We store a list of file systems here ...
  file_systems = []

  #
  # Modern Linux kernels provide "/proc/filesystems" in the following format:
  #
  #   nodev   sysfs
  #   nodev   rootfs
  #   nodev   bdev
  #   nodev   proc
  #   nodev   cgroup
  #   nodev   cpuset
  #   nodev   debugfs
  #   nodev   securityfs
  #   nodev   sockfs
  #   nodev   pipefs
  #   nodev   anon_inodefs
  #   nodev   tmpfs
  #   nodev   inotifyfs
  #   nodev   devpts
  #           ext3
  #           ext2
  #           ext4
  #   nodev   ramfs
  #   nodev   hugetlbfs
  #   nodev   ecryptfs
  #   nodev   fuse
  #           fuseblk
  #   nodev   fusectl
  #   nodev   mqueue
  #           xfs
  #   nodev   binfmt_misc
  #           vfat
  #           iso9660
  #
  # We skip every "nodev" entry as they cannot really be used for block
  # devices like hard drives and media cards, and so on ...
  #

  #
  # We utilise rely on "cat" for reading values from entries under "/proc".
  # This is due to some problems with IO#read in Ruby and reading content of
  # the "proc" file system that was reported more than once in the past ...
  #
  %x{ cat /proc/filesystems 2> /dev/null }.each do |line|
    # Remove bloat ...
    line.strip!

    # Line of interest should not start with "nodev" ...
    next if line.empty? or line.match(/^nodev/)

    mutex.synchronize { file_systems << line }
  end

  Facter.add('filesystems') do
    confine :kernel => :linux
    setcode { file_systems.sort.join(',') }
  end
end

# vim: set ts=2 sw=2 et :
