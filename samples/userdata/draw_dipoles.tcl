#Guidance instructions
#
#first open a vtf-file with extra user information containig the dipole informations
#
#after you have loaded these molecule informations generate a construction plan 
#by typing "set bauplan [halfspere top]", "set bauplan [twosphere top]", "set bauplan [doublecone top]" 
#or "set bauplan [arrow top]"
#now all information neccessary to create a basic shape for your dipoles is stored in "bauplan"
#
#next use the command "overwrite_atoms top 2 $sel $bauplan" to place at each atom position the shape you have 
#choosen for your dipoles. 
#top und 2 sind hierbei die identifikatoren der beiden geladenen molek�le
#
#If you now click at a vmd frame control button (for example next frame) this scipt will automatically load the
#new location and orientation for each Atom and replace it.
#
#Achtung das Program pr�ft noch gar nichts es ist also sehr warscheinlich das irgendwo ein fehler auftrritt 
#wenn etwas nicht passt



#twosphere gernerates as it is named two spheres with two different colors. 
#These two spheres are shifted by a very small distance in x-direction, so that they appear as one two-colored
#sphere
proc twosphere {mol} {
	set part_list "{graphics $mol color 0} {graphics $mol sphere {-0.1 0 0} radius 1} {graphics $mol color 1} {graphics $mol sphere {0.1 0 0} radius 1}"
	#returns part_list which contains the vmd commands to create the two spheres
	return $part_list
}

#doublecone creates two different colored cones which touch each other at their bottoms.
#The top's of the cones are pointing in x-direction
proc doublecone {mol} {
	set part_list "{graphics $mol color 0} {graphics $mol cone {0 0 0} {-1 0 0} radius 1} {graphics $mol color 1} {graphics $mol cone {0 0 0} {1 0 0} radius 1}"
	return $part_list
}
#arrow creates an arrow built up from a small cone and a long, thin cylinder.
#the arrow points in x-direction
proc arrow {mol} {
	set part_list "{graphics $mol cone {0.5 0 0} {1 0 0} radius 0.25} {graphics $mol cylinder {-1 0 0} {0.5 0 0} radius 0.1}"
	return $part_list
}

#places one single subobject unsing a transrot_matrix
proc place_object_part {mol id plan transrot_matrix} {
	set i 0
	set new_element [list ]
	foreach old_element $plan {
		if {$i <= 2} {
			#for the first 3 entries in the subobject's construction plan just copy them to the new construction plan
			lappend new_element $old_element
		} else {
			#check the following entries for a vector
			#if it is a vector, transform the first 3 vectors translational and rotational
			#and all following transform only rotational
			#note: if the object is a text object which contains exactly 3 Words this procedure will missinterpret this object
			if {[llength $old_element] == 3} {
				if {$i > 2 && $i<=5} {
					#rotate and translate
					lappend new_element [coordtrans $transrot_matrix $old_element]
				} else {
					#only rotate
					lappend new_element [vectrans $transrot_matrix $old_element]
				}
			} else {
				#for last information entries just copy to the new object
				lappend new_element $old_element
			}
		}
		incr i
	}
	#finally remove old subobject...
	graphics $mol replace $id
	#and replace it with the new transformed subobject
	eval $new_element
}

#this procedure places one dipole object into the right position and orientation
proc place_object {mol id_list construction_plan position orientation} {
	#built up an 4x4 matrix which contains the translational shift
	set position [list [list 0 0 0 [lindex $position 0]] [list 0 0 0 [lindex $position 1]] [list 0 0 0 [lindex $position 2]] [list 0 0 0 0]]
	#create a 4x4 matrix which turns the dipole object from its x-axis orientation into the pointing orientation
	#saved in "orientation"
	set orientation [transvec $orientation]
	set transrot_matrix [list ]
	#combine translational and rotational matrix by adding the elements
	foreach pos $position ori $orientation {
		lappend transrot_matrix [vecadd $pos $ori]
	}
	set i 0
	#translate and rotate each subobject from a dipole object unsing the new transrot_matrix
	foreach id $id_list {
		place_object_part $mol $id [lindex $construction_plan $i] $transrot_matrix
		incr i
	}
}

#this procedure creates an dipol representation at the origin with no turning
proc create_object {construction_plan} {
	set id_list [list ]
	foreach part $construction_plan {	
		lappend id_list [eval $part]
	}
	#after successfull creation of the objects of one dipole representation the return will be an id list
	#of all sub objects which are neccessary to build the representation
	return $id_list
}

# Overwrite_atoms uses the atom positions to place the dipole objects
# which are defined by "dipol_plan". Overwrite_atoms also reads the
# user data from the vtf file which contains information about the
# dipole orientation to turn the dipolobjects correctly.
proc overwrite_atoms {mol dipol_plan} {
	if { $mol eq "top" } then { set mol [molinfo top] }
	upvar #0 vtf_userdata userdata
	#get atom information
	set sel [uplevel #0 atomselect $mol all]
	#get the dipol orientation, at the moment the procedure uses a second file to transfer diplolinformation
	set selo $sel
	#get the total nuber of atoms
	set number [$sel num]
	#get dipol positions
	set positions [$sel get {x y z}]
	#get dipol orientations
	set frame [molinfo $mol get frame]
	for {set atom 0} {$atom < $number} {incr atom} {
		lappend orientations $userdata($mol.step$frame.$atom)
	}
	#listlist contains, every information neccessary to describe the whole dipole visualization
	#the first entry in listlist is the application plan, for the objects
	set listlist [list $dipol_plan]
	#this loop creates for each atom a dipole representation and turns and places it to the right possition
	for {set i 0} {$i < $number} {incr i} {
		#create one representation at the origin with no turning. save the object id's of this representation
		set id_list [create_object $dipol_plan]
		#now relocate this new object to the position and orientatioin of one dipole
		place_object $mol $id_list $dipol_plan [lindex $positions $i] [lindex $orientations $i]
		#append the object id's to listlist 
		lappend listlist $id_list
	}
	#this will make vmd call the procedure renew_atompos each time the actual frame gets changed
	#that means if you play the animation, the dipole representations will follow the vmd representation's
	#animation
	trace add variable ::vmd_frame write [list renew_atompos $mol $sel $listlist]
}

#renew_atompos is a procedure which is calles automatically by vmd each time the actual frame gets changed
#this procedure then moves all objects which are representing the dipoles to their new possitions and orientations
#the arguments varname, element and op where sent from vmd's autocall by standard. They will be ignored in this procedure
proc renew_atompos {mol sel listlist varname element op} {
	if { $mol eq "top" } then { set mol [molinfo top] }
	upvar #0 vtf_userdata userdata
	#get the number of atoms
	set number [$sel num]
	#extract the assembly plan from listlist
	set dipol_plan [lindex $listlist 0]
	#delete the assembly plan from listlist, so it contains only the object id's
	#each representation consists of a list of object id's inside the list "listlist"
	set listlist [lreplace $listlist 0 0]
	#get the new positions
	set positions [$sel get {x y z}]
	#get the new orientations
	#set orientations [$selo get {x y z}]
	set frame [molinfo $mol get frame]
	for {set atom 0} {$atom < $number} {incr atom} {
		lappend orientations $userdata($mol.step$frame.$atom)
	}
	#move each dipole to its new place
	for {set i 0} {$i < $number} {incr i} {
		place_object $mol [lindex $listlist $i] $dipol_plan [lindex $positions $i] [lindex $orientations $i]
	}
}

#*************************************************************************************************************
#the follwoing is no more important for this script but left here for completition

#halphsphere creating two different colared halfspheres using a Icosahedron shape and subdividing the triagles
#into more smaler triangles. This helps to round the surface of the icosahedron that it gets close to a sphere.
#see more about under http://fly.cc.fer.hr/~unreal/theredbook/chapter02.html
proc halfsphere {mol} {
	#Parameters of the golden ratio normed to a vector length of 1
	set X .525731112119133606
	set Z .850650808352039932
	#resolution means the number of calls to the subdevide function e.g. resolution=2 a triangle will be 
	#subdevided into 16 smaller triangles, resolution =3 they become 64 triangles
	#so be carefully with the resolution setting
	set resolution 1
	#set the two colors of the sphere as rgb colors
	set col1 [list 1.0 0.0 0.0]
	set col2 [list 0.0 1.0 0.0]
	#to get a linear color crossover calculate the number of neccessary sub-colors
	set last_color [expr {2 ** $resolution}]
	#create all colors
	for {set i 0} {$i <= $last_color} {incr i} {
		set eins [expr { ($last_color - double($i)) / $last_color}]
		set zwei [expr {double($i) / $last_color}]
		set sub_color [vecadd [vecscale $eins $col1] [vecscale $zwei $col2]]
		color change rgb $i [lindex $sub_color 0] [lindex $sub_color 1] [lindex $sub_color 2]
	}	
	set c1 0
	set c2 $last_color
	set id_list [list ]
	set part_list [list ]
	#set cornor points of icosahedron
	set corner [list [list -$X 0 $Z] [list $X 0 $Z] [list -$X 0 -$Z] [list $X 0 -$Z] [list 0 $Z $X] [list 0 $Z -$X] [list 0 -$Z $X] [list 0 -$Z -$X] [list $Z $X 0] [list -$Z $X 0] [list $Z -$X 0] [list -$Z -$X 0]]
	#set the main colors at this cornor points
	set corner_color [list $c2 $c1 $c2 $c1 $c1 $c1 $c2 $c2 $c1 $c2 $c1 $c2]
    #set the conections of the cornor points to get icosahedron
	set triple [list {0 1 4} {0 4 9} {9 4 5} {4 8 5} {4 1 8} {8 1 10} {8 10 3} {5 8 3} {5 3 2} {2 3 7} {7 3 10} {7 10 6} {7 6 11} {11 6 0} {0 6 1} {6 10 1} {9 11 0} {9 2 11} {9 5 2} {7 11 2}]
	#for each triangle call the subdivide fuction which then creates the vmd commands to build a triangle
	#if resolution is grater than 0 the subdevide function will begin to call itself. The output will be, in any case,
	#a list of vmd graphic commands
	foreach t $triple {
		set t0 [lindex $t 0]
		set t1 [lindex $t 1]
		set t2 [lindex $t 2]
		set color_tripel [list [lindex $corner_color $t0] [lindex $corner_color $t1] [lindex $corner_color $t2]]
		set list0 [subdivide $mol [lindex $corner $t0] [lindex $corner $t1] [lindex $corner $t2] $color_tripel $resolution]
		set part_list [concat $part_list $list0]
	}
	#return the list of graphic comands which are neccesary to build a to colored sphere in vmd
	return $part_list
}

#subdivide is a procedure to divide a triangle into 4 smaller triangles
#Due to subdivide is a recursive procedure, it can call itselve a few times until the wanted detail level is reached
#subdevide is specialized to round the surface of a sphere around the origin
proc subdivide {mol kt1 kt2 kt3 color_tripel depth} {
	if {$depth == 0} {
		#generates the vmd code for one (colored) triangle, 
		set part_code "graphics $mol tricolor [list $kt1] [list $kt2] [list $kt3] [list [vecnorm $kt1]] [list [vecnorm $kt2]] [list [vecnorm $kt3]] $color_tripel"
		#send these commands back to the calling procedure "halfsphere"
		return [list $part_code]
	}
	#if depth is unequal zero begin to subdevide
	#devide each triangle into 4 equal smaller triangles, and norm their vectors to the origin, so that the resulting shape
	#becomes more and more a sphere
	#note that thats also the reason why this sphere can only created around the origin, and has to be of an radius of 1
	set kt1 [vecnorm $kt1]
	set kt2 [vecnorm $kt2]
	set kt3 [vecnorm $kt3]
	set kt12 [vecnorm [vecadd $kt1 $kt2]]
	set kt23 [vecnorm [vecadd $kt2 $kt3]]
	set kt31 [vecnorm [vecadd $kt3 $kt1]]
	#average the color between each two corners of the triangle
	set c1 [lindex $color_tripel 0]
	set c2 [lindex $color_tripel 1]
	set c3 [lindex $color_tripel 2]
	set subcolor_tripel [list $c1 [expr {int(($c1 + $c2) / 2)}] [expr {int(($c3 + $c1) / 2)}]]
	#decrement depth and recall for each new triangle the subdivide function. If depth gets to zero subdevide will
	#only return the vmd for building this triangle
	set list1 [subdivide $mol $kt1 $kt12 $kt31 $subcolor_tripel [expr {$depth-1}]]
	set subcolor_tripel [list $c2 [expr {int(($c2 + $c3) / 2)}] [expr {int(($c1 + $c2) / 2)}]]
	set list2 [subdivide $mol $kt2 $kt23 $kt12 $subcolor_tripel [expr {$depth-1}]]
	set subcolor_tripel [list $c3 [expr {int(($c3 + $c1) / 2)}] [expr {int(($c2 + $c3) / 2)}]]
	set list3 [subdivide $mol $kt3 $kt31 $kt23 $subcolor_tripel [expr {$depth-1}]]
	set subcolor_tripel [list [expr {int(($c1 + $c2) / 2)}] [expr {int(($c2 + $c3) / 2)}] [expr {int(($c3 + $c1) / 2)}]]
	set list4 [subdivide $mol $kt12 $kt23 $kt31 $subcolor_tripel [expr {$depth-1}]]
	return [concat $list1 $list2 $list3 $list4]
}
