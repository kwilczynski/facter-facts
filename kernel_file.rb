#
# kernel_file.rb
#
# This fact provides information about file descriptors currently available on
# the system as follows: total allocated file descriptors since system power-up,
# total free file descriptors available for allocation and maximum available
# file descriptors (also known as "RLIMIT_NOFILE" which per-process and always
# lower than the constant "NR_OPEN" denoting Kernel enforced upper-limit) and
# which is probably the most useful piece of information in its own right ...
#

if Facter.value(:kernel) == 'Linux'
  #
  # We will pass Proc object for execution later inside "setcode" block.  This
  # should make caching of the results work nicely ...
  #
  result = Proc.new do
    #
    # Modern Linux kernels provide "/proc/sys/fs/file-nr" in the following format:
    #
    #    52832    0    1200077
    #
    # Where first number denotes total allocated file descriptors since
    # system power-up, second number shows total number of free file
    # descriptors available for allocation (and Linux Kernel will add
    # more on-demand as needed), and last number shows maximum available
    # file descriptors (same as the number in "/proc/sys/fs/file-max) ...
    #
    data = Facter::Util::Resolution.exec('cat /proc/sys/fs/file-nr 2> /dev/null')
    data.split(/\s+/)
  end

  # Total allocated file descriptors since system power-up ...
  Facter.add('kernel_file_total') do
    confine :kernel => :linux
    setcode { result.call[0] }
  end

  #
  # Total free file descriptors available for allocation (if exhausted,
  # then Linux Kernel will add more on-demand) ...
  #
  Facter.add('kernel_file_free') do
    confine :kernel => :linux
    setcode { result.call[1]}
  end

  #
  # Maximum available file descriptors that can be allocated.  This number
  # will be the same as what can be seen in "/proc/sys/fs/file-max" ...
  #
  Facter.add('kernel_file_max') do
    confine :kernel => :linux
    setcode { result.call[2] }
  end
end

# vim: set ts=2 sw=2 et :
# encoding: utf-8
