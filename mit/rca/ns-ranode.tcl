############################################################################
#
# This code was developed as part of the MIT SPIN project. (June, 1999)
#
############################################################################


Class MobileNode/ResourceAwareNode -superclass Node/MobileNode

MobileNode/ResourceAwareNode instproc init args {
    global ns_ opt wantslist tracefd

    $self instvar entry_point_
    $self instvar rca_agent_ rca_app_ ll_ mac_ ifq_ netif_
    $self instvar ResourceManager_ 

    set bs_node [lindex $args 0]

    eval $self next [lreplace $args 0 0]

    # Set up the resource manager
    set ResourceManager_ [new ResourceManager]
    $ResourceManager_ Register [new Resource/NeighborResource]
    set energy [new Resource/Energy]
    $ResourceManager_ Register $energy

    # Create a new agent and attach it to the node
    if {$bs_node == 1} {
      set agent [new Agent/BSAgent]
    } else {
      set agent [new Agent/RCAgent]
    }
    set rca_agent_ $agent

    # Stick a "receive" trace object between the
    # entry point and the agent.
    set rcvT [cmu-trace Recv "AGT" $self]
    $rcvT target $agent
    set entry_point_ $rcvT  

    # Add a Log Target
    set T [new Trace/Generic]
    $T target [$ns_ set nullAgent_]
    $T attach $tracefd
    $T set src_ [$self id]
    $rca_agent_ log-target $T

    # Attach an application to the agent
    set haslist [find_haslist [$self id]]
    if {$bs_node == 1} {
      set rca [new $opt(bsapp)]
    } else {
      set rca [new $opt(rcapp) $opt(mtype) $wantslist $haslist]
    }
    $ns_ attach-agent $self $agent
    $rca attach-agent $agent

    set rca_app_ $rca
}

# By defining this entry point function to return
# the agent, we circumvent the address classifiers
MobileNode/ResourceAwareNode instproc entry {} {

     $self instvar entry_point_ rca_agent_

     return $entry_point_
 }

MobileNode/ResourceAwareNode instproc start-app {} {
    $self instvar rca_app_

    $rca_app_ start
}

MobileNode/ResourceAwareNode instproc getResourceManager {} {
  $self instvar ResourceManager_
  return $ResourceManager_
}

MobileNode/ResourceAwareNode instproc add-interface {args} {
#    args are expected to be of the form
#    $chan $prop $opt(ll) $opt(mac) $opt(ifq) $opt(ifqlen) $opt(netif)
#    $opt(ant) $opt(inerrproc) $opt(outerrproc) $opt(fecproc)
    global ns_ opt

    $self instvar nifs_ 

    set t $nifs_

    eval $self next $args

    $self instvar rca_agent_ ll_ mac_ ifq_ nifs_ netif_

    # Stick a "send" trace object between the
    # RC agent and the link layer
    set sndT [cmu-trace Send "AGT" $self]
    $sndT target $ll_($t)

    # Attach the agent to its link-layer
    $rca_agent_ add-ll $sndT $mac_(0)

    # Attach the energy resource to the network interface
    set energy [$self getER]

    $netif_($t) attach-energy $energy

}

MobileNode/ResourceAwareNode instproc add-neighbor p {
    $self instvar ResourceManager_
    set nr [$ResourceManager_ getResourceByType Resource/NeighborResource]
    if {[$self info class] == "ResourceAwareMobileNode/WirelessRANode"} {
      set d [dist [$self set X_] [$self set Y_] [$p set X_] [$p set Y_]]
      $nr add $p $d
    } else {
      $nr add $p
    }
    $self next $p
}

MobileNode/ResourceAwareNode instproc set-energy {energyLevel alarmLevel} {
    $self instvar ResourceManager_
    set er [$ResourceManager_ getResourceByType Resource/Energy]
    set l [$er set energyLevel_]
    $er setParams $energyLevel $alarmLevel
    set l [$er set energyLevel_]
}

#
# This function queries the ResourceManager to determine the current 
# neighbors for this node.
#
MobileNode/ResourceAwareNode instproc neighbors {} {
    $self instvar ResourceManager_
  
    set nr [$ResourceManager_ getResourceByType Resource/NeighborResource] 
    return [$nr query all]
}

#
# This function queries the ResourceManager to determine the current 
# energy levels for this node.
#
MobileNode/ResourceAwareNode instproc energy {} {
    $self instvar ResourceManager_
  
    set er [$ResourceManager_ getResourceByType Resource/Energy] 
    return [$er query]
}

#
# This function returns the EnergyResource from the ResourceManager 
#
MobileNode/ResourceAwareNode instproc getER {} {
    $self instvar ResourceManager_
  
    set er [$ResourceManager_ getResourceByType Resource/Energy] 
    return $er
}

MobileNode/ResourceAwareNode instproc getResourceAwareNode {} {  
  return $self
}
