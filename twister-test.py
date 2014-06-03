#!/usr/bin/python

import os,sys,time

ext_ip  = os.environ['EXTIP']
twister = "./twisterd"

cmd = sys.argv[1]
n   = int(sys.argv[2])

dport=36000
drpcport=46000
datadir = "/Users/gurghet/Documents/Tesi/inst-t/acc-0%d" % n
pidf = "/Users/gurghet/Documents/Tesi/inst-t/0%d.pid" % n
port = "%d" % (dport+n)
port1 = "%d" % (dport+1)
rpcport = "%d" % (drpcport+n)
rpcport1 = "%d" % (drpcport+1)
rpcline = " -genproclimit=1 -rpcuser=user -rpcpassword=pwd -rpcallowip=127.0.0.1 -rpcport="
rpccfg = rpcline + rpcport
rpccfg1 = rpcline + rpcport1


if cmd == "start":
    try:
        os.mkdir(datadir)
    except:
        pass
    os.system( twister + " -pid=" + pidf + " -datadir=" + datadir +
               " -port=" + port + " -daemon" +
               rpccfg )
    os.system( "echo " + twister + " -pid=" + pidf + " -datadir=" + datadir +
               " -port=" + port + " -daemon" +
               rpccfg )
    if( n != 1):
        time.sleep(2)
        os.system( twister + rpccfg1 + " addnode " + ext_ip + ":" + port + " onetry" )
        os.system( twister + rpccfg + " addnode " + ext_ip + ":" + port1 + " onetry" )
        os.system( "echo " + twister + rpccfg1 + " addnode " + ext_ip + ":" + port + " onetry" )
        os.system( "echo " + twister + rpccfg + " addnode " + ext_ip + ":" + port1 + " onetry" )

if cmd == "cmd":
    if( len(sys.argv) < 4 ):
        print "missing command (try help)"
        sys.exit(-1)
    parms = ""
    for i in xrange(3,len(sys.argv)):
        parms += " '" + sys.argv[i] + "'"
    os.system( "echo " + twister + rpccfg + parms )
    os.system( twister + rpccfg + parms )

