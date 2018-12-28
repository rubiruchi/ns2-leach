/*************************************************************************
 *
 * This code was developed as part of the MIT SPIN project. (June, 1999)
 *
 *************************************************************************/


#include <stdlib.h>
#include <mit/rca/energy.h>

#define SUCCESS 0
#define SUCCESS_STRING "success"
#define FAIL -1
#define FAIL_STRING "fail"
#define ALARM 1
#define ALARM_STRING "alarm"

static class EnergyResourceClass : public TclClass {
public:
  EnergyResourceClass() : TclClass("Resource/Energy") {}
  TclObject* create(int, const char*const*) {
    return (new EnergyResource);
  }
} class_EnergyResource;

EnergyResource::EnergyResource() 
{
  energy_level_ = 0;
  alarm_level_ = 0;
  bind("energyLevel_",&energy_level_);
  bind("alarmLevel_",&alarm_level_);
  bind("expended_",&expended_);
}

int EnergyResource::command(int argc, const char*const* argv)
{
  Tcl& tcl = Tcl::instance();

  if (argc == 2) {
    if (strcmp(argv[1], "query") == 0) {
      double val = EnergyResource::query();
      tcl.resultf("%f",val);
      return TCL_OK;
    }
  }
  else
  if (argc == 3) {
    if (strcmp(argv[1], "add") == 0) {
      EnergyResource::add(atof(argv[2]));
      return TCL_OK;
    }
    else 
    if (strcmp(argv[1], "remove") == 0) {
      int val = EnergyResource::remove(atof(argv[2]));
      tcl.resultf("%s",EnergyResource::resulttostring(val));
      return TCL_OK;
    } 
    else
    if (strcmp(argv[1], "acquire") == 0) {
      double val = EnergyResource::acquire(atof(argv[2]));
      tcl.resultf("%f",EnergyResource::resulttostring((int)val));
      return TCL_OK;
    } 
  } 
  return Resource::command(argc, argv);
}

void EnergyResource::add(double amount)
{
  energy_level_ += amount;
}

int EnergyResource::remove(double amount)
{
  double new_level = energy_level_ - amount;
 if(new_level >= 0 )
      {
  energy_level_ = new_level;
  expended_ += amount;
	}
  if (new_level < 0)
    {
      return FAIL;
    }
  if (new_level < alarm_level_)
    {
      return ALARM;
    }
  return SUCCESS;
}

int EnergyResource::acquire(double amount)
{
  if ((energy_level_ - alarm_level_) < amount)
    {
      return FAIL;
    }

  return SUCCESS;
}

char *EnergyResource::resulttostring(int result)
{
  switch (result)
    {
    case SUCCESS:
      return SUCCESS_STRING;

    case FAIL:
      return FAIL_STRING;

    case ALARM:
      return ALARM_STRING;

    default:
      return NULL;
    }
  return NULL;
}
