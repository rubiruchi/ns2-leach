/*************************************************************************
 *
 * This code was developed as part of the MIT uAMPS project. (June, 2000)
 *
 *************************************************************************/


#ifdef MIT_uAMPS

#ifndef ns_bsagent_h
#define ns_bsagent_h

#include "math.h"
#include "object.h"
#include "agent.h"
#include "app.h"
#include "trace.h"
#include "packet.h"
#include "mac.h"
#include "random.h"


class BSAgent : public Agent {

public:
  BSAgent();
  ~BSAgent();
  void sendmsg(int data_size, const char* meta_data, int destination, 
               int sendto, double dist_to_dest, int code);
  void recv(Packet*, Handler*);
//  void log(const char *msg);
  void BSsetup(void);
  void itoa(int n, char s[]);
  double find_min_dist(double*, double*, int, double*, double*, int, 
                       int*, int*);
  int command(int argc, const char*const* argv);

  double nodesX_[1000];   // node X-coordinates
  double nodesY_[1000];   // node Y-coordinates
  double currentE_[1000]; // current node energies
  int p_;                // desired number of clusters per round  
  int iters_;            // num of iters for the sim annealing algorithm
  int nn_;               // total number of nodes in the network
  double max_epsilon_;   // amount of perturbation of CH coeffs
  int recv_code_;        // 0 == packet from ll, 1 == BS setup return

protected:
  int packetMsg_;        // message type
  int packetSize_;       // message size

private:
  NsObject *ll;          // link layer object 
  Mac *mac;              // MAC layer object
  Trace *log_target;     // log target
};

#endif


#endif /* MIT_uAMPS */
