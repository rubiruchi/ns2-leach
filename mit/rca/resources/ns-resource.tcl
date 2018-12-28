############################################################################
#
# This code was developed as part of the MIT SPIN project. (jk, wbh 3/24/00)
#
############################################################################


# Resource Class
#
# Most Resources functions are "virtual".  We define all of the
# functions to do nothing.  When you derive from the Resource
# class, you should define your implementation of each function.

Class Resource

Resource instproc init args {
}

Resource instproc add {args} {
  
    puts stderr "Warning: add function not implemented yet for this object"
}

Resource instproc remove {args} {
  
    puts stderr "Warning: remove function not implemented yet for this object"
}
   
Resource instproc acquire {args} {
  
    puts stderr "Warning: acquire function not implemented yet for this object"
}

Resource instproc query {args} {
  
  puts stderr "Warning: query function not implemented yet for this object"
}



