global bs opt 

set filename [open $opt(topo) r]
set num_nodes $opt(nn_)
set max_x 0
set max_y 0
set min_x 10000
set min_y 10000
for {set i 0} {$i < $num_nodes} {incr i} {
	set params [gets $filename]
	set x [lindex $params 0]
	set y [lindex $params 1]
	puts "Node $i: ($x,$y)"
	$node_($i) set X_ $x
	$node_($i) set Y_ $y
	$node_($i) set Z_ 0.000000000000
	if {$x > $max_x} {set max_x $x}
	if {$y > $max_y} {set max_y $y}
	if {$x < $min_x} {set min_x $x}
	if {$y < $min_y} {set min_y $y}
}

$node_($num_nodes) set X_ [lindex $bs 0]
$node_($num_nodes) set Y_ [lindex $bs 1]
$node_($num_nodes) set Z_ 0.000000000000

set opt(max_dist) [expr ceil([expr sqrt([expr \
											  pow([expr $max_x - $min_x],2) +  \
											  pow([expr $max_y - $min_y],2)])])]
puts "Max Distance for this Simulation is $opt(max_dist)"

for {set i 0} {$i <= $num_nodes} {incr i} {
	for {set j 0} {$j <= $num_nodes} {incr j} {
		$god_ set-dist $i $j 1
	}
}

close $filename 
