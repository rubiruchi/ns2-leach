############################################################################
#
# This code was developed as part of the MIT uAMPS project. (wbh 3/24/00)
#
############################################################################

source /home/pradeepkumar/ns-allinone-2.35/ns-2.35/mit/uAMPS/ns-mte.tcl

set opt(rcapp)        "Application/MTE"      ;# Application type
set opt(tr)           "/tmp/mte.tr"          ;# Trace file
set opt(spreading)    1

set outf [open "$opt(dirname)/conditions.txt" w]
puts $outf "\nUSING MTE ROUTING\n"
close $outf

source mit/uAMPS/sims/uamps.tcl

# Parameters for MTE algorithm
# Random offset for mte-- neede to make sure nodes do not all transmit at
# same time.  Otherwise, CSMA fails.
set opt(ra_mte)       0.01                
# Latency between when nodes transmit their data.  Each data message takes
# tmsg seconds and traverses sqrt(N) hops (on average).  There are N 
# messages (1 per node).  Therefore, data_lag = N * sqrt(N) * tmsg.
set opt(data_lag)     [expr [expr $opt(nn_) * [expr sqrt($opt(nn_))] * 8 * \
                            [expr $opt(sig_size) + $opt(hdr_size) + 75]] / \
                            $opt(bw)] 

set outf [open "$opt(dirname)/conditions.txt" a]
puts $outf "Spreading factor = $opt(spreading)"
puts $outf "Data lag is $opt(data_lag) seconds.\n"
close $outf
