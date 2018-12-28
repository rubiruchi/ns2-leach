############################################################################
#
# This code was developed as part of the MIT uAMPS project. (June, 2000)
#
############################################################################


Class LEACH-C/StatClustering -superclass LEACH/LEACH-C

LEACH-C/StatClustering instproc init args {
  $self next $args
}


############################################################################
#
# Static clustering is the same as LEACH-C except there is no rotation.
# Therefore, nodes always send data in given slot.
#
############################################################################

LEACH-C/StatClustering instproc sendData {} {

  global ns_ DATA MAC_BROADCAST BYTES_ID opt

  $self instvar currentCH_ dist_ code_ frame_time_ alive_

  $self WakeUp 
  set nodeID [$self nodeID]
  set msg [list [list $nodeID , [$ns_ now]]]
  # Use DS-SS to send data messages to avoid inter-cluster interference.
  set spreading_factor $opt(spreading)
  set datasize [expr $spreading_factor * \
               [expr [expr $BYTES_ID * [llength $msg]] + $opt(sig_size)]]

  pp "$nodeID sending data $msg to $currentCH_ at [$ns_ now]"
  set mac_dst $MAC_BROADCAST
  set link_dst $currentCH_
  $self send $mac_dst $link_dst $DATA $msg $datasize $dist_ $code_

  # Static-clustering nodes always transmit once per frame
  set xmitat [expr [$ns_ now] + $frame_time_]
  if {$alive_} {
    $ns_ at $xmitat "$self sendData"
  }

  set sense_energy [expr $opt(Esense) * $opt(sig_size) * 8]
  pp "Node $nodeID removing sensing energy = $sense_energy J."
  [$self getER] remove $sense_energy

  if {$currentCH_ != $nodeID} {
    $self GoToSleep 
  }
}

