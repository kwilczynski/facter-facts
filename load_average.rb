#
# load_average.rb
#
# This fact provides information about the load average on the underlying
# system for last one, five and fifteen minutes; plus number of currently
# running processes and the total number of processes, and last process
# ID that was used recently.
#

if Facter.value(:kernel) == 'Linux'
  #
  # We utilise rely on "cat" for reading values from entries under "/proc".
  # This is due to some problems with IO#read in Ruby and reading content of
  # the "proc" file system that was reported more than once in the past ...
  #
  data = Facter::Util::Resolution.exec('cat /proc/loadavg 2> /dev/null').split(' ')

  #
  # Modern Linux kernels provide "/proc/loadavg" in the following format:
  #
  #    0.26 0.16 0.09 1/256 16384
  #
  # Where the first three columns represent CPU and IO utilisation for the
  # last one, five and fifteen minute time periods.  This utilisation refers
  # to the average number of processes that are either in a runnable or
  # uninterruptable state.  A process in runnable state is either using the
  # CPU (gets its slice of time) or waiting to use CPU time.
  #
  # The fourth column shows the number of currently running processes to the
  # total number of prcesses on the system.
  #
  # The fifth and the last column shows last process ID that was used.
  #

  # Extract currently running and total processes ...
  running_processes = data[3].split('/').first
  total_processes   = data[3].split('/').last

  # The one, five and fifteen minutes together ...
  Facter.add('load_average') do
    confine :kernel => :linux
    setcode { data[0,3].join(',') }
  end

  Facter.add('load_average_1') do
    confine :kernel => :linux
    setcode { data[0] }
  end

  Facter.add('load_average_5') do
    confine :kernel => :linux
    setcode { data[1] }
  end

  Facter.add('load_average_15') do
    confine :kernel => :linux
    setcode { data[2] }
  end

  Facter.add('running_processes') do
    confine :kernel => :linux
    setcode { running_processes }
  end

  Facter.add('total_processes') do
    confine :kernel => :linux
    setcode { total_processes }
  end

  Facter.add('last_pid') do
    confine :kernel => :linux
    setcode { data[4] }
  end
end

# vim: set ts=2 sw=2 et :
# encoding: utf-8
