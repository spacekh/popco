#!/bin/sh

numRunsPerParams=2
addlTicks=2000

cd $HOME/popco

###################################
extraPersons=91  # there are 9 propositions in earth-origin, i.e. nine non-naive person
echo
echo running 100-person population with all flipping, including neg flip
echo

numToFlip=100
runNum=1
while [ $runNum -le $numRunsPerParams ]; do
        time sbcl.executable --script sanday/sky-to-earth-add-neg-runs.lisp $extraPersons $addlTicks $numToFlip "s2eAddNeg${extraPersons}extra${addlTicks}addl${numToFlip}flippedRun$runNum"
        runNum=$(($runNum+1))
done
