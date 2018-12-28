############################################################################
#
# This code was developed as part of the MIT uAMPS project. (June, 2000)
#
############################################################################


############################################################################
#
#  Utilities for gathering statistics during the course of the simulation.
#
#  To start up a suite of statistics under the name "trace" call:
#             sens_init_stats "trace"
# 
#  To add a new sample to the statistics collection, call:
#             sens_gather_stats
# 
#  To finish gathering statistics, call:
#                 sens_close_stats
#
#  Statistics will be stored in the files:
#             trace.energy -- total energy used by the nodes
#             trace.data -- total data received by the BS from each node
#             trace.alive -- total number of nodes that remain alive
#
############################################################################

set sens_energyf 0
set sens_dataf 0
set sens_alivef 0


############################################################################
#
# Initialization
#
############################################################################

proc sens_init_stats {name} {
    global sens_energyf sens_dataf sens_alivef 

    set sens_energyf [open "$name.energy" w]
    set sens_dataf [open "$name.data" w]
    set sens_alivef [open "$name.alive" w]
}

############################################################################
#
# Statistics Gathering 
#
############################################################################

proc sens_gather_stats {args} {

    global ns_ opt node_ sens_energyf sens_dataf sens_alivef

    set thetime [$ns_ now]
    set total_energy 0
    set total_data 0
    set total_alive 0

    # Print out the energy used for each node.
    for {set id 0} {$id < [expr $opt(nn)-1]} {incr id} {
      set er [$node_($id) getER]
      set expended [$er set expended_]
      set total_energy [expr $total_energy + $expended]
      puts $sens_energyf "$thetime $id $expended"
    }

    # Print out the total data received by the BS.
    set app [$node_($opt(bsID)) set rca_app_]
    for {set id 0} {$id < [expr $opt(nn)-1]} {incr id} {
      set node_data [$app getData $id]
      puts $sens_dataf "$thetime $id $node_data"
      set total_data [expr $total_data + $node_data]
    }

    # Print out the total number of sensors that are alive.
    for {set id 0} {$id < [expr $opt(nn)-1]} {incr id} {
      set app [$node_($id) set rca_app_]
      set alive [$app set alive_]
      puts $sens_alivef "$thetime $id $alive"
      set total_alive [expr $total_alive + $alive]
    }

    puts "\nAt $thetime:"
    puts "\t\tTotal Energy = $total_energy"
    puts "\t\tTotal Data = $total_data"
    puts "\t\tTotal Alive = $total_alive\n"

    $ns_ at [expr $thetime + $opt(check_energy)] "sens_gather_stats"

    flush $sens_energyf
    flush $sens_dataf
    flush $sens_alivef
    return
}

############################################################################
#
# Finishing Functions
#
############################################################################

proc sens_finish {} {

  sens_gather_stats
  sens_close_stats
  puts "Simulation complete.\n"
  exit 0
}

proc sens_close_stats {} {
    global sens_energyf sens_dataf sens_alivef

    close $sens_energyf
    close $sens_dataf
    close $sens_alivef
}

proc find_haslist id {
  global wantslist
  set wantslist ""
  return $id
}
