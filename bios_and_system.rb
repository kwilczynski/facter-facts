require 'facter'
require 'facter/manufacturer'

#
# bios_and_system.rb
#

query = {
  'BIOS [Ii]nformation' => [
    { 'Vendor:'           => 'bios_vendor'            },
    { 'Version:'          => 'bios_version'           },
    { 'Release Date:'     => 'bios_release_date'      },
    { 'ROM Size:'         => 'bios_rom_size'          },
    { 'BIOS Revision:'    => 'bios_revision'          },
    { 'Firmware Revision' => 'bios_firmware_revision' }
  ],
  '[Ss]ystem [Ii]nformation' => [
    { 'Manufacturer:'     => 'system_manufacturer'  },
    { 'Product Name:'     => 'system_product_name'  },
    { 'Serial Number:'    => 'system_serial_number' },
    { 'UUID:'             => 'system_uuid'          },
    { 'Family(?: Name)?:' => 'system_family_name'   }
  ]
}

# We call existing helper function to do the heavy-lifting ...
Facter::Manufacturer.dmi_find_system_info(query)

# vim: set ts=2 sw=2 et :
# encoding: utf-8
