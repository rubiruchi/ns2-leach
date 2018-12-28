#!/bin/bash
tar -xvzf ns-234-leach.tar.gz
cd ns-234-leach/
cp -r mit /home/pradeepkumar/ns-allinone-2.35/ns-2.35
cp apps/app.* /home/pradeepkumar/ns-allinone-2.35/ns-2.35/apps
cp mac/channel.cc /home/pradeepkumar/ns-allinone-2.35/ns-2.35/mac
cp mac/ll.h /home/pradeepkumar/ns-allinone-2.35/ns-2.35/mac
cp mac/wireless-phy.* /home/pradeepkumar/ns-allinone-2.35/ns-2.35/mac
cp mac/phy.* /home/pradeepkumar/ns-allinone-2.35/ns-2.35/mac
cp mac/mac.cc /home/pradeepkumar/ns-allinone-2.35/ns-2.35/mac
cp mac/mac-sensor* /home/pradeepkumar/ns-allinone-2.35/ns-2.35/mac
cp trace/cmu-trace.* /home/pradeepkumar/ns-allinone-2.35/ns-2.35/trace
cp common/packet.* /home/pradeepkumar/ns-allinone-2.35/ns-2.35/common
cp common/mobilenode.cc /home/pradeepkumar/ns-allinone-2.35/ns-2.35/common
cp tcl/mobility/leach-c.tcl /home/pradeepkumar/ns-allinone-2.35/ns-2.35/tcl/mobility
cp tcl/mobility/leach.tcl /home/pradeepkumar/ns-allinone-2.35/ns-2.35/tcl/mobility
cp tcl/mobility/mte.tcl /home/pradeepkumar/ns-allinone-2.35/ns-2.35/tcl/mobility
cp tcl/mobility/stat-clus.tcl /home/pradeepkumar/ns-allinone-2.35/ns-2.35/tcl/mobility
cp tcl/ex/wireless.tcl /home/pradeepkumar/ns-allinone-2.35/ns-2.35/tcl/ex
cp test /home/pradeepkumar/ns-allinone-2.35/ns-2.35
cp leach_test /home/pradeepkumar/ns-allinone-2.35/ns-2.35
cp Makefile /home/pradeepkumar/ns-allinone-2.35/ns-2.35
cp Makefile.in /home/pradeepkumar/ns-allinone-2.35/ns-2.35



