############################################################################
#
# This code was developed as part of the MIT uAMPS project. (wbh 3/24/00)
#
############################################################################
source /home/pradeepkumar/ns-allinone-2.35/ns-2.35/mit/uAMPS/ns-leach.tcl
source /home/pradeepkumar/ns-allinone-2.35/ns-2.35/mit/uAMPS/ns-leach-c.tcl
source /home/pradeepkumar/ns-allinone-2.35/ns-2.35/mit/uAMPS/ns-stat-cluster.tcl

#source $env(uAMPS_LIBRARY)/ns-leach.tcl
#source $env(uAMPS_LIBRARY)/ns-leach-c.tcl
#source $env(uAMPS_LIBRARY)/ns-stat-cluster.tcl

set opt(rcapp)        "LEACH-C/StatClustering"  ;# Application type
set opt(tr)           "/tmp/stat_clus"          ;# Trace file
# Need to spread the data by k+1
set opt(spreading)    [expr $opt(num_clusters)+1]

set outf [open "$opt(dirname)/conditions.txt" w]
puts $outf "\nUSING STATIC-CLUSTERING: CENTRALIZED CLUSTER FORMATION\n"
close $outf

source mit/uAMPS/sims/uamps.tcl

# Parameters for centralized control cluster formation algorithm
set opt(adv_info_time)     [TxTime [expr $opt(hdr_size) + 12]]
set opt(finish_adv)        [expr $opt(nn_) * $opt(adv_info_time)]
set opt(bs_setup_iters)    1000      ;# Num iters for sim. annealing alg.
set opt(bs_setup_max_eps)  10        ;# Max change for sim. annealing alg.

set outf [open "$opt(dirname)/conditions.txt" a]
puts $outf "Desired number of clusters = $opt(num_clusters)"
puts $outf "Spreading factor = $opt(spreading)\n"
close $outf

