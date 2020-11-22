!#/bin/bash

COUNTER=33
touch "mivampira_zoomout.raw"
touch "mivampira_zoomout.plt"
for (( c=33; c>=0; c-- ))
do  
   echo "Welcome $c times"
   CMD="ilbm2raw mivampira_zoomout_$c.iff mivampira_zoomout.rawtmp -p mivampira_zoomout.plttmp"
   ilbm2raw mivampira_zoomout_$c.iff mivampira_zoomout.rawtmp -p mivampira_zoomout.plttmp
   cat mivampira_zoomout.rawtmp >> mivampira_zoomout.raw
   cat mivampira_zoomout.plttmp >> mivampira_zoomout.plt
   rm mivampira_zoomout.rawtmp mivampira_zoomout.plttmp
   # echo $CMD
done