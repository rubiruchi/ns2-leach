/*************************************************************************
 *
 * This code was developed as part of the MIT SPIN project. (June, 1999)
 *
 *************************************************************************/

#ifdef MIT_uAMPS

#include "object.h"
#include "agent.h"
#include "trace.h"
#include "packet.h"
#include "scheduler.h"

#include "mac.h"
#include "ll.h"
#include "cmu-trace.h"

#include "rcagent.h"
#include "rtp.h"
#include "random.h"
#include "ip.h"

#include "mac-sensor.h"

static class RCAgentClass : public TclClass {
public:
  RCAgentClass() : TclClass("Agent/RCAgent") {}
  TclObject* create(int, const char*const*) {
    return (new RCAgent());
  }
} class_rc_agent;

RCAgent::RCAgent() : Agent(PT_RCA)
{
  ll = 0;

  bind("packetSize_", &size_);
  bind("packetMsg_", &packetMsg_);
  bind("distEst_", &distEst_);
}

RCAgent::~RCAgent()
{
}

int
RCAgent::command(int argc, const char*const* argv)
{
  TclObject *obj;  
  Tcl& tcl = Tcl::instance();

  if (argc == 3) {
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
        fprintf(stderr, "RCAgent: %s lookup of %s failed\n", argv[1],
          argv[2]);
        return TCL_ERROR;
      }
      ll = (NsObject*) obj;
      if( (obj = TclObject::lookup(argv[3])) == 0) {
        fprintf(stderr, "RCAgent: %s lookup of %s failed\n", argv[1],
          argv[2]);
        return TCL_ERROR;
      }
      mac = (Mac*) obj;
      return TCL_OK;
    }
  } 
  
  if (strcmp(argv[1], "sendmsg") == 0) {
    if (argc < 5) {
      fprintf(stderr, "RCAgent: %s needs argc >= 5\n", argv[1]);
      return TCL_ERROR;
    } 
    int mac_dst;
    if (Tcl_GetInt(tcl.interp(),(char *)argv[4], &mac_dst) != TCL_OK) {
        fprintf(stderr, "RCAgent: could not convert %s to int\n", argv[4]);
        return TCL_ERROR;
    }
    if (argc == 5) {
        RCAgent::sendmsg(atoi(argv[2]), argv[3], mac_dst, -1, 10, 0);
        return (TCL_OK);
    }
    int link_dst;
    if (Tcl_GetInt(tcl.interp(),(char *)argv[5], &link_dst) != TCL_OK) {
        fprintf(stderr, "RCAgent: could not convert %s to int\n", argv[5]);
        return TCL_ERROR;
    }
    if (argc == 6) {
        RCAgent::sendmsg(atoi(argv[2]), argv[3], mac_dst, link_dst, 10, 0);
        return (TCL_OK);
    }
    double dist_to_dest;
    if (Tcl_GetDouble(tcl.interp(),(char *)argv[6], &dist_to_dest) != TCL_OK) {
        fprintf(stderr, "RCAgent: could not convert %s to double\n", argv[6]);
        return TCL_ERROR;
    }
    if (argc == 7) {
        RCAgent::sendmsg(atoi(argv[2]),argv[3],mac_dst,link_dst,dist_to_dest,0);
        return (TCL_OK);
    }
    int code;
    if (Tcl_GetInt(tcl.interp(),(char *)argv[7], &code) != TCL_OK) {
        fprintf(stderr, "RCAgent: could not convert %s to int\n", argv[7]);
        return TCL_ERROR;
    }
    if (argc == 8) {
        RCAgent::sendmsg(atoi(argv[2]), argv[3], mac_dst, link_dst, dist_to_dest, code);
        return (TCL_OK);
    } else {
        fprintf(stderr, "RCAgent: %s needs argc <= 8\n", argv[1]);
        return TCL_ERROR;
    }
  }

  return Agent::command(argc, argv);
}

void RCAgent::sendmsg(int data_size, const char* meta_data, int mac_dst, int link_dst, double dist_to_dest, int code) 
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

  //printf("Sending: Type=%d data_size=%d\n\tMeta=%s\n\tSource=%x\n\tTarget=%x\n",rca_hdr->msg_type(), hdr->size(), rca_hdr->meta(),rca_hdr->rca_src(),rca_hdr->rca_mac_dst());
  //printf("\tLink_dst = %x\n",rca_hdr->rca_link_dst());
  //fflush(stdout);

  //Packet::PrintRcHeader(p,"RCAgent");

  Scheduler::instance().schedule(ll, p, 0); 
  
  return;
}

void RCAgent::recv(Packet* p, Handler*)
{
  hdr_cmn *hdr = HDR_CMN(p);
  hdr_rca *rca_hdr = HDR_RCA(p);

  //printf("Receiving: Link_dst = %x, Type=%d data_size=%d\n\tMeta = %s, source = %d\n",rca_hdr->rca_link_dst(),rca_hdr->msg_type(), hdr->size(), rca_hdr->meta(),rca_hdr->rca_src());
  //fflush(stdout);

  packetMsg_ = rca_hdr->msg_type();
  distEst_ = rca_hdr->dist_est();

  if (app_)
    app_->recv(rca_hdr->rca_link_dst(), hdr->size(), rca_hdr->meta(),
               rca_hdr->rca_src());

  /*
   * didn't expect packet (or we're a null agent?)
   */
  Packet::free(p);
}


/*void RCAgent::log(const char *msg)
{
  if (!log_target) return;

  Scheduler& s = Scheduler::instance();

  sprintf(log_target->buffer(),
    "C %.5f %s",
    s.clock(),
    msg);
  log_target->dump();
}*/

#endif
