# META NAME xglob
# META DESCRIPTION pure data (pd) plugin - list a folder content 
# META AUTHOR <Lazzaro Ciccolella> lazzarocicco@gmail.com

package require Tcl 8.5
#package require Tk # don't have a gui
#package require pdwindow 0.1 # don't have interaction with pd gui 
set serverport 4000

# glob-plugin found a file with a space inside its name, what should it do?
set spaceinfile "rename_file"
# There are three options for the "spaceinfile" variable:
# 1) "rename_file" deletes the file with the old name and creates an identical one, puts the "_" character in place of the space.
# 2) "copy_file" leaves the original file, not including it in the list, and creates a copy with the "_" character instead of the space. That copy is included in the list.
# 3) "ignore_file" ignores the file and does not include it in the list.

puts "----------xglob-plugin---------"
puts "xglob-plugin is a pure data (pd) plugin."
puts "lazzaro Ciccolella 2020 marrongiallo.github.io"
puts "to use me open help -> browser -> externals -> xglob_request-help.pd"
puts "----------xglob-plugin---------"

proc globfilepath {namefile tipofile sock} {
	set pathfolder [file dirname $namefile]
	set listall [glob -directory $pathfolder *]
	set solowav [lsearch -all -inline [nospaced_list $listall] *.$tipofile*]
	set listTosend [linsert $solowav 0 "wavlist"]
#	puts "procselected globfilepath: reuslt->  $listTosend"
	#non commentare o cancellare l'istruzione che segue non serve a scrivere nel terminale ma a scrivere nel socket
	puts $sock "$listTosend\n;"
	#
}

proc nospaced_list {glob_all_list} {
        set  list_nospaces {}
        foreach item_list $glob_all_list {
                if {[llength $item_list] > 1} {
                        #puts "\ncon spazi detected:  $item_list\n"
                        switch $::spaceinfile {
                                "rename_file" {
                                        file rename -force $item_list [string map {" " "_"} $item_list]
                                        lappend list_nospaces $item_list
                                }
                                "copy_file" {
                                        file copy -force $item_list [string map {" " "_"} $item_list]
                                        lappend list_nospaces $item_list
                                }
                                "ignore_file" {
                        }
                }
                } else {
                        lappend list_nospaces $item_list
                }
        }
        return $list_nospaces
}


proc reply {sock msg} {
	# internal     puts  "[string trimleft [string trimright $msg "\n;"] exemplary]"
	# to pd     puts $sock "[string trimleft [string trimright $msg "\n;"] exemplary];"
}
proc switchrequest {sock} {
	set fromPd [gets $sock]
		if {[eof $sock]} {
			close $sock
		} else {
			set semicolonremoved [string trimright $fromPd ";"]
			set parse_args [split $semicolonremoved  " "]
			set first_arg [lindex $parse_args 0]
			set second_arg [lindex $parse_args 1]
				switch $first_arg {
					ggg -
					hhh {
						puts "non può essere"
						}
					globfilepath {
						#puts "ok"
						switch $second_arg {
							"wav" {
								globfilepath [string trimleft $semicolonremoved "globfilepath $second_arg "] $second_arg $sock
								}
							default {
								puts "default"
								}
						}
					}
					default {
						puts "default"
						}
				}
				#reply $sock $fromPd
		}
}
proc accept {sock addr port} {
	fileevent $sock readable [list switchrequest $sock]
	fconfigure $sock -buffering line -blocking 0
}

socket -server accept $serverport
vwait events
