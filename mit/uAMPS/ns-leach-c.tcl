############################################################################
#
# This code was developed as part of the MIT uAMPS project. (June, 2000)
#
############################################################################


# Message Constants
set INFO 4
set BS_CH_INFO 5


############################################################################
#
# LEACH-C Application
#
############################################################################

Class LEACH/LEACH-C -superclass Application/LEACH


LEACH/LEACH-C instproc init args {
  $self next $args
}

LEACH/LEACH-C instproc start {} {
  [$self mac] set node_num_ [$self nodeID]
  $self advertiseInfo
  $self checkAlive 
}


############################################################################
#
# Centralized Cluster Formation Set-up Functions
#
############################################################################

LEACH/LEACH-C instproc advertiseInfo {} {

  global ns_ chan opt bs INFO MAC_BROADCAST LINK_BROADCAST BYTES_ID
  $self instvar code_ beginningE_ now_ alive_

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

  # Send (X,Y)-coordinates and current energy information to BS.
  $self setCode $opt(bsCode)
  $self WakeUp
  set now_ [$ns_ now]
  set nodeID [$self nodeID]
  set X [$self getX]
  set Y [$self getY]
  set E [[$self getER] query]
  set mac_dst $MAC_BROADCAST
  set link_dst $LINK_BROADCAST
  set msg [list [list [list $X $Y $E]]]
  set datasize [expr $BYTES_ID * [llength [list $X $Y $E]]] 
  set dist [nodeToBSDist [$self node] $bs] 

  set beginningE_ $E

  # Each node transmits to the base station in a given time slot.
  set xmitat [expr [$ns_ now] + [expr $nodeID * $opt(adv_info_time)]]

  $ns_ at $xmitat "$self send $mac_dst $link_dst $INFO $msg \
                         $datasize $dist $code_"
  $self GoToSleep
  # Must wake up to hear cluster information from the base station. 
  set wakeUpTime [expr [$ns_ now] + $opt(finish_adv)]
  $ns_ at $wakeUpTime "$self WakeUp"
}
    

############################################################################
#
# Receiving Functions
#
############################################################################

LEACH/LEACH-C instproc recv {args} {

  global BS_CH_INFO DATA 

  set msg_type [[$self agent] set packetMsg_]
  set chID [lindex $args 0]
  set sender [lindex $args 1]
  set data_size [lindex $args 2]
  set msg [lrange $args 3 end]
  set nodeID [$self nodeID]

  if {$msg_type == $BS_CH_INFO} {
    $self recvBS_CH_INFO $msg
  } elseif {$msg_type == $DATA && $nodeID == $chID} {
    $self recvDATA $msg
  }

}

LEACH/LEACH-C instproc recvBS_CH_INFO {msg} {

    global opt ns_ node_

    $self instvar currentCH_ clusterNodes_ TDMAschedule_ 
    $self instvar now_ next_change_time_ dist_ code_
    $self instvar beginningE_ frame_time_ end_frm_time_ xmitTime_

    set next_change_time_ [expr $now_ + $opt(ch_change)]

    set clusters [lindex [lindex [lindex $msg 0] 0] 0]
    set id [$self nodeID]
    set my_ch [lindex $clusters $id]
    set currentCH_ $my_ch
    set CHnodes ""

    # Determine code for each cluster from BS information.
    foreach element $clusters {
      if {[lsearch $CHnodes $element] == -1} {
        set CHnodes [lappend CHnodes $element]
      }
    }
    $self setCode [expr [lsearch $CHnodes $my_ch] + 1]

    set outf [open $opt(dirname)/startup.energy a]
    puts $outf "[$ns_ now]\t$id\t[expr $beginningE_ - [[$self getER] query]]"
    close $outf

    # Determine slot in TDMA schedule from BS information.
    set i 0
    set sch ""
    foreach element $clusters {
      if {$element == $my_ch} {lappend sch $i}
      incr i
    }
    set TDMAschedule_ [join $sch]
    set clusterNodes_ $TDMAschedule_
    set frame_time_ [expr [expr 5 + [llength $TDMAschedule_]] * \
                          $opt(ss_slot_time)]

    puts "Node $id's CH is $my_ch, code is $code_ at time [$ns_ now]" 
    if {$my_ch == $id} {
      # Node is a CH for this round.  Record TDMA schedule.
      puts "CH $id: TDMAschedule is $TDMAschedule_"
      puts "*******************************************"
      $self WakeUp 
      $self setClusterHead
      set dist_ $opt(max_dist)
      set outf [open $opt(dirname)/TDMAschedule.[expr round($now_)].txt a]
      puts $outf "$my_ch\t$TDMAschedule_"
      close $outf
      if {[llength $TDMAschedule_] == 1} {
        puts "Warning!  There are no nodes in this cluster ($id)!"
        $self SendMyDataToBS
      }
    } elseif {$my_ch > -1} {
      # Node is a cluster member for this round.  Schedule a data
      # transmission to the cluster-head during TDMA slot.
      $self unsetClusterHead
      set dist_ [nodeDist [$self node] $node_($my_ch)]
      set ind [lsearch $TDMAschedule_ $id]
      if {$ind < 0} {
        puts "ERROR!!!!  $id does not have a transmit time!"
        exit 0
      }
      set xmitTime_ [expr $opt(ss_slot_time) * $ind]
      set end_frm_time_ [expr $frame_time_ - $xmitTime_]
      set xmitat [expr [$ns_ now] + $xmitTime_]
      if {[expr $xmitat + $end_frm_time_] < \
          [expr $next_change_time_ - 10 * $opt(ss_slot_time)]} {
        $ns_ at $xmitat "$self sendData"
      }
      $self GoToSleep 
    }

    # For LEACH-C, clusters are rotated at the beginning of each round.
    if {$opt(rcapp) == "LEACH/LEACH-C"} {
      $ns_ at $next_change_time_ "$self advertiseInfo"
    }

}

