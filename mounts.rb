#
# mounts.rb
#
# This fact provides list of mount points present in the system alongside
# any known block devices on which a particular mount point resides ...
#
# We do some filtering based on patterns for file systems and devices that
# make no sense and are not of our concern ...
#

require 'thread'
require 'facter'

if Facter.value(:kernel) == 'Linux'

  mutex = Mutex.new

  mounts  = []
  devices = []

  #
  # Support for the following might not be of interest ...
  #
  exclude = %w( afs aufs autofs bind binfmt_.* cifs coda devfs devpts fd ftpfs
    fuse.* gvfs.* iso9660 lustre.* mfs ncpfs NFS nfs.* none proc rpc_.* securityfs
    shfs shm smbfs sysfs tmpfs udev udf unionfs usbfs )

  #
  # Modern Linux kernels provide "/proc/mounts" in the following format:
  #
  #   rootfs / rootfs rw 0 0
  #   none /sys sysfs rw,nosuid,nodev,noexec,relatime 0 0
  #   none /proc proc rw,nosuid,nodev,noexec,relatime 0 0
  #   udev /dev tmpfs rw,relatime,mode=755 0 0
  #   none /sys/kernel/security securityfs rw,relatime 0 0
  #   none /sys/fs/fuse/connections fusectl rw,relatime 0 0
  #   none /sys/kernel/debug debugfs rw,relatime 0 0
  #   none /dev/pts devpts rw,nosuid,noexec,relatime,gid=5,mode=620,ptmxmode=000 0 0
  #   none /dev/shm tmpfs rw,nosuid,nodev,relatime 0 0
  #   none /var/run tmpfs rw,nosuid,relatime,mode=755 0 0
  #   none /var/lock tmpfs rw,nosuid,nodev,noexec,relatime 0 0
  #   none /lib/init/rw tmpfs rw,nosuid,relatime,mode=755 0 0
  #   /dev/sda5 /home xfs rw,relatime,attr2,noquota 0 0
  #   /dev/sda1 /boot ext3 rw,relatime,errors=continue,data=ordered 0 0
  #   binfmt_misc /proc/sys/fs/binfmt_misc binfmt_misc rw,nosuid,nodev,noexec,relatime 0 0
  #

  # Make regular expression form our patterns ...
  exclude = Regexp.union(exclude.collect { |i| Regexp.new(i) })

  # List of numeric identifiers with their corresponding canonical forms ...
  known_devices = Dir['/dev/*'].inject({}) { |k,v| k.update(File.stat(v).rdev => v) }

  %x{ cat /proc/mounts 2> /dev/null }.each do |l|
    # Remove bloat ...
    l.strip!

    # Line of interest should not start with ...
    next if l.empty? or l.match(/^none/)

    # We have something, so let us apply our device type filter ...
    next if l.match(exclude)

    # At this point we split single and valid row into tokens ...
    row = l.split(' ')

    # Only device and mount point are of interest ...
    device = row[0].strip
    mount  = row[1].strip

    #
    # Correlate mount point with a real device that exists in the system.
    # This is to take care about entries like "rootfs" under "/proc/mounts".
    #
    device = known_devices.values_at(File.stat(mount).dev).shift || device

    # Add where appropriate ...
    mutex.synchronize do
      devices << device
      mounts  << mount
    end
  end

  Facter.add('devices') do
    confine :kernel => :linux
    setcode { devices.sort.uniq.join(',') }
  end

  Facter.add('mounts') do
    confine :kernel => :linux
    setcode { mounts.uniq.join(',') }
  end
end

# vim: set ts=2 sw=2 et :
