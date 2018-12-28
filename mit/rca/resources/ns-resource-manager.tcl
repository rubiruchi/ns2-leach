############################################################################
#
# This code was developed as part of the MIT SPIN project. (jk, wbh 3/24/00)
#
############################################################################


# ResourceManager Class
#
# This is an abstract super class of resource manager. The functions Query,
# Request and Update are virtual.

Class ResourceManager

ResourceManager instproc init {args} {

    eval $self next $args
    $self instvar arrayOfResources_ arrayOfOperation_
    set arrayOfResources_ {}
    set arrayOfOperation_ {}
}

ResourceManager instproc getResourceByType resourceType {

    $self instvar arrayOfResources_

    # go through each element of the resource array, find the matched type

    foreach obj $arrayOfResources_ {
        if { [$obj info class] == $resourceType } {
            return $obj
        }
    }

    return {}
}


ResourceManager instproc Register resourceObj {

    $self instvar arrayOfResources_

    # check if this type of resource have been registered before. Currently
    # the resource manager only register non-duplicate type of resources.

    set r [$resourceObj info class]

    if { [$self getResourceByType $r] != {} } {

        puts "This type of resource ( $r ) have been registered in resource manager before."
        return -1
    }

    # add this object to resource list
    lappend arrayOfResources_ $resourceObj

    return 1
}

# The Query function return a list of resource objects, which match the input
# resource types given by args

ResourceManager instproc Query {args} {

    $self instvar arrayOfResources_

    # if want to fetch all the resource objects

    if { [lsearch $args all] != -1 } {
      return $arrayOfResources_
    }

    # for each resource type in the args, get the corresponding resource in 
    # the resource array, and append to the return list
 
    set ret {}
    foreach rsType $args {
      if { [set obj [$self getResourceByType $rsType]] != {} } {
        lappend ret $obj
      }
    }

    return $ret
}

ResourceManager instproc Request {args} {

    puts stderr "Warning: Request function not implemented yet for this object"

}

ResourceManager instproc Update {args} {

    puts stderr "Warning: Update function not implemented yet for this object"
}
