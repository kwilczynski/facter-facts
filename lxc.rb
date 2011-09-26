#
# lxc.rb
#
# This fact provides a way to determine whether underlying system is currently
# utilising Linux Containers (LXC) to host multiple light-weight containers.
#

require 'thread'
require 'facter'

if Facter.value(:kernel) == 'Linux'
  mutex = Mutex.new

  # We grab the class to use for any future calls to static "exec" method ...
  resolution = Facter::Util::Resolution

  # Most common approach to expose Control Groups via a file system mount ...
  mounts = %w(/cgroup /sys/fs/cgroup)

  #
  # Any particular host system can utilise either native LXC binaries like
  # "lxc-create" via the "liblxc" library or alternatively built containers
  # with "virsh" from the "libvirt" library, or even have both installed.
  #
  # Either way is sufficient for detection ...
  #
  binaries = %w(/usr/bin/lxc-create /usr/lib/libvirt/libvirt_lxc)

  # We capture whether it is a host system or a container here ...
  lxc = []

  # We capture details of Control Groups here ...
  cgroup = resolution.exec('cat /proc/1/cgroup 2> /dev/null')

  # Anything to do?  Control Group information available?
  if cgroup.size > 0
    #
    # First detection vector: check how Control Groups data looks like for
    # the "init" process (can actually be any process including "self") as
    # on the host system this may look like:
    #
    #   1:net_cls,freezer,devices,cpuacct,cpu,ns,cpuset:/
    #
    # Whereas from within a container this will look more alike:
    #
    #   1:net_cls,freezer,devices,cpuacct,cpu,ns,cpuset:/test
    #
    # Where "test" is an arbitrary name of the container.  Think about this
    # as if it were an indication of a separate name space ...
    #
    if cgroup.match(/^\d+:.+:\/$/)
      #
      # Second detection vector: check whether Control Groups mount point
      # is available and non-empty, plus whether we have certain binaries
      # present on the file system.  The combination of both would indicate
      # that system is operating as an Linux Containers (LXC) host ...
      #
      # A container should never have Control Groups available inside of it
      # as it would be a security risk, and it us uncommon for it to have
      # host-side packages installed ...
      #
      if mounts.collect { |mount| Dir.glob(File.join(mount, '*')).size > 0 }.any? \
         and binaries.collect { |binary| File.exists?(binary) }.any?

        mutex.synchronize do
          # We are a host system ...
          lxc = [false, 'host']
        end
      end
    elsif cgroup.match(/^\d+:.+:\/.+$/)
      #
      # Third detection vector: check whether current system is a container.
      # This can be done by looking at environment variables that the "init"
      # process was given during the initialisation.  Said variables will
      # differ depending on whether a container was brought to life by native
      # Linux Containers (LXC) user-space utilities such as "lxc-start" via
      # the "liblxc" library or by "virsh" from the "libvirt" library.
      #

      # We capture whether system is a container or not here ...
      container = false

      # Parse and process "init" process environment variables ...
      resolution.exec('cat /proc/1/environ 2> /dev/null').split("\000").each do |line|
        # Remove bloat ...
        line.strip!

        # Process environment variable one by one ...
        case line
        when /^container=.+$/
          # Get the value and therefore type of the container only ...
          type = line.split('=').last

          #
          # Native Linux Containers utilities will set "container=lxc" whereas
          # "virsh" via the "libvirt" will set either "container=libvirt-lxc"
          # or "container=libvirt".  Although, no case of "libvirt" setting
          # "container" to "libvirt-lxc" was seen so far ...
          #
          if %w(lxc libvirt-lxc libvirt).include?(type)
            container = true
            break
          end
        #
        # Almost all recent versions of "libvirt" will only set this ...
        #
        # Format is as follows:
        #
        #  LIBVIRT_LXC_UUID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
        #  LIBVIRT_LXC_NAME=YYYYYYYYYYYY
        #
        when /^LIBVIRT_LXC_(?:UUID|NAME)=.+$/
          container = true
          break
        else
          # Skip irrelevant entries ...
          next
        end
      end

      # Linux Containers (LXC) container at all?
      if container
        mutex.synchronize do
          # We are a container ...
          lxc = [true, 'container']
        end
      end
    end

    # All set?  Can we safely populate facts with values?
    unless lxc.empty?
      Facter.add('lxc_container') do
        confine :kernel => :linux
        setcode { lxc.first }
      end

      Facter.add('lxc_type') do
        confine :kernel => :linux
        setcode { lxc.last }
      end
    end
  end
end

# vim: set ts=2 sw=2 et :
