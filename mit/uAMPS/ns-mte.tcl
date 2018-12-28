############################################################################
#
# This code was developed as part of the MIT uAMPS project. (June, 2000)
#
############################################################################


# Message Constants
set DATA           3
set MAC_BROADCAST  0xffffffff
set LINK_BROADCAST 0xffffffff
set BYTES_ID       2


############################################################################
#
# Minimum Transmission Energy Routing Application
#
############################################################################

Class Application/MTE -superclass Application

Application/MTE instproc init args {

  global opt 

  $self instvar rng_ round_ code_
  $self instvar dist_ now_ upstream_ alive_
  $self instvar begin_idle_

  set rng_ [new RNG]
  $rng_ seed 0
  set round_ 0
  set code_ 0
  set dist_ 0
  set now_ 0
  set upstream_ ""
  set alive_ 1
  set begin_idle_ 0

  $self next $args

}

Application/MTE instproc start {} {

  global node_ opt bs ns_ node_
  $self instvar nextHopID_ dist_ 

  [$self mac] set node_num_ [$self nodeID]
  set nodeID [$self nodeID]
  $self setCode $opt(bsCode)

  # Find next hop neighbor-- node to whom always send data.
  # Choose closest node that is in the direction of the base station. 
  # NOTE!  This algorithm assumes nodes know the location of all nodes
  # near them.  In practice, this would require an initial set-up 
  # phase where this information is disseminated throughout the network
  # and that each node has a GPS receiver or other location-tracking 
  # algorithms to determine node locations.
  set x [$self getX]
  set y [$self getY]
  set bsx [lindex $bs 0]
  set bsy [lindex $bs 1]
  set cx [expr ($x + $bsx) / 2]
  set cy [expr ($y + $bsy) / 2]
  set dtobs [nodeToBSDist $node_($nodeID) $bs] 
  set r [expr $dtobs / 2]

  set minx $bsx
  set miny $bsy
  set minID $opt(nn_)
  set mind $dtobs
  for {set i 0} {$i < $opt(nn_)} {incr i} {
    set nx [$node_($i) set X_]
    set ny [$node_($i) set Y_]
    set incircle [dist $nx $ny $cx $cy]
    if {$incircle < $r && ($nodeID != $i)} {
      set d [dist $x $y $nx $ny]
      if {$d < $mind} {
          set mind $d
          set minx $nx
          set miny $ny
          set minID $i
      }
    }  
  }

  set nextHopID_ $minID
  set dist_ $mind
  puts "[$self nodeID] next hop neighbor is $nextHopID_ (dist = $mind)"

  # All nodes keep track of who sends data to them in order to 
  # inform these neighbors to reroute data when node dies.
  if {$minID < $opt(bsID)} {
    [$node_($minID) set rca_app_] addUpStreamNeighbor $nodeID
  }

  set now_ [$ns_ now]
  $ns_ at $now_ "$self SendMyData"

  # Finding next hop neighbor costs 1 nJ/node (guess) to compute distances.
  set startup_energy [expr $opt(nn_) * 1e-9] 
  puts "\tstartup_energy = $startup_energy"
  [$self getER] remove $startup_energy

  $self checkAlive

}

Application/MTE instproc addUpStreamNeighbor id {
  $self instvar upstream_
  set upstream_ [lappend upstream_ $id]
}

Application/MTE instproc removeUpStreamNeighbor id {
  $self instvar upstream_
  set index [lsearch $upstream_ $id]
  set upstream_ [lreplace $upstream_ $index $index]
}


############################################################################
#
# Helper Functions
#
############################################################################

Application/MTE instproc getRandomNumber {llim ulim} {
  $self instvar rng_
  return [$rng_ uniform $llim $ulim]
}

Application/MTE instproc node {} {
  return [[$self agent] set node_]
}

Application/MTE instproc nodeID {} {
  return [[[$self agent] set node_] id]
}

Application/MTE instproc mac {} {
  return [[$self node] set mac_(0)]
}

Application/MTE instproc getX {} {
  return [[[$self agent] set node_] set X_]
}

Application/MTE instproc getY {} {
  return [[[$self agent] set node_] set Y_]
}

Application/MTE instproc getER {} {
  set er [[[$self agent] set node_] getER]
  return $er
}

Application/MTE instproc setCode code {
  $self instvar code_
  set code_ $code
  [$self mac] set code_ $code
}

Application/MTE instproc checkAlive {} {

  global ns_ chan opt node_
  $self instvar alive_ nextHopID_ upstream_
  $self instvar begin_idle_ 

  # Check the alive status of the node.  If the node has run out of
  # energy, it no longer functions in the network.
  set ISalive [[[$self node] set netif_(0)] set alive_]
  if {$alive_ == 1} {
    if {$ISalive == 0} {
      puts "Node [$self nodeID] is DEAD!!!!"
      $chan removeif [[$self node] set netif_(0)]
      set alive_ 0
      set opt(nn_) [expr $opt(nn_) - 1]

      # Set upstream neighbor's nextHopID_ to my nextHopID_.
      if {$nextHopID_ != $opt(bsID)} {
        [$node_($nextHopID_) set rca_app_] removeUpStreamNeighbor [$self nodeID]
      }
      set x [$node_($nextHopID_) set X_]
      set y [$node_($nextHopID_) set Y_]
      foreach element $upstream_ {
        set node $node_($element)
        set nx [$node set X_]
        set ny [$node set Y_]
        [$node set rca_app_] set nextHopID_ $nextHopID_
        [$node set rca_app_] set dist_ [dist $x $y $nx $ny]
        if {$nextHopID_ != $opt(bsID)} {
          [$node_($nextHopID_) set rca_app_] addUpStreamNeighbor $element
          puts "Node $element next hop neighbor is now $nextHopID_"
        }
      }
    } else {
      $ns_ at [expr [$ns_ now] + 0.1] "$self checkAlive"
      set idle_energy [expr $opt(Pidle) * [expr [$ns_ now] - $begin_idle_]]
      [$self getER] remove $idle_energy
      set begin_idle_ [$ns_ now]
    }
  }
  if {$opt(nn_) == 0} "sens_finish"
}


############################################################################
#
# Receive Functions
#
############################################################################

Application/MTE instproc recv {args} {

  global ns_ DATA opt
  $self instvar nextHopID_ 

  set nodeID [$self nodeID]
  set msg_type [[$self agent] set packetMsg_]
  set sender [lindex $args 1]
  set data_size [lindex $args 2]
  set msg [lrange $args 3 end]

  if {$msg_type != $DATA} {
    puts "ERROR!!! MTE routing only uses DATA types."
    exit 1
  }

  pp "Node $nodeID received data {$msg} from $sender at [$ns_ now]"
  pp "Node $nodeID must now pass data {$msg} along next \
          hop to $nextHopID_."
  $self SendDataNextHop $msg

}


############################################################################
#
# Send Functions
#
############################################################################

Application/MTE instproc SendMyData {} {

  global ns_ opt
  $self instvar alive_

  if {$alive_ == 1} {
    $self SendDataNextHop

    # Send data once every data_lag seconds.  This is set so that
    # there are minimal collisions among data messages.  If data_lag is too
    # small, no data is transmitted due to collisions.  If data_lag is 
    # too large, the channel is not efficiently used.  
    set xmitat [expr [$ns_ now] + $opt(data_lag)]
    $ns_ at $xmitat "$self SendMyData"
  }
  set nodeID [$self nodeID]
  set sense_energy [expr $opt(Esense) * $opt(sig_size) * 8]
  pp "Node $nodeID removing sensing energy = $sense_energy J."
  [$self getER] remove $sense_energy

}

Application/MTE instproc SendDataNextHop {args} {

  global ns_ DATA BYTES_ID opt 
  $self instvar dist_ nextHopID_ now_ code_

  set nodeID [$self nodeID]
  if {[llength $args] == 1} { 
    set msg [list [lindex $args 0]]
  } else { 
    set msg [list $nodeID] 
  }
  set datasize [expr $BYTES_ID * [llength $msg] + \
               [expr [llength [join $msg]] * $opt(sig_size)]]
  set mac_dst $nextHopID_
  set link_dst $nextHopID_
  set code $code_

  if {$nextHopID_ == $opt(bsID)} {
      # Data must be sent directly to the basestation.
      $self SendDataToBS $msg
  } else {
      set random_access [$self getRandomNumber 0 $opt(ra_mte)]
      $ns_ at [expr [$ns_ now] + $random_access] "$self send_now \
          $mac_dst $link_dst $DATA $msg $datasize $dist_ $code"
  }

}

Application/MTE instproc send_now {mac_dst link_dst type msg \
                                          data_size dist code} {

  global ns_
  $self instvar nextHopID_ 
  pp "[$self nodeID] sending data {$msg} to $nextHopID_ \
          (dist = $dist) at [$ns_ now]"
  [$self agent] set packetMsg_ $type
  [$self agent] set dst_ $mac_dst
  [$self agent] sendmsg $data_size $msg $mac_dst $link_dst $dist $code
}

Application/MTE instproc SendDataToBS {msg} {

  global ns_ opt bs DATA BYTES_ID
  $self instvar rng_ now_

  # Data must be sent directly to the basestation.
  set nodeID [$self nodeID]
  set datasize [expr $BYTES_ID * [llength $msg] + $opt(sig_size)]
  set dist [nodeToBSDist [$self node] $bs]

  set mac_dst $opt(bsID)
  set link_dst $opt(bsID)
  set random_delay [expr [$ns_ now] + [$rng_ uniform 0 0.01]]
  $ns_ at $random_delay "$self send_now $mac_dst $link_dst $DATA \
                         $msg $datasize $dist $opt(bsCode) "
}




