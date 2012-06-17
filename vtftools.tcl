#
# VTF Tools
#
# A plugin that provides tools to support users of the VTF file
# format.
#
# Author:
#   Olaf Lenz <olaf _at_ lenz.name>
#   Olaf Lenz <olenz _at_ icp _dot_ uni-stuttgart _dot_ de>
#
package provide vtftools 1.0
package require vtfplugin 2.1

namespace eval ::VTFTools:: {
    namespace export *

    variable userdata

    proc read_userdata { args } {
	set molid "top"
	set filename ""
	set type ""

	# Parse options
	for { set argnum 0 } { $argnum < [llength $args] } { incr argnum } {
	    set arg [ lindex $args $argnum ]
	    set val [ lindex $args [expr $argnum + 1]]
	    switch -- $arg {
		"-molid" { set molid $val; incr argnum; }
		default { set filename $arg; break }
	    }
	}
	if { $molid=="top" } then { set molid [ molinfo top ] }
	
	if  { $filename eq "" } then {
	    set filename [ molinfo $molid get filename ]
	    set type [ molinfo $molid get filetype ]
	}
	if  {$type ne "vtf" && $type ne "vcf" && $type ne "vsf" } then {
	    error "error: vtf_read_userdata: $filename is not a VTF/VCF/VSF file"
	}
	
	variable userdata
	vtf_parse_userdata $filename $type ::VTFTools::userdata $molid
    }

    proc load { filename } {
	set molid [mol new $filename]
 	read_userdata -molid $molid 
	return $molid
    }
}

proc vtf_read_userdata { args } {
    eval ::VTFTools::read_userdata $args
}

proc vtf_load { args } {
    ::VTFTools::load $args
}
