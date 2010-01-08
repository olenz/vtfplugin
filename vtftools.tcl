#
# VTF Tools 1.0
#
# A plugin that provides tools to support users of the VTF file
# format.
#
# Author:
#   Olaf Lenz <olaf _at_ lenz.name>
#
# $Id$
#
package provide vtftools 1.0
package require vtfplugin 2.0

namespace eval ::VTFTools:: {
    namespace export vtf_*

    proc vtf_read_userdata { args } {
	set molid "top"
	set filename ""
	set type ""

	# Parse options
	for { set argnum 0 } { $argnum < [llength $args] } { incr argnum } {
	    set arg [ lindex $args $argnum ]
	    set val [ lindex $args [expr $argnum + 1]]
	    switch -- $arg {
		"-molid" { set molid $val; incr argnum; }
		default { error "error: vtf_read_userdata: unknown option: $arg" }
	    }
	    if { $molid=="top" } then { set molid [ molinfo top ] }

	    if  { $filename eq "" } then {
		set filename [ molinfo $molid get filepath ]
		set type [ molinfo $molid get filetype ]
	    }

	    if  {$type ne "vtf" && $type ne "vcf" && $type ne "vsf" } then {
		error "error: vtf_read_userdata: $filename is not a VTF/VCF/VSF file"
	    }

	    vtf_parse_userdata $filename $type $molid
	}
    }

#     proc vtf_load { filename } {
# 	vtf_read_userdata $filename $type 
#     }
}
