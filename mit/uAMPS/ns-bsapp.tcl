############################################################################
#
# This code was developed as part of the MIT uAMPS project. (June, 2000)
#
############################################################################


# Message Constants
set MAC_BROADCAST 0xffffffff
set LINK_BROADCAST 0xffffffff
set DATA 3
set INFO 4
set BS_CH_INFO 5


############################################################################
#
# Base Station Application
#
############################################################################

Class Application/BSApp -superclass Application


Application/BSApp instproc init args {

  $self instvar rng_ total_ now_ code_ 

  set rng_ [new RNG]
  $rng_ seed 0
  set total_ 0
  set now_ 0
  set code_ 0

  $self next $args

}

Application/BSApp instproc start {} {

  global opt ns_
  $self instvar code_ now_ data_ 

  set now_ [$ns_ now]
  set code_ $opt(bsCode)
  [$self mac] set code_ $code_
  [$self mac] set node_num_ [$self nodeID]

  # Keep track of the data received from each node.  Data may be received
  # either directly or as part of an aggregate signal.
  for {set i 0} {$i < $opt(nn_)} {incr i} {
      set data_($i) 0
  }

  # If running leach-c or stat-clus, BS sets up clusters.
  # Use a C++ routine to determine optimal clusters.
  # Must pass agent the appropriate parameters for cluster formation.
  if {$opt(rcapp) == "LEACH/LEACH-C" || \
      $opt(rcapp) == "LEACH-C/StatClustering"} {
      [$self agent] transfer_info [expr $opt(nn) - 1] \
                    $opt(num_clusters) \
                    $opt(bs_setup_iters) \
                    $opt(bs_setup_max_eps)
      $ns_ at [expr $now_ + $opt(finish_adv)] "$self BSsetup"
  }

}


############################################################################
#
# Helper Functions
#
############################################################################

Application/BSApp instproc node {} {
  return [[$self agent] set node_]
}

Application/BSApp instproc nodeID {} {
  return [[$self node] id]
}

Application/BSApp instproc mac {} {
  return [[$self node] set mac_(0)]
}

Application/BSApp instproc getData {id} {
  $self instvar data_
  return $data_($id)
}


############################################################################
#
# Receiving Functions
#
############################################################################

Application/BSApp instproc recv {args} {

  global INFO DATA

  # If recv_code is 1, have just received centralized
  # cluster formation information.
  # If recv_code is 0, have just received a packet.
  set recv_code [[$self agent] set recv_code_] 
  if {$recv_code == 1} {
    $self recvClusterInfo $args
  } else {
    set msg_type [[$self agent] set packetMsg_]
    set chID [lindex $args 0]
    set sender [lindex $args 1]
    set data_size [lindex $args 2]
    set msg [lrange $args 3 end]
    set nodeID [$self nodeID]

    if {$msg_type == $INFO} {
        $self recvINFO $sender $msg
    } elseif {$msg_type == $DATA && $nodeID == $chID} {
      $self recvDATA $sender $msg
    }
  }
}

Application/BSApp instproc recvINFO {sender msg} {

  global opt
  $self instvar total_

  # Record information (location and energy) received from the nodes 
  # for centralized cluster formation.
  if {$total_ == 0} {
    for {set i 0} {$i < [expr $opt(nn) - 1]} {incr i} {
        [$self agent] append_info $i 0 0 0
    }
  }

  set X [lindex $msg 0]
  set Y [lindex $msg 1]
  set E [lindex $msg 2]
  incr total_
  puts "BS received info: ($X $Y $E) from Node $sender" 
  puts "BS received: $total_ "
  [$self agent] append_info $sender $X $Y $E 

}


Application/BSApp instproc recvClusterInfo args {

    global MAC_BROADCAST LINK_BROADCAST BS_CH_INFO opt
    $self instvar code_ now_ ch_index_

    set ch_index $args
    set mac_dst $MAC_BROADCAST
    set link_dst $LINK_BROADCAST
    set msg [list [list $ch_index]]
    set datasize [expr 4 * [llength [join $ch_index]]]

    # Broadcast cluster information to sensor nodes.
    $self send $mac_dst $link_dst $BS_CH_INFO $msg $datasize 1000 $code_
    set now_ [expr $now_ + $opt(ch_change)]
    set ch_index_ [join $ch_index]
}

Application/BSApp instproc recvDATA {sender msg} {

  global ns_ opt node_
  $self instvar data_  

  # Keep track of how much data is received from each node.
  # Data may be sent directly or via an aggregate signal.
  puts "BS Received data $msg from $sender at time [$ns_ now]"

  set nodes_data ""
  set actual_nodes_data ""
  if {$opt(rcapp) == "Application/MTE"} {
    set nodes_data $msg
    set actual_nodes_data $msg
    foreach i $nodes_data {
      incr data_($i)
    }
  } else {
    set nodes_data [[$node_($sender) set rca_app_] set dataReceived_]
    foreach i $nodes_data {
      if {[[$node_($i) set rca_app_] set alive_] == 1} {
        incr data_($i)
        lappend actual_nodes_data $i
      }
    }
  }
  puts "This represents data from nodes: $actual_nodes_data"

}


############################################################################
#
# Sending Functions
#
############################################################################

Application/BSApp instproc send {mac_dst link_dst type msg
                                      data_size dist code} {
    [$self agent] set packetMsg_ $type
    [$self agent] set dst_ $mac_dst
    [$self agent] sendmsg $data_size $msg $mac_dst $link_dst $dist $code
}


Application/BSApp instproc BSsetup {} {
  global ns_ opt
  $self instvar total_

  # Use a C++ routine to determine optimal clusters.
  if {$total_ > $opt(num_clusters)} {
    [$self agent] transfer_info [expr $opt(nn) - 1] \
                      $opt(num_clusters) \
                      $opt(bs_setup_iters) \
                      $opt(bs_setup_max_eps)
    [$self agent] BSsetup
  } else {
    # If there are too few nodes to form clusters, end simulation.
    puts "Only received info from $total_ nodes."
    puts "There are currently $opt(nn_) alive ==> \
          $opt(num_clusters) cluster-heads needed."
    "sens_finish"
  }
  set total_ 0
  # Only LEACH-C performs set-up once every round. 
  if {$opt(rcapp) == "LEACH/LEACH-C"} {
    $ns_ at [expr [$ns_ now] + $opt(ch_change)] "$self BSsetup"
  }

}

