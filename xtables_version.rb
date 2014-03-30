#
# xtables_version.rb
#
# This fact provides version of the user-space utilities like "iptables",
# "ip6tables", "ebtables" and "arptables" when present.  All these tools
# interact with modern Linux Kernel and its firewall called Netfilter (the
# kernel-space component) and work either in Layer 2 and/or Layer 3 OSI
# networking model ...
#
# Known utilities, their names and short description:
#
#   iptables  - "Administration tool for IPv4 packet filtering and NAT",
#   ip6tables - "IPv6 packet filter administration",
#   ebtables  - "Ethernet bridge frame table administration",
#   arptables - "ARP table administration";
#

if Facter.value(:kernel) == 'Linux'
  # We grab the class to use for any future calls to static "exec" method ...
  resolution = Facter::Util::Resolution

  #
  # Modern Linux distributions offer "iptables", "ip6tables", "ebtables" and
  # "arptables" binaries from under the "/sbin" directory.  Therefore we will
  # simply use "/sbin/iptables" (similarly for "ebtables", etc ...) when asking
  # for the software version ...
  #

  # We work-around an issue in Facter #10278 by forcing locale settings ...
  ENV['LC_ALL'] = 'C'

  # Both "iptables" and "ip6tables" will have the same version in 99% of cases ...
  if File.exists?('/sbin/iptables')
    Facter.add('iptables_version') do
      confine :kernel => :linux
      setcode do
        version = resolution.exec('/sbin/iptables -V 2> /dev/null').strip
        version.split(/\s+v?/)[1]
      end
    end
  end

  if File.exists?('/sbin/ip6tables')
    Facter.add('ip6tables_version') do
      confine :kernel => :linux
      setcode do
        version = resolution.exec('/sbin/ip6tables -V 2> /dev/null').strip
        version.split(/\s+v?/)[1]
      end
    end
  end

  if File.exists?('/sbin/ebtables')
    Facter.add('ebtables_version') do
      confine :kernel => :linux
      setcode do
        version = resolution.exec('/sbin/ebtables -V 2> /dev/null').strip
        version.split(/\s+v?/)[1]
      end
    end
  end

  #
  # Worth noting is that "arptables" will complain for non-root users but
  # even despite that we can still retrieve its version ...
  #
  # When it complains the output will resemble the following format:
  #
  #   arptables v0.0.3.4: can't initialize arptables table `filter': Permission denied (you must be root)
  #   Perhaps arptables or your kernel needs to be upgraded.
  #
  if File.exists?('/sbin/arptables')
    Facter.add('arptables_version') do
      confine :kernel => :linux
      setcode do
        version = resolution.exec('/sbin/arptables -V 2>&1').split('\n')[0]
        version.split(/\s+v?/)[1].sub(':', '')
      end
    end
  end
end

# vim: set ts=2 sw=2 et :
# encoding: utf-8
