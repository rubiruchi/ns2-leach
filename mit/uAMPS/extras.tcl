############################################################################
#
# This code was developed as part of the MIT uAMPS project. (June, 2000)
#
############################################################################


############################################################################
#
# Functions to calculate distances.
#
############################################################################

proc nodeDist {node1 node2} {
  return [dist [$node1 set X_] [$node1 set Y_] [$node2 set X_] [$node2 set Y_]]
}

proc nodeToBSDist {node1 bs} {
  return [dist [$node1 set X_] [$node1 set Y_] [lindex $bs 0] [lindex $bs 1]]
}

proc dist {x1 y1 x2 y2} {
  set d [expr sqrt([expr pow([expr $x1-$x2],2) + pow([expr $y1-$y2],2)])]
  return $d
}


############################################################################
#
# Computational energy dissipation model for beamforming num signals 
# of size bytes/signal.
#
############################################################################

proc bf {size num} {
  global opt

  set bits_size [expr $size * 8]
  set energy 0
  if {$num > 1} {
    set energy [expr $opt(e_bf) * $bits_size * $num];
  }
  return $energy
}


############################################################################
#
# Miscellaneous printing (output) functions.
#
############################################################################

proc nround {val digits} {
  global tcl_precision
  set old_tcl_precision $tcl_precision
  set tcl_precision $digits
  set newval [expr $val * 1]
  puts $newval
  set tcl_precision $old_tcl_precision
  return $newval
}

proc nroundf {file val digits} {
  global tcl_precision
  set old_tcl_precision $tcl_precision
  set tcl_precision $digits
  set newval [expr $val * 1]
  puts $file $newval
  set tcl_precision $old_tcl_precision
  return $newval
}

proc pputs {str val} {
  puts -nonewline $str
  nround $val 6
}

proc pp args {
  global opt

  set options [lindex $args 0]
  if {$opt(quiet) == 0} {
    if {$options == "-nonewline" } {
        puts -nonewline [lindex $args 1]
    } else {
      puts [lindex $args 0]
    }
  }
  return
}
