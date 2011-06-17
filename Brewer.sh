#!/bin/bash
cd build
sleep 1 && open -a Firefox http://localhost:8000 & 
echo "go";./server.coffee
