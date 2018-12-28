############################################################################
#
# This code was developed as part of the MIT SPIN project. (jk, wbh 3/24/00)
#
############################################################################


# Neighbor Descriptor Class

Class NeighborDescriptor

NeighborDescriptor instproc init args {
    $self instvar id_ 
    set id_ ""
}

NeighborDescriptor instproc setId args {
  $self instvar id_
  if {$args != {}} {
    set id_ $args
  }
  return $id_
}

NeighborDescriptor instproc getType {} {
  return "wired"
}

# WirelessNeighbor Class

Class WirelessNeighborDescriptor -superclass NeighborDescriptor

WirelessNeighborDescriptor instproc init args {
    eval $self next $args
    $self instvar distance_
    set distance_ 0 
}

WirelessNeighborDescriptor instproc setDistance args {
  $self instvar distance_
  if {$args != {}} {
    set distance_ $args
  }
  return $distance_
}

WirelessNeighborDescriptor instproc getType {} {
  return "wireless"
}


# Neighbor Resources

Class Resource/NeighborResource -superclass Resource

Resource/NeighborResource instproc init args {
    eval $self next $args
    $self instvar available_flag_ neighbor_list_
    set available_flag_ 1
    set neighbor_list_ ""
}

# Querying for a specific ID returns the descriptor for that ID.
# If that ID is not available, we return "".

Resource/NeighborResource instproc query id {
    $self instvar neighbor_list_

    if {$id == "all"} {
      set retstr ""
      foreach n $neighbor_list_ {
        lappend retstr [$n setId]
      }
      return $retstr
    }
    
    foreach n $neighbor_list_ {
      if {$id == [$n setId]} {
        return [$n setId]
      }
    }

    return ""
}

# Querying for a specific ID returns the descriptor for that ID
# and the distance, if the desc is a wireless neighbor.
# If that ID is not available, we return "".

Resource/NeighborResource instproc query_ext id {
    $self instvar neighbor_list_

    if {$id == "all"} {
      return $neighbor_list_
    }
    
    foreach n $neighbor_list_ {
      if {$id == [$n setId]} {
        return $n 
      }
    }

    return ""
}

# Add a list of neighbors to the current list of neighbors

Resource/NeighborResource instproc getindex id { 
    $self instvar neighbor_list_

    set index 0
    foreach desc $neighbor_list_ {
      if {[$desc setId] == $id} {
        return $index
      }
      incr index
    }
    return -1
}

# Remove a neighbor from the neighbor list

Resource/NeighborResource instproc remove desc {
    $self instvar neighbor_list_

    set id $desc 
    set index [$self getindex $id]
    set newlist [lreplace $neighbor_list_ $index $index]
    set neighbor_list_ $newlist
}
  
# Add a neighbor to the neighbor list.  Only one entry
# per id is allowed.  Any previous entries for this id
# will be deleted.

Resource/NeighborResource instproc add {desc args} {
    $self instvar neighbor_list_

    set id $desc
    set index [$self getindex $id]
    if {$index != -1} {
      set neighbor_list_ [lreplace $neighbor_list_ $index $index]
    }

    if {$args == {}} {
      set new_neighbor [new NeighborDescriptor]
    } else {
      set new_neighbor [new WirelessNeighborDescriptor]
    }
    set neighbor_list_ [concat $new_neighbor $neighbor_list_ ]
    $new_neighbor setId $desc
    if {$args != {}} {
      $new_neighbor setDistance $args
    }
}
