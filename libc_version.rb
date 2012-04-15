#
# libc_version.rb
#
# This fact provides information about version and variant of the GNU C
# Library (also known as "glibc", or just as simply by "libc" nowadays)
# which is currently available and/or was selected to be used for current
# runtime environment ...
#
# We assume that version which "ldd" returns is the same as the relevant
# GNU C Library.  This is because "ldd" in most cases is a part of (or
# should be) correctly built tool-chain ...
#
# The case for using "ldd" is sensible only when the library itself and/or
# relevant symbolic link is missing from the "/lib" directory, which might
# indicate that system is already utilising "multiarch" architecture ...
#
# Please note, that at this point in time there is no support for uClibc ...
#

require 'facter'

if Facter.value(:kernel) == 'Linux'
  # We grab the class to use for any future calls to static "exec" method ...
  resolution = Facter::Util::Resolution

  #
  # We will pass Proc object for execution later inside "setcode" block.  This
  # should make caching of the results work nicely ...
  #
  result = Proc.new do
    # Both "libc" and "ldd" are on available from given locations in 99% of cases ...
    libc_library = '/lib/libc.so.6'
    ldd_binary   = '/usr/bin/ldd'

    # We set defaults in case we cannot resolve relevant values ...
    version = 'unknown'
    variant = 'unknown'

    if File.exists?(libc_library)

      # In 99.9% of cases "/lib/libc.so.6" will be a symbolic link, and we resolve ...
      if File.symlink?(libc_library)
        libc_library = File.readlink(libc_library)
        libc_library = File.join('/lib/', libc_library)
      end

      #
      # Assuming that "libc" has executable bit set, then we run it and parse
      # results where only fist line is what matters as it has the version and
      # variant we are after.  For instance, classic GNU C Library:
      #
      #   GNU C Library stable release version 2.12.2, by Roland McGrath et al.
      #
      # And the Embedded GLIBC (EGLIBC) variant:
      #
      #   GNU C Library (EGLIBC) stable release version 2.10.1, by Roland McGrath et al.
      #
      header = resolution.exec("#{libc_library} 2> /dev/null")
      header = header.split(/\n/).first

      # Parse version and set variant ...
      if match = header.match(/^GNU\sC.+\s\(E.+\).+\s([\d\.]+)\S/)
        version = match[1]
        variant = :eglibc
      elsif match = header.match(/^GNU\sC.+\s([\d\.]+)\S/)
        version = match[1]
        variant = :glibc
      end
    elsif File.exists?(ldd_binary)

      #
      # When using results of "ldd --version", only fist line is what matters
      # as it has the version and variant we are after.  For instance, classic
      # GNU C Library:
      #
      #   ldd (GNU libc) 2.12.2
      #
      # And the Embedded GLIBC (EGLIBC) variant:
      #
      #   ldd (EGLIBC) 2.10.1
      #
      header = resolution.exec("#{ldd_binary} --version 2> /dev/null")
      header = header.split(/\n/).first

      # Parse version and set variant ...
      if match = header.match(/^ldd\s\(E.+\)\s([\d\.]+)\S?/)
        version = match[1]
        variant = :eglibc
      elsif match = header.match(/^ldd\s\(G.+\)\s([\d\.]+)\S?/)
        version = match[1]
        variant = :glibc
      end
    end

    # Return our findings or "unknown" ...
    [version, variant]
  end

  Facter.add('libc_version') do
    confine :kernel => :linux
    setcode { result.call.first }
  end

  Facter.add('libc_variant') do
    confine :kernel => :linux
    setcode { result.call.last.to_s }
  end
end

# vim: set ts=2 sw=2 et :
# encoding: utf-8
