#!/bin/bash
cd build
unamestr=`uname`
if [ "$unamestr" == 'Linux' ]; then
	sleep 1 && /usr/bin/firefox http://localhost:8000 & 
elif [ "$unamestr" == 'FreeBSD' ]; then
   sleep 1 && /usr/bin/firefox http://localhost:8000 & 
elif [ "$unamestr" == 'Darwin' ]; then
	sleep 1 && open -a Firefox http://localhost:8000 & 
fi 
./server.coffee
