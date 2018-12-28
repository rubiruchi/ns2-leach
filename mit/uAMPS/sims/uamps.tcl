############################################################################
#
# This code was developed as part of the MIT uAMPS project. (June, 2000)
#
############################################################################

global opt bs

source /home/pradeepkumar/ns-allinone-2.35/ns-2.35/mit/rca/ns-ranode.tcl
source /home/pradeepkumar/ns-allinone-2.35/ns-2.35/mit/uAMPS/ns-bsapp.tcl
source /home/pradeepkumar/ns-allinone-2.35/ns-2.35/mit/uAMPS/extras.tcl
source /home/pradeepkumar/ns-allinone-2.35/ns-2.35/mit/uAMPS/stats.tcl
#Uncomment these lines to use gdb to debug the c code
#source mit/uAMPS/ns-bsapp.tcl
#source mit/uAMPS/extras.tcl
#source mit/uAMPS/stats.tcl
source /home/pradeepkumar/ns-allinone-2.35/ns-2.35/mit/rca/resources/ns-resource-manager.tcl
source /home/pradeepkumar/ns-allinone-2.35/ns-2.35/mit/rca/resources/ns-energy-resource.tcl
source /home/pradeepkumar/ns-allinone-2.35/ns-2.35/mit/rca/resources/ns-neighbor-resource.tcl

# ========================================================================
# Default Script Options
# ========================================================================

set opt(bsapp)        "Application/BSApp" ;# BS application type
set opt(mtype)         ""                 ;# No meta-data used 
set opt(nn_)          [expr $opt(nn) - 1] ;# Number of non-BS nodes
set opt(bsID)         $opt(nn_)           ;# BS node number
set opt(bsCode)       0                   ;# Spreading code for BS
set opt(quiet)        1                   ;# 0=print info, 1=quiet

set opt(bw)           1e6                 ;# 1 Mbps radio speed
set opt(delay)        1e-12               ;# Links delay
set opt(prop_speed)   3e8;                ;# Meters per second
set opt(ll)           RCALinkLayer        ;# Arpless link-layer
set opt(mac)          Mac/Sensor          ;# Sensor mac pr	otocol
set opt(ifq)          Queue/DropTail      ;# DropTail Q
set opt(ifqlen)       100                 ;# Max packets in ifq
set opt(netif)        Phy/WirelessPhy     ;# Wireless channel
set opt(ant)          Antenna/OmniAntenna ;# Omnidirectional antena

# Time required to transmit numbytes bytes of data
proc TxTime {numbytes} {
  global opt
  return [expr $numbytes*8/$opt(bw)]
}

set opt(hdr_size)     25                  ;# Bytes for header
set opt(sig_size)     500                 ;# Bytes for data signal
# Packet transmission time
set opt(slot_time)    [expr [TxTime [expr $opt(sig_size)+$opt(hdr_size)]]]
# Spread-spectrum packet transmission time
set opt(ss_slot_time) [expr $opt(slot_time) * $opt(spreading)]
# Maximum TDMA frame time (if all nodes in one cluster)
set opt(frame_time)   [expr $opt(ss_slot_time) * $opt(nn_)]

set opt(ch_change)    [expr 10 * $opt(init_energy)]  ;# Time for each round
set opt(check_energy) 10                             ;# Time btwn energy traces 

set opt(freq)          914e+6             ;# Carrier frequency
set opt(L)             1.0                ;# System (non-propogation) loss
set opt(Gt)            1.0                ;# Tx antenna gain
set opt(Gr)            1.0                ;# Rx antenna gain
set opt(ht)            1.5                ;# Antenna height
set opt(CSThresh)      1e-9               ;# Receive threshold is 1 nW
set opt(RXThresh)      6e-9               ;# Success threshold is 6 nW
set PI                 3.1415926
set l                  [expr 3e8 / $opt(freq)]    ;# Wavelength of carrier

############################################################################
#
# Energy Models
#
############################################################################

# Efriss_amp = RXThresh * (4pi)^2 / (Rb Gt Gr lambda^2)
set opt(Efriss_amp)   [expr [expr 1.1 * $opt(RXThresh) * 16 * $PI * $PI] / \
                            [expr $opt(bw) * $opt(Gt) * $opt(Gr) * $l * $l]]
# Etwo_ray_amp = RXThresh / (Rb Gt Gr ht^2 hr^2)
set opt(Etwo_ray_amp) [expr 1.1 * $opt(RXThresh) / \
                      [expr $opt(bw) * $opt(Gt) * $opt(Gr) * \
                            $opt(ht) * $opt(ht) * $opt(ht) * $opt(ht)]]
set opt(EXcvr)         50e-9              ;# Energy for radio circuitry
set opt(e_bf)          5e-9               ;# Beamforming energy (J/bit)
set opt(Esense)        0                  ;# Sensing energy (J/bit)
set opt(thresh_energy) 0.00               ;# Threshold for power adaptation
set opt(Pidle)         0                  ;# Idle power (W)
set opt(Psleep)        0                  ;# Sleep power (W)


# ===== Get rid of the warnings in bind ================================
Resource/Energy set energyLevel_   $opt(init_energy)
Resource/Energy set alarmLevel_    $opt(thresh_energy)
Resource/Energy set expended_      0

Agent/RCAgent set sport_           0
Agent/RCAgent set dport_           0
Agent/RCAgent set packetMsg_       0
Agent/RCAgent set distEst_         0
Agent/RCAgent set packetSize_      0
Agent/BSAgent set packetMsg_       0
Agent/BSAgent set packetSize_      0
Agent/BSAgent set recv_code_       0

RCALinkLayer set delay_            25us
RCALinkLayer set bandwidth_        0     
RCALinkLayer set off_prune_        0    
RCALinkLayer set off_CtrMcast_     0   
RCALinkLayer set macDA_            0  
RCALinkLayer set debug_            0  
RCALinkLayer set avoidReordering_  0  

Phy/WirelessPhy set bandwidth_     $opt(bw)
Phy/WirelessPhy set CSThresh_      $opt(CSThresh)
Phy/WirelessPhy set RXThresh_      $opt(RXThresh)
Phy/WirelessPhy set Efriss_amp_    $opt(Efriss_amp)
Phy/WirelessPhy set Etwo_ray_amp_  $opt(Etwo_ray_amp)
Phy/WirelessPhy set EXcvr_         $opt(EXcvr)
Phy/WirelessPhy set freq_          $opt(freq)
Phy/WirelessPhy set L_             $opt(L)
Phy/WirelessPhy set sleep_         0
Phy/WirelessPhy set alive_         1
Phy/WirelessPhy set ss_            $opt(spreading)
Phy/WirelessPhy set dist_          0

Antenna/OmniAntenna set Gt_        $opt(Gt)
Antenna/OmniAntenna set Gr_        $opt(Gr)
Antenna/OmniAntenna set Z_         $opt(ht)

set MacTrace                       OFF
Mac set bandwidth_                 $opt(bw)
Mac/Sensor set code_               0
Mac/Sensor set node_num_           0
Mac/Sensor set ss_                 $opt(spreading) 
Mac/Sensor set CHheard_            0
Mac/Sensor set myADVnum_           0

set bs [list $opt(bs_x) $opt(bs_y)]
set BS_NODE 1

set outf [open "$opt(dirname)/conditions.txt" a]
puts $outf "Simulation will stop after $opt(stop) seconds."
puts $outf "Base station at ($opt(bs_x), $opt(bs_y))"
if {$opt(eq_energy) == 1} {
  puts $outf "Each node starting with $opt(init_energy) Joules of energy.\n"
}
puts $outf "Energy Model:"
puts $outf "\t\tRXThresh = $opt(RXThresh)"
puts $outf "\t\tCSThresh = $opt(CSThresh)"
puts $outf "\t\tRb = $opt(bw)"
puts $outf "\t\tExcvr = $opt(EXcvr)"
puts $outf "\t\tEfriss_amp = $opt(Efriss_amp)"
puts $outf "\t\tEtwo_ray_amp = $opt(Etwo_ray_amp)"
puts $outf "\t\tEbf = $opt(e_bf)"
puts $outf "\t\tPidle = $opt(Pidle)"
puts $outf "\t\tPsleep = $opt(Psleep)\n"
close $outf

set initialized 0
set rng_ [new RNG]

proc leach-create-mobile-node { id } {
    global ns_ chan prop topo tracefd opt node_ 
    global initialized BS_NODE rng_

    if {$initialized == 0} {
      sens_init
      set initialized 1
    }

    # Create nodes.
    if {$id != $opt(nn_)} {
      puts -nonewline "$id "
      set node_($id) [new MobileNode/ResourceAwareNode]
    } else {
      puts "($opt(nn_) == BS)"
      set node_($id) [new MobileNode/ResourceAwareNode $BS_NODE]
    }

    set node $node_($id)
    if {$id != $opt(nn_)} {
      # Set initial node energy.
      if {$opt(eq_energy) == 1} {
        $node set-energy $opt(init_energy) $opt(thresh_energy)
      } else {
        #set E [$rng_ uniform $opt(lower_e) $opt(upper_e)]
        #set rn [$rng_ uniform 0 1]
        #if {$rn < 0.1} {
        #  set E 200
        #} else {
        #  set E 2
        #}
        set high_e_nodes [list 97 19 12 87 8 22 83 55 34 72]
        if {[lsearch $high_e_nodes $id] == -1} {
          set E 2
        } else {
          set E 200
        }
        $node set-energy $E $opt(thresh_energy)
        set initf [open "$opt(dirname)/init.energy" a]
        puts $initf "$id\t$E"
        close $initf
      }
    } else {
      # Base station has an infinite amount of energy.
      $node set-energy 50000 $opt(thresh_energy)
    }

    # Disable random motion.
    $node random-motion 0       
    $node topography $topo

    if ![info exist inerrProc_] {
        set inerrProc_ ""
    }
    if ![info exist outerrProc_] {
        set outerrProc_ ""
    }
    if ![info exist FECProc_] {
        set FECProc_ ""
    }

    # Connect the node to the channel.
    $node add-interface $chan $prop $opt(ll) $opt(mac)  \
      $opt(ifq) $opt(ifqlen) $opt(netif) $opt(ant) \
      $topo $inerrProc_ $outerrProc_ $FECProc_

    # Set up the trace target.
    set T [new Trace/Generic]
    $T target [$ns_ set nullAgent_]
    $T attach $tracefd
    $T set src_ $id
    $node log-target $T

    $ns_ at 0.0 "$node_($id) start-app"
}

proc sens_init {} {

    global ns_ opt ns

    # The timer code has hard-coded the global variable ns to
    # be the simulator.
    set ns $ns_

    # Remove old trace files.
    catch "eval exec rm [glob -nocomplain $opt(dirname)/TDMAschedule.*.txt]"
    catch "exec rm $opt(dirname)/$opt(filename).energy"
    catch "exec rm $opt(dirname)/$opt(filename).data"
    catch "exec rm $opt(dirname)/$opt(filename).alive"
    catch "exec rm $opt(dirname)/startup.energy"
    catch "exec rm $opt(dirname)/init.energy"

    puts "Creating sensor nodes..."
  
    sens_init_stats "$opt(dirname)/$opt(filename)"

    $ns_ at $opt(stop) "sens_finish"
    # Start logging simulation statistics.
    $ns_ at $opt(check_energy) "sens_gather_stats"
}

