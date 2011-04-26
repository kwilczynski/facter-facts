#
# static_facts.rb
#
# Allows to expose any statically defined key-value pair as a Facter fact
# with the ability to include other files ...
#
# For example:
#
# Given the following content of /etc/facts.conf:
#
#   foo=bar
#   answer=42
#
# Then upon execution both "foo" and "answer" will be available as facts
# to use directly from within Facter.
#
# Another example concerns usage of the "include" directive which allows
# for including single file as well as group of files when a wild card
# pattern was introduced.  Any additional files which may act as a source
# of static facts should be preferably stored under /etc/facts.d/
# directory purely to maintain order and simplify management ...
#
# Given the following content of /etc/facts.conf:
#
#   foo=bar
#   include /etc/facts.d/answer.fact
#
# Where the content of /etc/facts.d/answer.fact is:
#
#   answer=42
#
# Then upon execution both "foo" and "answer" will be available as facts
# to use directly from within Facter.  In this case the "answer" fact
# was loaded from file "answer.fact" which was given as a parameter
# to the "include" directive.
#
# The "include" directive will accept wild cards in the file names
# therefore the following would also be valid:
#
#   include /etc/facts.d/*.fact
#   include ~/.facts.d/*.fact
#
# Each include file can have "include" directive in it but there
# is a limit to the level of recursion in order to stop infinite
# and/or circular recursion from happening ...
#
# This code was inspired by R. I. Pienaar's etc_facts.rb.
#

require 'thread'
require 'facter'

class StaticFact
  @@facts = {}
  @@mutex = Mutex.new
  @@maximum_recursion_level = 8 # Sane default? Hope so ...
  @@current_recursion_level = 0

  class << self
    def load_facts(file='/etc/facts.conf')
      parse_file(file) # Parse and load facts from the origin file ...
      @@facts
    end

    private
    def parse_file(file)
      # We cannot allow for endless recursion ...
      return if @@current_recursion_level > @@maximum_recursion_level
      return unless File.exists?(file)

      File.readlines(file).each do |line|
        next if line.match(/^#/)       # Skip comments if any ...
        next if line.match(/^\n|\r\n/) # Skip empty lines ...

        if match = line.match(/^include\s+(.+)$/)
          file  = File.expand_path(match[1].strip)
          files = Dir.glob(file) # Look for wild card pattern ...

          if files.size > 1
            #
            # When simple pattern was used to include more files then
            # we parse each and one of them but do not change current
            # recursion level.  We consider this a "flat include".
            #
            files.each { |f| parse_file(f) }
          else
            @@mutex.synchronize { @@current_recursion_level += 1 }
            parse_file(file) # Parse and load facts from an include file ...
          end
        elsif match = line.match(/^(.+)=(.+)$/)
          @@mutex.synchronize {
            @@facts.update({ match[1].strip => match[2].strip })
          }
        end
      end
    end
  end
end

facts = StaticFact.load_facts

facts.each do |name, value|
  Facter.add(name) do
    setcode { value }
  end
end

facts.clear # Remove all.  Schedule for garbage collection ...

# vim: set ts=2 sw=2 et :
