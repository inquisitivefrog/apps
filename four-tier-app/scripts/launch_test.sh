#!/bin/bash
#
#set -x
#
export TODAY=`date +"%F-%T"`
export TEST_PLAN=BookOrderAppTestPlan.jmx
export RESULTSDIR=jmeter/results/results_${TODAY}

if [ -d $RESULTSDIR ]; then
    rm -rf $RESULTSDIR
else
    mkdir $RESULTSDIR
fi
jmeter -n -t jmeter/plans/$TEST_PLAN -j jmeter/logs/jmeter_${TODAY}.log -l jmeter/logs/results_${TODAY}.log -e -o $RESULTSDIR
