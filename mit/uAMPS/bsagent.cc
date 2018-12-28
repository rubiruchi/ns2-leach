/*************************************************************************
 *
 * This code was developed as part of the MIT uAMPS project. (June, 2000)
 *
 *************************************************************************/


#ifdef MIT_uAMPS

#include "bsagent.h"

static class BSAgentClass : public TclClass {
public:
  BSAgentClass() : TclClass("Agent/BSAgent") {}
  TclObject* create(int, const char*const*) {
    return (new BSAgent());
  }
} class_bs_agent;

BSAgent::BSAgent() : Agent(PT_RCA)
{
  ll = 0;

  bind("packetSize_", &size_);
  bind("packetMsg_", &packetMsg_);
  bind("recv_code_", &recv_code_);
}

BSAgent::~BSAgent()
{
}

int
BSAgent::command(int argc, const char*const* argv)
{
  TclObject *obj;  
  Tcl& tcl = Tcl::instance();

  if (argc == 2) {
    if(strcmp(argv[1], "BSsetup") == 0) {
      BSAgent::BSsetup();
      return TCL_OK;
    }
  } else if (argc == 3) {
    if(strcmp(argv[1], "log-target") == 0) {
      log_target = (Trace*) TclObject::lookup(argv[2]);
      if(log_target == 0)
        return TCL_ERROR;
      return TCL_OK;
    } else if(strcmp(argv[1], "log") == 0) {
      //log(argv[2]);
      return TCL_OK;
    }
  } else if (argc == 4)  {
    if (strcasecmp(argv[1], "add-ll") == 0) {
      if( (obj = TclObject::lookup(argv[2])) == 0) {
        fprintf(stderr, "BSAgent: %s lookup of %s failed\n", argv[1],
          argv[2]);
        return TCL_ERROR;
      }
      ll = (NsObject*) obj;
      if( (obj = TclObject::lookup(argv[3])) == 0) {
        fprintf(stderr, "BSAgent: %s lookup of %s failed\n", argv[1],
          argv[2]);
        return TCL_ERROR;
      }
      mac = (Mac*) obj;
      return TCL_OK;
    }
  }
  if (strcmp(argv[1], "transfer_info") == 0) {
    if (argc == 6) {
      nn_ = atoi(argv[2]);
      p_ = atoi(argv[3]);
      iters_ = atoi(argv[4]);
      max_epsilon_ = atof(argv[5]);
      return TCL_OK;
    } else {
      fprintf(stderr, "BSAgent: %s needs argc == 6\n", argv[1]);
      return TCL_ERROR;
    }
  } else if (strcmp(argv[1], "append_info") == 0) {
    if (argc == 6) {
      nodesX_[atoi(argv[2])] = atof(argv[3]);
      nodesY_[atoi(argv[2])] = atof(argv[4]);
      currentE_[atoi(argv[2])] = atof(argv[5]);
      return TCL_OK;
    } else {
      fprintf(stderr, "BSAgent: %s needs argc == 6\n", argv[1]);
      return TCL_ERROR;
    }
  } 
  
 if (strcmp(argv[1], "sendmsg") == 0) {
    if (argc < 5) {
      fprintf(stderr, "BSAgent: %s needs argc >= 5\n", argv[1]);
      return TCL_ERROR;
    }
    int mac_dst;
    if (Tcl_GetInt(tcl.interp(),(char *)argv[4], &mac_dst) != TCL_OK) {
        fprintf(stderr, "BSAgent: could not convert %s to int\n", argv[4]);
       return TCL_ERROR;
    }
    if (argc == 5) {
        BSAgent::sendmsg(atoi(argv[2]), argv[3], mac_dst, -1, 10, 0);
        return (TCL_OK);
    }
    int link_dst;
    if (Tcl_GetInt(tcl.interp(),(char *)argv[5], &link_dst) != TCL_OK) {
        fprintf(stderr, "BSAgent: could not convert %s to int\n", argv[5]);
       return TCL_ERROR;
    }
    if (argc == 6) {
        BSAgent::sendmsg(atoi(argv[2]), argv[3], mac_dst, link_dst, 10, 0);
         return (TCL_OK);
    }
    double dist_to_dest;
    if (Tcl_GetDouble(tcl.interp(),(char *)argv[6], &dist_to_dest) != TCL_OK) {
        fprintf(stderr, "BSAgent: could not convert %s to double\n", argv[6]);
        return TCL_ERROR;
    }
    if (argc == 7) {
        BSAgent::sendmsg(atoi(argv[2]),argv[3],mac_dst,link_dst,dist_to_dest,0);
        return (TCL_OK);
    }
    int code;
    if (Tcl_GetInt(tcl.interp(),(char *)argv[7], &code) != TCL_OK) {
        fprintf(stderr, "BSAgent: could not convert %s to int\n", argv[7]);
         return TCL_ERROR;
    }
    if (argc == 8) {
        BSAgent::sendmsg(atoi(argv[2]), argv[3], mac_dst, link_dst, dist_to_dest, code);
        return (TCL_OK);
    } else {
        fprintf(stderr, "BSAgent: %s needs argc <= 8\n", argv[1]);
        return TCL_ERROR;
    }
  }

  return Agent::command(argc, argv);
}

/* ======================================================================
   This function is used when the base station sends a message to the
   sensor nodes.  The appropriate packet header information is set and
   the packet is passed to the link-layer.
   ====================================================================== */
void BSAgent::sendmsg(int data_size, const char* meta_data, int mac_dst, 
                      int link_dst, double dist_to_dest, int code) 
{

  Packet *p = allocpkt();
  hdr_cmn *hdr = HDR_CMN(p);
  hdr->size() = data_size;

  hdr_rca *rca_hdr = HDR_RCA(p);
  rca_hdr->msg_type() = packetMsg_;
  rca_hdr->set_meta(meta_data);
  rca_hdr->rca_mac_dst() = mac_dst;
  rca_hdr->rca_link_dst() = link_dst;
  rca_hdr->rca_src() = mac->addr();
  rca_hdr->get_dist() = dist_to_dest;
  rca_hdr->get_code() = code;

  hdr_mac* mh = HDR_MAC(p);
  mh->set(MF_DATA, mac->addr(), mac_dst);

  /*
  printf("Sending: Type=%d data_size=%d\n\tMeta=%s\n\tSource=%d\n\t
          Target=%d\n ",rca_hdr->msg_type(), hdr->size(), rca_hdr->meta(),
          rca_hdr->rca_src(),rca_hdr-> rca_mac_dst());
  fflush(stdout);
  Packet::PrintRcHeader(p,"BSAgent");
  */

  Scheduler::instance().schedule(ll, p, 0); 
  
  return;
}

/* ======================================================================
   This function is called when the base station receives a packet from
   the link-layer that must be passed up to the application. 
   ====================================================================== */
void BSAgent::recv(Packet* p, Handler*)
{
  hdr_cmn *hdr = HDR_CMN(p);
  hdr_rca *rca_hdr = HDR_RCA(p);

  packetMsg_ = rca_hdr->msg_type();

  /*
  printf("Receiving: Link_dst = %d, Type=%d data_size=%d\n\tMeta = %s, 
          source = %d\n",rca_hdr->rca_link_dst(),rca_hdr->msg_type(), 
          hdr->size(), rca_hdr->meta(),rca_hdr->rca_src());
  fflush(stdout);
  */

  /*
   * Recv_code: 0 == packet from ll, 1 == BS setup return.
   */
  recv_code_ = 0;
  if (app_)
    app_->recv(rca_hdr->rca_link_dst(), hdr->size(), rca_hdr->meta(),
               rca_hdr->rca_src());

  Packet::free(p);
}

/*void BSAgent::log(const char *msg)
{
  if (!log_target) return;
  Scheduler& s = Scheduler::instance();
  sprintf(log_target->buffer(), "C %.5f %s", s.clock(), msg);
  log_target->dump();
}*/

/* ======================================================================
   The TCL application calls this function to find clusters for the 
   centralized algorithm.  The base station runs a simulated annealing 
   algorithm to determine the set of nodes that minimize the sum of
   squared distances between the non-cluster-head nodes and the
   cluster-head nodes.  Only nodes with energy above the mean 
   are eligible to become cluster-heads. 
   ====================================================================== */
void BSAgent::BSsetup(void)
{
  int randnode, last_iter = 0;
  double ck, cost, min_cost;    // parameters for the sim ann alg
  double *prob;                 // sim ann probs for iteration k
  double *ch_X, *ch_Y;          // current CH node coordinates
  double *new_X, *new_Y;        // randomly perturbed (X,Y) corrds
  double *new_ch_X, *new_ch_Y;  // possible new CH node coordinates
  int *eligible, *all_nodes;    // nodes that can be CH for current round
  int *clusters;                // cluster numbers 
  int *cluster_index;           // node number of CH for each node
  int *ch_index;                // CH node number 
  int *new_ch_index;            // possible new CH node number 

  prob = new double[iters_]; 
  ch_X = new double[p_];
  ch_Y = new double[p_];
  new_ch_X = new double[p_];
  new_ch_Y = new double[p_];
  new_X = new double[p_];
  new_Y = new double[p_];

  eligible = new int[nn_];
  all_nodes = new int[nn_];
  cluster_index = new int[nn_];
  clusters = new int[nn_];
  ch_index = new int[p_];
  new_ch_index = new int[p_];

  /* 
   * Compute the average energy per node.  Only nodes with energy above
   * the average are eligible to be cluster-head nodes during this round. 
   */
  double avg_energy=0; 
  for (int i = 0; i < nn_; i++)
    avg_energy += currentE_[i];
  avg_energy /= nn_;

  for (int i = 0; i < nn_; i++) {
    all_nodes[i] = 1;
    if (currentE_[i] < avg_energy) 
      eligible[i] = 0;
    else
      eligible[i] = 1;
  }

  /*
   * Find an initial set C of p_ nodes for the simulated annealing 
   * algoirthm. 
   */
  int i = 0;
  int is_ok = 1;   // check to make sure all p_ nodes are distinct
  while (i < p_) {
    randnode = Random::integer(nn_); 
    if (eligible[randnode]) {
      is_ok = 1;
      for (int j=0; j<i; j++) 
        if (randnode == ch_index[j]) is_ok = 0;
      if (is_ok) {
        ch_index[i] = randnode;
        ch_X[i] = nodesX_[randnode];
        ch_Y[i] = nodesY_[randnode];
        i++;
      }
    } 
  }

  /* 
   * Find the cost of set C, the initial list of CH nodes and the
   *  assignment of nodes to clusters.
   */
  min_cost = find_min_dist(nodesX_, nodesY_, nn_,
                           ch_X, ch_Y, p_, cluster_index, all_nodes);
  for (int i = 0; i < nn_; i++) {
    clusters[i] = ch_index[cluster_index[i]];
  }

  /* 
   * Iterate iters_ number of times to find the optimum set of cluster-head
   * nodes using simulated annealing.
   */
  for (int k = 0; k < iters_; k++) {
    /* 
     * Find a new set C' that is a set of nodes that are random 
     * perturbations of the (X,Y) coordinates of the nodes in C. 
     */
    for (int i = 0; i < p_; i++) {
      new_X[i] = ch_X[i] + Random::uniform(-max_epsilon_, max_epsilon_); 
      new_Y[i] = ch_Y[i] + Random::uniform(-max_epsilon_, max_epsilon_); 
    }
    /* 
     * Since the cluster-head nodes must exist, the new set must map to 
     * the nodes with the closest (X,Y)-corrdiates to create C'. 
     */ 
    find_min_dist(new_X, new_Y,p_, nodesX_, nodesY_, nn_, 
                  new_ch_index, eligible);
    for (int i = 0; i < p_; i++) {
      new_ch_X[i] = nodesX_[new_ch_index[i]];
      new_ch_Y[i] = nodesY_[new_ch_index[i]];
    }

    /* 
     * Find the cost of set C'.
     */
    cost = find_min_dist(nodesX_,nodesY_,nn_,
                         new_ch_X,new_ch_Y,p_,cluster_index, all_nodes);
    /* 
     * If cost(C') < cost(C), C' becomes new optimum.  Otherwise, C' may
     * still become new optimum with a non-zero probability set below. 
     */
    ck = 1000 * exp(-k / 20);
    prob[k] = (cost < min_cost ? 1 : cost == min_cost ? 0 :
                                     exp(-(cost - min_cost) / ck));
    if (Random::uniform(0.0,1.0) <= prob[k]) {
      for (int i = 0; i < p_; i++) {
        ch_X[i] = new_ch_X[i];
        ch_Y[i] = new_ch_Y[i];
        ch_index[i] = new_ch_index[i];
      }
      min_cost = cost;
      last_iter = k;
      for (int i = 0; i < nn_; i++) {
        clusters[i] = new_ch_index[cluster_index[i]];
      }
    }
  }
  printf("Min_cost = %f\nlast_iter = %d\nCH are:\n", min_cost, last_iter);
  for (int i=0; i<p_; i++) 
    printf("%f\t%f\t%d\n", ch_X[i], ch_Y[i], ch_index[i]);
  fflush(stdout);

  /* 
   * This is needed to pass Tcl the cluster-head information as a string.
   */
  char *char_clusters = new char[10*nn_];
  char *holder = char_clusters;
  for (int i=0; i<nn_; i++) {
    if (currentE_[i] > 0) 
      itoa(clusters[i], holder);
    else 
      itoa(-1, holder);
    holder += strlen(holder);
    *holder = ' ';
    holder += 1;
  }
  *holder = '\0';

  /*
   * Recv_code: 0 == packet from ll, 1 == BS setup return.
   */
  recv_code_ = 1;
  app_->recv(char_clusters);

  delete[] prob; 
  delete[] ch_X; 
  delete[] ch_Y;
  delete[] new_ch_X;
  delete[] new_ch_Y;
  delete[] new_X;
  delete[] new_Y;

  delete[] eligible;
  delete[] all_nodes;
  delete[] cluster_index;
  delete[] clusters;
  delete[] ch_index;
  delete[] new_ch_index;

}

/* ======================================================================
   This function is converts an integer to a string representation.
   ====================================================================== */
void BSAgent::itoa(int n, char s[])
{
  int i, sign, j, c;

  if ((sign = n) < 0)  n = -n;
  i = 0;
  do {
    s[i++] = n % 10 + '0';
  } while ((n /= 10) > 0);
  if (sign < 0)
    s[i++] = '-';
  s[i] = '\0';
  // reverse function
  for (i = 0, j = strlen(s)-1; i < j; i++, j--) {
    c = s[i];
    s[i] = s[j];
    s[j] = c;
  }
}

/* ======================================================================
   This function finds the minimum distance between two sets of nodes,
   C1 = {(X1, Y1)} of size size1 and C2 = {(X2, Y2)} of size size2, 
   using only nodes from C2 that are eligible.
   ====================================================================== */
double BSAgent::find_min_dist(double* X1, double* Y1, int size1, 
                               double* X2, double* Y2, int size2,
                               int* ch_index, int* eligible) 
{
    int new_index;
    double cost = 0, dsquare;
    double min_dist;

    for (int i = 0; i < size1; i++) {
      min_dist = 1000000;
      for (int j = 0; j < size2; j++) {
        if (eligible[j]) {
          dsquare = (X1[i] - X2[j]) * (X1[i] - X2[j]) + 
                    (Y1[i] - Y2[j]) * (Y1[i] - Y2[j]);
          if (dsquare < min_dist) {
            min_dist = dsquare;
            new_index = j;
          }
        }
      }
      cost += min_dist;
      ch_index[i] = new_index;
    }
    return cost;
}

#endif /* MIT_uAMPS */
