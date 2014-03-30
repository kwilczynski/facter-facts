#
# connections.rb
#
# This fact provides information about number of current TCP connections (or
# sockets if you wish) in the following states: ESTABLISHED, TIME_WAIT,
# CLOSE_WAIT and LISTEN; which are the most common known states ...
#

if Facter.value(:kernel) == 'Linux'
  # We store number of connections of each type here ...
  connections = { :established => 0,
                  :time_wait   => 0,
                  :close_wait  => 0,
                  :listen      => 0 }

  #
  # Modern Linux kernels provide "/proc/net/tcp" in the following format:
  #
  #  sl  local_address rem_address   st tx_queue rx_queue tr tm->when retrnsmt   uid  timeout inode
  #   0: 017AA8C0:0035 00000000:0000 0A 00000000:00000000 00:00000000 00000000     0        0 12229 1 00000000 300 0 0 2 -1
  #   1: 00000000:0016 00000000:0000 0A 00000000:00000000 00:00000000 00000000     0        0 7708 1 00000000 300 0 0 2 -1
  #   2: 4200000A:0016 3200000A:837A 01 00000000:00000000 02:0006835A 00000000     0        0 14111 2 00000000 20 4 29 4 -1
  #   3: 4200000A:0016 3200000A:96D2 01 00000000:00000000 02:000AFD06 00000000     0        0 19945 4 00000000 20 4 31 4 -1
  #
  # We only require "st" or "state" field to determine in which state a particular
  # connection (or socket if you wish) is in currently:
  #
  #  00, and FF (a bad state which is impossible to achieve)
  #  01 - ESTABLISHED
  #  02 - SYN_SENT
  #  03 - SYN_RECV
  #  04 - FIN_WAIT1
  #  05 - FIN_WAIT2
  #  06 - TIME_WAIT
  #  07 - CLOSE
  #  08 - CLOSE_WAIT
  #  09 - LAST_ACK
  #  0A - LISTEN
  #  0B - CLOSING (not a valid state)
  #
  # But only "01", "06", "08" and "0A" are of interest to us ...
  #

  #
  # We utilise rely on "cat" for reading values from entries under "/proc".
  # This is due to some problems with IO#read in Ruby and reading content of
  # the "proc" file system that was reported more than once in the past ...
  #
  Facter::Util::Resolution.exec('cat /proc/net/tcp 2> /dev/null').each_line do |line|
    # Remove bloat ...
    line.strip!

    # Skip header line ...
    next if line.match(/^.+local_address.+/)

    # Skip new and empty lines ...
    next if line.match(/^(\r\n|\n|\s*)$|^$/)

    # Process line and retrieve state of the connection ...
    state = line.split(' ')[3].strip

    #
    # Convert from a hexadecimal value to an integer where 01 is obviously 1,
    # 06 is 6, 08 is 8 and 0A is 10.  This is purely for performance ...
    #
    case state.hex
    when 1
      connections[:established] += 1
    when 6
      connections[:time_wait] += 1
    when 8
      connections[:close_wait] += 1
    when 10
      connections[:listen] += 1
    else
      # Skip irrelevant states ...
      next
    end
  end

  connections.each do |k,v|
    Facter.add("connections_#{k.to_s}") do
      confine :kernel => :linux
      setcode { v.to_s }
    end
  end
end

# vim: set ts=2 sw=2 et :
# encoding: utf-8
