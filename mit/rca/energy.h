/*************************************************************************
 *
 * This code was developed as part of the MIT SPIN project. (June, 1999)
 *
 *************************************************************************/


#ifndef energy_resource_h
#define energy_resource_h

#include <mit/rca/resource.h>

class EnergyResource ;

class EnergyResource : public Resource {
 private:
  int command(int argc, const char*const* argv);
  char *resulttostring(int result);
  double energy_level_;
  double alarm_level_;
  double expended_;

 public:
  EnergyResource();
  void add(double amount);
  int remove(double amount);
  int acquire(double amount);
  double query() { return energy_level_;}

};

#endif
