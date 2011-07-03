#
# static_facts.rb
#
# Allows to expose any statically defined key-value pair as a Facter fact
# with the ability to include other files ...
#
# For example:
#
# Given the following content of /etc/facts.conf:
#
#   foo=bar
#   answer=42
#
# Then upon execution both "foo" and "answer" will be available as facts
# to use directly from within Facter.
#
# Another example concerns usage of the "include" directive which allows
# for including single file as well as group of files when a wild card
# pattern was introduced.  Any additional files which may act as a source
# of static facts should be preferably stored under /etc/facts.d/
# directory purely to maintain order and simplify management ...
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
# Worth noting is that we allow for single space before and after
# the equals sign i.e. "abc = def" to aid readability. But this
# is not recommended and should be rather avoided ...
#

require 'thread'
require 'facter'

class StaticFact

  @@mutex = Mutex.new

  # Sane default? Hope so ...
  @@maximum_recursion_level = 8
  @@current_recursion_level = 0

  @@facts = {}

  class << self
    def load_facts(file='/etc/facts.conf')
      # Just a fail-safe ...
      return unless File.exists?(file)

      # Parse and load facts from the origin file ...
      parse_file(file)
      @@facts
    end

    private

    def parse_file(file)
      directory = File.dirname(file)

      # We cannot allow for endless recursion ...
      return if @@current_recursion_level > @@maximum_recursion_level

      # Since we include different files we check whether they still exist ...
      return unless File.exists?(directory) or File.exists?(file)

      File.readlines(file).each do |l|
        next if l.match(/^#.*/)      # Skip comments if any ...
        next if l.match(/^\s*$/)     # Skip blank lines ...
        next if l.match(/^\n|\r\n$/) # Skip empty lines ...

        # Remove bloat ...
        l.strip!

        if match = l.match(/^include\s+(.+)$/)
          file = match[1].strip
          file = File.expand_path(file)

          # Look for wild card pattern ...
          files = Dir.glob(file)

          # There are no files to include ... so skip ...
          next if files.empty?

          if files.size > 1
            #
            # When simple pattern was used to include more files then
            # we parse each and one of them but do not change current
            # recursion level.  We consider this a "flat include".
            #
            files.each { |f| parse_file(f) }
          else
            @@mutex.synchronize { @@current_recursion_level += 1 }
            # Parse and load facts from an include file ...
            parse_file(file)
          end
        elsif match = l.match(/^(.+)\s?=\s?(.+)$/)
          # Since we allow spaces we have to clean it up a little ...
          name  = match[1].strip
          value = match[2].strip

          @@mutex.synchronize { @@facts.update(name => value) }
        end
      end
    end
  end
end

facts = StaticFact.load_facts

if facts
  facts.each do |name, value|
    Facter.add(name) do
      setcode { value }
    end
  end
end

# vim: set ts=2 sw=2 et :
