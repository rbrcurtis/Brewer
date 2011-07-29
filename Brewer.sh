#!/bin/bash
unamestr=`uname`
if [ "$unamestr" == 'Linux' ]; then
	sleep 1 && /usr/bin/firefox http://localhost:8000 & 
elif [ "$unamestr" == 'FreeBSD' ]; then
   sleep 1 && /usr/bin/firefox http://localhost:8000 & 
elif [ "$unamestr" == 'Darwin' ]; then
	sleep 1 && open -a Brewer &
fi 
./server.coffee
