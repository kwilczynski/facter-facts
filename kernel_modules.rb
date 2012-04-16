#
# kernel_modules.rb
#
# This fact provides an alphabetic list (and a total count) of Linux Kernel
# modules that are currently loaded and are in the "live" state.
#

require 'facter'

if Facter.value(:kernel) == 'Linux'
  #
  # We will pass Proc object for execution later inside "setcode" block.  This
  # should make caching of the results work nicely ...
  #
  result = Proc.new do
    # We store list of *live* modules and count how many we have ...
    modules_list  = []
    modules_count = 0

    # Both paths should be available from given location in 99% of cases ...
    proc_modules      = '/proc/modules'
    modules_directory = '/sys/module'

    #
    # We check "/proc/modules" first, but in some circumstances it might be
    # missing from under the "/proc" tree.  For instance when Linux VServer
    # is in use, or when some sort of MAC and/or RBAC layer is denying us
    # access, etc.  If such will be the case, then we resort to enumerating
    # "/sys/mogule" directory ...
    #
    if File.exists?(proc_modules)
      #
      # Modern Linux kernels provide "/proc/modules" in the following format:
      #
      #    ...
      #    binfmt_misc 17498 1 - Live 0x0000000000000000
      #    bridge 81986 0 - Live 0x0000000000000000
      #    dm_crypt 22872 0 - Live 0x0000000000000000
      #    ...
      #

      #
      # We utilise rely on "cat" for reading values from entries under "/proc".
      # This is due to some problems with IO#read in Ruby and reading content of
      # the "proc" file system that was reported more than once in the past ...
      #
      Facter::Util::Resolution.exec("cat #{proc_modules} 2> /dev/null").each_line do |line|
        # Remove bloat ...
        line.strip!

        # Skip new and empty lines ...
        next if line.match(/^(\r\n|\n|\s*)$|^$/)

        # We are only interested in modules that are loaded at the moment ...
        modules_list << line.split.first if line.match(/^\w+\s.+[Ll]ive.+$/)
      end
    elsif File.exists?(modules_directory)
      #
      # Modern Linux kernels provide each of the entries residing inside the
      # "/sys/module" directory resembling the following structure:
      #
      #    ...
      #     +-- binfmt_misc
      #     |   +-- holders
      #     |   +-- initstate
      #     |   +-- notes
      #     |   +-- refcnt
      #     |   +-- sections
      #     |   |   +-- __mcount_loc
      #     |   `-- srcversion
      #     +-- dm_crypt
      #     |   +-- holders
      #     |   +-- initstate
      #     |   +-- notes
      #     |   +-- refcnt
      #     |   +-- sections
      #     |   |   +-- __bug_table
      #     |   |   `-- __mcount_loc
      #     |   `-- srcversion
      #    ...
      #

      # Enumerating "/sys/module" directory and picking each name one by one ...
      Dir.entries(modules_directory).each do |name|
        # Skip irrelevant entries ...
        next if ['.', '..'].include?(name)

        # Concatenate a path to be: "/sys/module/<MODULE NAME>/initstate" ...
        directory  = File.join(modules_directory, name)
        state_file = File.join(directory, 'initstate')

        #
        # As of Linux Kernel 2.6.20 the "initstate" file is available to check
        # for the current state of the module of interest.  It does reflect the
        # same set of states as what can be seen in "/proc/modules", and we are
        # interested only in modules that are loaded (or "live" if you wish) ...
        #
        if File.exists?(state_file)
          modules_list << name if File.read(state_file).match(/^[Ll]ive/)
        end
      end
    end

    #
    # No modules or blocked, or we cannot get any results whatsoever?  Then
    # simply assume that we don't know and/or have anything ...
    #
    if modules_list.empty?
      modules_list << 'none'
      modules_count = 0
    end

    # Return out findings or "none" and "0" ...
    [modules_list, modules_count]
  end

  Facter.add('kernel_modules') do
    confine :kernel => :linux
    setcode do
      modules = result.call.first
      modules.sort.join(',')
    end
  end

  Facter.add('kernel_modules_count') do
    confine :kernel => :linux
    setcode { result.call.last }
  end
end

# vim: set ts=2 sw=2 et :
# encoding: utf-8
