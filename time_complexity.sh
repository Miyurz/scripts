#!/bin/bash

i=$1

if [ `expr ${i} % 2`  != "0" ];
then
  i=$(expr $i + 1);
fi

k=$i

echo "while loop"
time while [ $i -lt 10000 ]
do
  i=$((i + 2))
  #echo $i;
done

echo "last value is $i"

echo "for loop"
echo "k is $k"
time for (( ;k<10000; k=k+2))
do
   continue;
   #echo $k
done

echo "last value is $k"
