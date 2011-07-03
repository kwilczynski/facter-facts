#
# filesystems.rb
#

require 'thread'
require 'facter'

if Facter.value(:kernel) == 'Linux'

  mutex = Mutex.new

  filesystems = []

  %x{ cat /proc/filesystems 2> /dev/null }.each do |l|
    # Remove bloat ...
    l.strip!

    # Line of interest should not start with "nodev" ...
    next if l.empty? or l.match(/^nodev/)

    mutex.synchronize { filesystems << l }
  end

  Facter.add('filesystems') do
    confine :kernel => :linux
    setcode { filesystems.sort.join(',') }
  end
end

# vim: set ts=2 sw=2 et :
