############################################################################
#
# This code was developed as part of the MIT uAMPS project. (June, 2000)
#
############################################################################


# Message Constants
set ADV_CH         0
set JOIN_REQ       1
set ADV_SCH        2
set DATA           3
set MAC_BROADCAST  0xffffffff
set LINK_BROADCAST 0xffffffff
set BYTES_ID       2


############################################################################
#
# LEACH Application
#
############################################################################

Class Application/LEACH -superclass Application


Application/LEACH instproc init args {

  global opt

  $self instvar rng_ isch_ hasbeench_ next_change_time_ round_
  $self instvar clusterChoices_ clusterDist_ clusterNodes_ currentCH_ 
  $self instvar xmitTime_ TDMAschedule_ dist_ code_
  $self instvar now_ alive_ frame_time_ end_frm_time_
  $self instvar begin_idle_ begin_sleep_
  $self instvar myADVnum_ receivedFrom_ dataReceived_

  set rng_ [new RNG]
  $rng_ seed 0
  set isch_ 0
  set hasbeench_ 0
  set next_change_time_ 0
  set round_ 0
  set clusterChoices_ ""
  set clusterDist_ ""
  set clusterNodes_ ""
  set currentCH_ ""
  set xmitTime_ ""
  set TDMAschedule_ ""
  set dist_ 0
  set code_ 0
  set now_ 0
  set alive_ 1
  set frame_time_ $opt(frame_time)
  set end_frm_time_ 0
  set begin_idle_ 0
  set begin_sleep_ 0
  set myADVnum_ 0
  set receivedFrom_ ""
  set dataReceived_ ""

  $self next $args

}

Application/LEACH instproc start {} {
  [$self mac] set node_num_ [$self nodeID]
  $self decideClusterHead
  $self checkAlive 
}


############################################################################
#
# Helper Functions
#
############################################################################

Application/LEACH instproc getRandomNumber {llim ulim} {
  $self instvar rng_
  return [$rng_ uniform $llim $ulim]
}

Application/LEACH instproc node {} {
  return [[$self agent] set node_]
}

Application/LEACH instproc nodeID {} {
  return [[$self node] id]
}

Application/LEACH instproc mac {} {
  return [[$self node] set mac_(0)]
}

Application/LEACH instproc getX {} {
  return [[$self node] set X_]
}

Application/LEACH instproc getY {} {
  return [[$self node] set Y_]
}

Application/LEACH instproc getER {} {
  set er [[$self node] getER]
  return $er
}

Application/LEACH instproc GoToSleep {} {
  global opt ns_
  $self instvar begin_idle_ begin_sleep_

  [[$self node] set netif_(0)] set sleep_ 1
  # If node has been awake, remove idle energy (e.g., the amount of energy
  # dissipated while the node is in the idle state).  Otherwise, the node
  # has been asleep and must remove sleep energy (e.g., the amount of
  # energy dissipated while the node is in the sleep state).
  if {$begin_idle_ > $begin_sleep_} {
    set idle_energy [expr $opt(Pidle) * [expr [$ns_ now] - $begin_idle_]]
    [$self getER] remove $idle_energy
  } else {
    set sleep_energy [expr $opt(Psleep) * [expr [$ns_ now] - $begin_sleep_]]
    [$self getER] remove $sleep_energy
  }
  set begin_sleep_ [$ns_ now]
  set begin_idle_ 0
}

Application/LEACH instproc WakeUp {} {
  global opt ns_
  $self instvar begin_idle_ begin_sleep_

  [[$self node] set netif_(0)] set sleep_ 0
  # If node has been asleep, remove sleep energy (e.g., the amount of energy
  # dissipated while the node is in the sleep state).  Otherwise, the node
  # has been idling and must remove idle energy (e.g., the amount of
  # energy dissipated while the node is in the idle state).
  if {$begin_sleep_ > $begin_idle_} {
    set sleep_energy [expr $opt(Psleep) * [expr [$ns_ now] - $begin_sleep_]]
    [$self getER] remove $sleep_energy
  } else {
    set idle_energy [expr $opt(Pidle) * [expr [$ns_ now] - $begin_idle_]]
    [$self getER] remove $idle_energy
  }
  set begin_idle_ [$ns_ now]
  set begin_sleep_ 0
}

Application/LEACH instproc setCode code {
  $self instvar code_
  set code_ $code
  [$self mac] set code_ $code
}

Application/LEACH instproc checkAlive {} {

  global ns_ chan opt node_
  $self instvar alive_ TDMAschedule_
  $self instvar begin_idle_ begin_sleep_

  # Check the alive status of the node.  If the node has run out of
  # energy, it no longer functions in the network.
  set ISalive [[[$self node] set netif_(0)] set alive_]
  if {$alive_ == 1} {
    if {$ISalive == 0} {
      puts "Node [$self nodeID] is DEAD!!!!"
      $chan removeif [[$self node] set netif_(0)]
      set alive_ 0
      set opt(nn_) [expr $opt(nn_) - 1]

      if {$opt(rcapp) == "LEACH-C/StatClustering" && \
          [$self isClusterHead?]} {
        foreach element $TDMAschedule_ {
          if {$element != [$self nodeID]} {
            puts "Node $element is effectively DEAD!!!!"
            $chan removeif [$node_($element) set netif_(0)]
            [$node_($element) set netif_(0)] set alive_ 0
            [$node_($element) set rca_app_] set alive_ 0
            set opt(nn_) [expr $opt(nn_) - 1]
          }
        }
      }
    } else {
      $ns_ at [expr [$ns_ now] + 0.1] "$self checkAlive"
      if {$begin_idle_ >= $begin_sleep_} {
        set idle_energy [expr $opt(Pidle) * [expr [$ns_ now] - $begin_idle_]]
        [$self getER] remove $idle_energy
        set begin_idle_ [$ns_ now]
      } else {
        set sleep_energy [expr $opt(Psleep) * [expr [$ns_ now] - $begin_sleep_]]
        [$self getER] remove $sleep_energy
        set begin_sleep_ [$ns_ now]
      }
    }
  }
  if {$opt(nn_) < $opt(num_clusters)} "sens_finish"
}

############################################################################
#
# Cluster Head Functions
#
############################################################################

Application/LEACH instproc isClusterHead? {} {
  $self instvar isch_
  return $isch_
}

Application/LEACH instproc hasbeenClusterHead? {} {
  $self instvar hasbeench_
  return $hasbeench_
}

Application/LEACH instproc hasnotbeenClusterHead {} {
  $self instvar hasbeench_
  set hasbeench_ 0
}

Application/LEACH instproc setClusterHead {} {
  $self instvar isch_ hasbeench_
  set isch_ 1
  set hasbeench_ 1
  return 
}

Application/LEACH instproc unsetClusterHead {} {
  $self instvar isch_
  set isch_ 0
  return 
}


############################################################################
#
# Distributed Cluster Set-up Functions
#
############################################################################

Application/LEACH instproc decideClusterHead {} {

  global chan ns_ opt node_

  $self instvar next_change_time_ round_ clusterNodes_ 
  $self instvar now_ TDMAschedule_ beginningE_ alive_
  $self instvar myADVnum_ CHheard_

  set CHheard_ 0
  [$self mac] set CHheard_ $CHheard_
  set myADVnum_ 0
  [$self mac] set myADVnum_ $myADVnum_

  # Check the alive status of the node.  If the node has run out of
  # energy, it no longer functions in the network.
  set ISalive [[[$self node] set netif_(0)] set alive_]
  if {$alive_ == 1 && $ISalive == 0} {
    puts "Node [$self nodeID] is DEAD!!!! Energy = [[$self getER] query]"
    $chan removeif [[$self node] set netif_(0)]
    set alive_ 0
    set opt(nn_) [expr $opt(nn_) - 1]
  }
  if {$alive_ == 0} {return}

  set now_ [$ns_ now]
  set nodeID [$self nodeID]
  set beginningE_ [[$self getER] query]

  $self setCode 0
  $self WakeUp 

  set tot_rounds [expr int([expr $opt(nn_) / $opt(num_clusters)])]
  if {$round_ >= $tot_rounds} {
    set round_ 0
  }

  if {$opt(eq_energy) == 1} {
    #
    # Pi(t) = k / (N - k mod(r,N/k))
    # where k is the expected number of clusters per round
    # N is the total number of sensor nodes in the network
    # and r is the number of rounds that have already passed.
    #
    set nn $opt(nn_)
    if {[expr $nn - $opt(num_clusters) * $round_] < 1} {
      set thresh 1
    } else {
      set thresh [expr double($opt(num_clusters)) /  \
        [expr $nn - $opt(num_clusters) * $round_]]
      # Whenever round_ is 0, all nodes are eligible to be cluster-head.
      if {$round_ == 0} {
        $self hasnotbeenClusterHead
      }
    }
    # If node has been cluster-head in this group of rounds, it will not
    # act as a cluster-head for this round.
    if {[$self hasbeenClusterHead?]} {
      set thresh 0
    }
  } else {
    #
    # Pi(t) = Ei(t) / Etotal(t) * k
    # where k is the expected number of clusters per round,
    # Ei(t) is the node's current energy, and Etotal(t) is the total 
    # energy from all nodes in the network.
    #
    set Etotal 0
    # Note!  In a real network, would need a routing protocol to get this
    # information.  Alternatively, each node could estimate Etotal(t) from 
    # the energy of nodes in its cluster.
    for {set id 0} {$id < [expr $opt(nn)-1]} {incr id} {
      set app [$node_($id) set rca_app_]
      set E [[$app getER] query]
      set Etotal [expr $Etotal + $E]
    }
    set E [[$self getER] query]
    set thresh [expr double([expr $E * $opt(num_clusters)]) / $Etotal] 
  }

  puts "THRESH = $thresh"
  set clusterNodes_ ""
  set TDMAschedule_ ""

  if {[$self getRandomNumber 0 1] < $thresh} {
    puts "$nodeID: *******************************************"
    puts "$nodeID: Is a cluster head at time [$ns_ now]"
    $self setClusterHead
    set random_access [$self getRandomNumber 0 $opt(ra_adv)]
    $ns_ at [expr $now_ + $random_access] "$self advertiseClusterHead"
  } else {
    puts "$nodeID: *******************************************"
    $self unsetClusterHead
  }

  incr round_ 
  set next_change_time_ [expr $now_ + $opt(ch_change)] 
  $ns_ at $next_change_time_ "$self decideClusterHead"
  $ns_ at [expr $now_ + $opt(ra_adv_total)] "$self findBestCluster"
}

Application/LEACH instproc advertiseClusterHead {} {

  global ns_ opt ADV_CH MAC_BROADCAST LINK_BROADCAST BYTES_ID
  $self instvar currentCH_ code_ 

  set chID [$self nodeID]
  set currentCH_ $chID
  pp "Cluster Head $currentCH_ broadcasting ADV at time [$ns_ now]"
  set mac_dst $MAC_BROADCAST
  set link_dst $LINK_BROADCAST
  set msg [list $currentCH_]
  set datasize [expr $BYTES_ID * [llength $msg]]

  # Send beacons opt(max_dist) meters so all nodes can hear.
  $self send $mac_dst $link_dst $ADV_CH $msg $datasize $opt(max_dist) $code_
}
    
Application/LEACH instproc findBestCluster {} {

  global ns_ opt 

  $self instvar now_ dist_ myADVnum_
  $self instvar clusterChoices_ clusterDist_ currentCH_ 

  set nodeID [$self nodeID]
  set min_dist 100000 
  if [$self isClusterHead?] {
    # If node is CH, determine code and create a TDMA schedule.
    set dist_ $opt(max_dist)
    set currentCH_ $nodeID
    set myADVnum_ [[$self mac] set myADVnum_] 
    # There are opt(spreading) - 1 codes available b/c need 1 code 
    # for communication with the base station.
    set numCodesAvail [expr 2 * $opt(spreading) - 1]
    set ClusterCode [expr int(fmod($myADVnum_, $numCodesAvail)) + 1]
    $ns_ at [expr $now_ + $opt(ra_adv_total) + $opt(ra_join)] \
        "$self createSchedule"
  } else {
    # If node is not a CH, find the CH which allows minimum transmit
    # power for communication.  Set the code and "distance" parameters
    # accordingly.
    if {$clusterChoices_ == ""} {
      puts "$nodeID: Warning!!! No Cluster Head ADVs were heard!"
      set currentCH_ $opt(nn)
      $self SendMyDataToBS
      return
    }
    foreach element $clusterChoices_ {
      set chID [lindex $element 0]
      set clustID [lindex $element 2]
      set ind [lsearch $clusterChoices_ $element]
      set d [lindex $clusterDist_ $ind]
      if {$d < $min_dist} {
          set min_dist $d
          set currentCH_ $chID
          set numCodesAvail [expr 2 * $opt(spreading) - 1]
          set ClusterCode [expr int(fmod($ind, $numCodesAvail)) + 1]
      }
    }
    set dist_ $min_dist

    set random_access [$self getRandomNumber 0 \
                             [expr $opt(ra_join) - $opt(ra_delay)]]
    $ns_ at [expr $now_ + $opt(ra_adv_total) + $random_access] \
            "$self informClusterHead"
    $self GoToSleep 
  }

  $self setCode $ClusterCode
  puts "$nodeID: Current cluster-head is $currentCH_, code is $ClusterCode, \
        dist is $dist_"

  set clusterChoices_ ""
  set clusterDist_ ""
}

Application/LEACH instproc informClusterHead {} {

  global ns_ opt JOIN_REQ MAC_BROADCAST BYTES_ID 
  $self instvar currentCH_ dist_ code_ 

  set nodeID [$self nodeID]
  set chID $currentCH_
  pp "$nodeID: sending Join-REQ to $chID (dist = $dist_) at time [$ns_ now]"
  set mac_dst $MAC_BROADCAST
  set link_dst $chID
  set msg [list $nodeID]
  set spreading_factor $opt(spreading)
  set datasize [expr $spreading_factor * $BYTES_ID * [llength $msg]]
  $self WakeUp 

  # NOTE!!!! Join-Req message sent with enough power so all nodes in
  # the network can hear the message.  This avoids the hidden terminal
  # problem.
  $self send $mac_dst $link_dst $JOIN_REQ $msg $datasize $opt(max_dist) $code_
}

Application/LEACH instproc createSchedule {} {

  global ns_ opt ADV_SCH MAC_BROADCAST BYTES_ID 
 
  $self instvar clusterNodes_ TDMAschedule_ 
  $self instvar dist_ code_ now_ beginningE_

  set numNodes [llength $clusterNodes_]
  set chID [$self nodeID]
  if {$numNodes == 0} {
    set xmitOrder ""
    puts "Warning!  There are no nodes in this cluster ($chID)!"
    $self SendMyDataToBS
  } else {
    # Set the TDMA schedule and send it to all nodes in the cluster.
    set xmitOrder $clusterNodes_
    set msg [list $xmitOrder]
    set spreading_factor $opt(spreading)
    set datasize [expr $spreading_factor * $BYTES_ID * [llength $xmitOrder]]
    pp "$chID sending TDMA schedule: $xmitOrder at time [$ns_ now]"
    pp "Packet size is $datasize."
    set mac_dst $MAC_BROADCAST
    set link_dst $chID
    $self send $mac_dst $link_dst $ADV_SCH $msg $datasize $dist_ $code_
  }

  set TDMAschedule_ $xmitOrder
  set outf [open $opt(dirname)/TDMAschedule.$now_.txt a]
  puts $outf "$chID\t$TDMAschedule_"
  close $outf

  set outf [open $opt(dirname)/startup.energy a]
  puts $outf "[$ns_ now]\t$chID\t[expr $beginningE_ - [[$self getER] query]] "
  close $outf

}


############################################################################
#
# Receiving Functions
#
############################################################################

Application/LEACH instproc recv {args} {

  global ADV_CH JOIN_REQ ADV_SCH DATA ns_

  $self instvar currentCH_ 

  set msg_type [[$self agent] set packetMsg_]
  set chID [lindex $args 0]
  set sender [lindex $args 1]
  set data_size [lindex $args 2]
  set msg [lrange $args 3 end]

  set nodeID [$self nodeID]

  if {$msg_type == $ADV_CH && ![$self isClusterHead?]} { 
    $self recvADV_CH $msg
  } elseif {$msg_type == $JOIN_REQ && $nodeID == $chID} {
    $self recvJOIN_REQ $msg
  } elseif {$msg_type == $ADV_SCH  && $chID == $currentCH_} {
    $self recvADV_SCH $msg
  } elseif {$msg_type == $DATA && $nodeID == $chID} {
    $self recvDATA $msg
  }

}

Application/LEACH instproc recvADV_CH {msg} {

  global ns_
  $self instvar clusterChoices_ clusterDist_ 
  set chID [lindex $msg 0]
  set nodeID [$self nodeID]
  pp "$nodeID rcvd ADV_CH from $chID at [$ns_ now]"
  set clusterChoices_ [lappend clusterChoices_ $msg]
  set clusterDist_ [lappend clusterDist_ [[$self agent] set distEst_]]
}

Application/LEACH instproc recvJOIN_REQ {nodeID} {

  global ns_
  $self instvar clusterNodes_ 
  set chID [$self nodeID]
  pp "$chID received notice of node $nodeID at time [$ns_ now]"
  set clusterNodes_ [lappend clusterNodes_ $nodeID]
}

Application/LEACH instproc recvADV_SCH {order} {

  global ns_ opt
  $self instvar xmitTime_ next_change_time_ now_ 
  $self instvar beginningE_ frame_time_ end_frm_time_

  set nodeID [$self nodeID]
  set ind [lsearch [join $order] $nodeID]

  set outf [open $opt(dirname)/startup.energy a]
  puts $outf "[$ns_ now]\t$nodeID\t[expr $beginningE_ - [[$self getER] query]]"
  close $outf

  if {$ind < 0} {
    puts "Warning!!!!  $nodeID does not have a transmit time!"
    puts "Must send data directly to BS."
    set outf [open $opt(dirname)/TDMAschedule.$now_.txt a]
    puts -nonewline $outf "$nodeID\t"
    close $outf
    $self SendMyDataToBS
    return
  }
  # Determine time for a single TDMA frame.  Each node sends data once 
  # per frame in the specified slot.
  set frame_time_ [expr [expr 5 + [llength [join $order]]] * $opt(ss_slot_time)]
  set xmitTime_ [expr $opt(ss_slot_time) * $ind]
  set end_frm_time_ [expr $frame_time_ - $xmitTime_]
  set xmitat [expr [$ns_ now] + $xmitTime_]
  pp "$nodeID scheduled to transmit at $xmitat.  It is now [$ns_ now]."
  if {[expr $xmitat + $end_frm_time_] < \
      [expr $next_change_time_ - 10 * $opt(ss_slot_time)]} {
    $ns_ at $xmitat "$self sendData"
  }

  $self GoToSleep 
}

Application/LEACH instproc recvDATA {msg} {

  global ns_ opt
  $self instvar TDMAschedule_ receivedFrom_ dataReceived_

  set chID [$self nodeID]
  set nodeID [lindex $msg 0]
  pp "CH $chID received data ($msg) from $nodeID at [$ns_ now]"
  set receivedFrom_ [lappend receivedFrom_ $nodeID]

  set last_node [expr [llength $TDMAschedule_] - 1]
  if {$chID == [lindex $TDMAschedule_ $last_node]} {
    set last_node [expr $last_node - 1]
  }
  if {$nodeID == [lindex $TDMAschedule_ $last_node]} {
    # After an entire frame of data has been received, the cluster-head
    # must perform data aggregation functions and transmit the aggregate
    # signal to the base station.
    pp "CH $chID must now perform comp and xmit to BS."
    set num_sigs [llength $TDMAschedule_]
    set compute_energy [bf $opt(sig_size) $num_sigs]
    pp "\tcompute_energy = $compute_energy"
    [$self getER] remove $compute_energy
    set receivedFrom_ [lappend receivedFrom_ $chID]
    set dataReceived_ $receivedFrom_
    set receivedFrom_ ""

    $self SendDataToBS
  }
}


############################################################################
#
# Sending Functions
#
############################################################################

Application/LEACH instproc sendData {} {

  global ns_ opt DATA MAC_BROADCAST BYTES_ID 

  $self instvar next_change_time_ frame_time_ end_frm_time_
  $self instvar currentCH_ dist_ code_ alive_ 

  set nodeID [$self nodeID]
  set msg [list [list $nodeID , [$ns_ now]]]
  # Use DS-SS to send data messages to avoid inter-cluster interference.
  set spreading_factor $opt(spreading)
  set datasize [expr $spreading_factor * \
               [expr [expr $BYTES_ID * [llength $msg]] + $opt(sig_size)]]

  $self WakeUp 

  pp "$nodeID sending data $msg to $currentCH_ at [$ns_ now] (dist = $dist_)"
  set mac_dst $MAC_BROADCAST
  set link_dst $currentCH_
  $self send $mac_dst $link_dst $DATA $msg $datasize $dist_ $code_

  # Must transmit data again during slot in next TDMA frame.
  set xmitat [expr [$ns_ now] + $frame_time_]
  if {$alive_ && [expr $xmitat + $end_frm_time_] < \
                 [expr $next_change_time_ - 10 * $opt(ss_slot_time)]} {
    $ns_ at $xmitat "$self sendData"
  } 
  set sense_energy [expr $opt(Esense) * $opt(sig_size) * 8]
  pp "Node $nodeID removing sensing energy = $sense_energy J."
  [$self getER] remove $sense_energy

  if {$currentCH_ != $nodeID} {
    $self GoToSleep 
  }

}

Application/LEACH instproc send {mac_dst link_dst type msg
                                      data_size dist code} {
  global ns_
  $self instvar rng_

  #set random_delay [expr 0.005 + [$rng_ uniform 0 0.005]]
  #$ns_ at [expr [$ns_ now] + $random_delay] "$self send_now $mac_dst \
  #  $link_dst $type $msg $data_size $dist"
  $ns_ at [$ns_ now]  "$self send_now $mac_dst \
      $link_dst $type $msg $data_size $dist $code"
}

Application/LEACH instproc send_now {mac_dst link_dst type msg \
                                          data_size dist code} {
    [$self agent] set packetMsg_ $type
    [$self agent] set dst_ $mac_dst
    [$self agent] sendmsg $data_size $msg $mac_dst $link_dst $dist $code
}

Application/LEACH instproc SendDataToBS {} {

      global ns_ opt bs MAC_BROADCAST DATA BYTES_ID

      $self instvar code_ rng_ now_ 

      # Data must be sent directly to the basestation.
      set nodeID [$self nodeID]
      set msg [list [list [list $nodeID , [$ns_ now]]]]
      # Use DS-SS to send data messages to avoid inter-cluster interference.
      set spreading_factor $opt(spreading)
      set datasize [expr $spreading_factor * \
                         [expr $BYTES_ID * [llength $msg] + $opt(sig_size)]]
      set dist [nodeToBSDist [$self node] $bs] 

      set mac_dst $MAC_BROADCAST
      set link_dst $opt(bsID)
      set random_delay [expr [$ns_ now] + [$rng_ uniform 0 0.01]]
      pp "Node $nodeID sending $msg to BS at time $random_delay"
      $ns_ at $random_delay "$self send $mac_dst $link_dst $DATA \
                             $msg $datasize $dist $opt(bsCode)"
}

Application/LEACH instproc SendMyDataToBS {} {
      global ns_ opt
      $self instvar next_change_time_ alive_
      puts "Data being sent to the Base Station"
      $self SendDataToBS
      puts "Data was sent to the base station"
      set xmitat [expr [$ns_ now] + $opt(frame_time)]
      if {$alive_ && [expr $xmitat + $opt(frame_time)] < \
                 [expr $next_change_time_ - $opt(frame_time)]} {
        $ns_ at $xmitat "$self SendMyDataToBS"
      } 
}

