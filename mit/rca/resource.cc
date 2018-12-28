/*************************************************************************
 *
 * This code was developed as part of the MIT SPIN project. (June, 1999)
 *
 *************************************************************************/


#include <mit/rca/resource.h>

static class ResourceClass : public TclClass {
public:
  ResourceClass() : TclClass("Resource") {}
  TclObject* create(int, const char*const*) {
    return (new Resource);
  }
} class_resource;

Resource::Resource()
{
}

Resource::~Resource()
{
}
  
