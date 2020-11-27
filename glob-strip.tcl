package require Tcl 8.5
package require Tk
set serverport 4000
##gui part
set res_w  [winfo screenwidth .]
set res_h  [winfo screenheight .]
set w_app 240
set h_app 400

set west_distance [expr $res_w - 1100]

frame .finestra
pack .finestra -fill both -expand 1

label .finestra.titolo -image [image create photo ddd -file "topbar.png"]
pack .finestra.titolo -fill x
frame .finestra.corpo -bg red
pack .finestra.corpo -padx 4 -expand 1 -fill both
label .finestra.corpo.lcl -textvariable msgcl -bg white
pack .finestra.corpo.lcl -pady 4 -padx 2 -fill x
label .finestra.corpo.lsr -textvariable msgsr -bg white
pack .finestra.corpo.lsr -pady 4 -padx 2 -fill x

wm attributes . -type splash -topmost true
### molto interessante si mette sul fondo (il contrario di topmost)
### wm attribute . -type desktop

#con lo schermo unico (due schermi come uno) non si posiziona al centro
#wm geometry . $w_app\x$h_app\+$ddd\+[expr $res_h - $h_app]
## per il momento hradcodiamo a metà dello schermo di destra
wm geometry . $w_app\x$h_app\+$west_distance\+[expr $res_h - $h_app]
bind . <Escape> {exit}
#bind . <Key> {puts "You pressed the key called \"%K\""}

##end gui part

puts "----------glob-strip---------"
puts "lazzaro Ciccolella 2020 marrongiallo.github.io"
puts "to use with pure data open the companion abstraction help -> browser -> externals -> glob_request-help.pd"
puts "----------glob-strip---------"

proc switchrequest {sock} {
	set fromPd [gets $sock]
		if {[eof $sock]} {
			close $sock
		} else {
		set action [lindex [pd $fromPd] 0]
                        switch $action {
                                "introduction" {
				::get_introduction [pd $fromPd]
                                }
                                "globrequest" {
					switch [lindex [pd $fromPd] 2] {
						"all" {
						::get_files_all [pd $fromPd] $sock
						}
						default {
						## if you have preference with a specific extesion default is you place
						::get_specific_files [pd $fromPd] $sock
						}
					}
                                }
			}

		}
}
proc ::get_specific_files {l sock} {
	#da pd : send send globreqest $0|$3 all <reference file>
	#puts $l
	set type [lindex $l 2]
	set ::msgcl "[lindex [lindex $l 1] 1] \([lindex [lindex $l 1] 0]\) request $type list"
	set dirname [file dirname [lindex $l 3]]
	set namefile [file tail [lindex $l 3]]
	set all [glob -directory $dirname -nocomplain -type f *$type]
	##START WRITING SOCKET don't comment!
		puts $sock "[join [lindex $l 1] "|"] [lindex $l 0] [lindex $l 2] start;"
			foreach item_all $all {
				puts $sock "[join [lindex $l 1] "|"] [lindex $l 0] [lindex $l 2] $item_all;"
			}
		puts $sock "[join [lindex $l 1] "|"] [lindex $l 0] [lindex $l 2] stop;"
	##STOP WRITING SOCKET
	set ::msgsr "sended [llength $all] $type files"
}
proc ::get_files_all {l sock} {
	#da pd : send send globreqest $0|$3 all <reference file>
	#puts $l
	set ::msgcl "[lindex [lindex $l 1] 1] \([lindex [lindex $l 1] 0]\) request all file list"
	set dirname [file dirname [lindex $l 3]]
	set namefile [file tail [lindex $l 3]]
	set all [glob -directory $dirname -nocomplain -type f *]
	##START WRITING SOCKET don't comment!
		puts $sock "[join [lindex $l 1] "|"] [lindex $l 0] [lindex $l 2] start;"
			foreach item_all $all {
				puts $sock "[join [lindex $l 1] "|"] [lindex $l 0] [lindex $l 2] $item_all;"
			}
		puts $sock "[join [lindex $l 1] "|"] [lindex $l 0] [lindex $l 2] stop;"
	##STOP WRITING SOCKET
	set ::msgsr "sended [llength $all] files"
}
proc get_introduction {l} {
	#da pd : send introduction $0|$3 I|AM|IN
	set ::msgcl "[lindex [lindex $l 1] 1] connected"
	puts $l
	puts "[lindex [lindex $l 1] 1] \([lindex [lindex $l 1] 0]\) connected"
	set ::msgsr "welcome [lindex [lindex $l 1] 1] !"
}

proc pd {datain} {
	set smcrm [string trimright $datain ";"]
	#remove ;
	set parsed_string [split $smcrm  " "]
	set length_list [llength $parsed_string]
	set listone {}
	set x 0
		while { $x < $length_list } {
			if { [regexp -nocase {|} [lindex $parsed_string $x]] } {
				lappend listone [split [lindex $parsed_string $x] "|"]
				} else {
				lappend listone [lindex $parsed_string $x]
			}
		set x [expr {$x + 1}]
		}
	return $listone
}

proc accept {sock addr port} {
	fileevent $sock readable [list switchrequest $sock]
	fconfigure $sock -buffering line -blocking 0
}

socket -server accept $serverport
vwait events
