############################################################################
#
# This code was developed as part of the MIT SPIN project. (jk, wbh 3/24/00)
#
############################################################################


# Energy Resource
# Note: energyLevel_ is measured in Joules

Resource/Energy instproc setParams {args} {
    $self instvar energyLevel_ alarmLevel_
    set energyLevel_ [lindex $args 0]
    set alarmLevel_ [lindex $args 1]
}

Resource/Energy instproc query {args} {
    $self instvar energyLevel_ 
    return $energyLevel_ 
}

