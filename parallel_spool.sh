#!/bin/bash

# EXAMPLE ./parallel_spool.sh -oQCRM -nCCHQA -mName -tuser -w "where name like '%Anna%' limit 10"

# Extract the arguments

while getopts o:n:t:w:m: option
do
  case "${option}"
  in
    o) OLD_ORG=${OPTARG};;
    n) NEW_ORG=${OPTARG};;
    t) TABLE=${OPTARG};;
    w) WHERE=$OPTARG;;
    m) MATCH=$OPTARG;;
    \?) echo " -o OLD_ORG -n NEW_ORG -m FIELD TO MATCH -t TABLE -w WHERE CLAUSE"; exit;
  esac
done

#Launches two extractions in parallel to save time and creates a list of PIDS

sfdx force:data:soql:query -q "select $MATCH, Id from $TABLE $WHERE" -u $NEW_ORG -r csv > spool_NEWORG &
echo $!>> pidfile
sfdx force:data:soql:query -q "select $MATCH, Id from $TABLE $WHERE" -u $OLD_ORG -r csv > spool_OLDORG &
echo $!>> pidfile

#Wait for the two parallel process to exit by looping on the PID file

while read pid
do
  # echo $pid
  wait $pid
done < pidfile
rm pidfile

#Remove the header and sort the file otherwise the join won't work properly

#New comment to test GIT

cat spool_NEWORG | grep -i -v $MATCH| sort > spool_NEWORG_s
cat spool_OLDORG | grep -i -v $MATCH| sort > spool_OLDORG_s
join -1 1 -2 1 -t , spool_OLDORG_s spool_NEWORG_s > joinfile

#Join the two files over column 1 assuming the field separator is a comma

echo 'name,oldID,newID' > results.csv
cat joinfile >> results.csv

#Clean up the mess

#rm joinfile
#rm spool*
