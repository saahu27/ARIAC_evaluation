#!/bin/bash

#---------------------------------------------------------
# Example usage:./run_trial.sh nist_competitor trial_name
#---------------------------------------------------------
if [[ ! $1 ]] ; then
    echo "Team configuration argument not passed" 
    exit 1
fi

# Create a folder to copy log files from docker
if [ ! -d /$PWD/logs/$teamName ]; then
  mkdir -p /$PWD/logs/$teamName/;
fi

function run_trial() {
    local teamname="$1"
    local trialname="$2"
    local j=1
    if [ ! -d /$PWD/logs/$teamname/$trialname\_$j ]; then
        mkdir -p /$PWD/logs/$teamname/$trialname\_$j/;
    else
        while [ -d /$PWD/logs/$teamname/$trialname\_$j ]; do
            let j++  
        done
        mkdir -p /$PWD/logs/$teamname/$trialname\_$j/;
    fi
    docker exec -it $teamname bash -c ". /container_scripts/run_trial.sh $teamname $trialname"
    echo "==== Copying logs to"
    
    docker cp $teamname:/tmp/trial_log.txt $PWD/logs/$teamname/$trialname\_$j/trial_log.txt
    docker cp $teamname:/tmp/sensor_cost.txt $PWD/logs/$teamname/$trialname\_$j/sensor_cost.txt
    docker cp $teamname:/tmp/state.log $PWD/logs/$teamname/$trialname\_$j/state.log
    docker cp $teamname:/root/.ros/log/. $PWD/logs/$teamname/$trialname\_$j/ros_log/
}

if [[ "$2" != "run-all" ]] ; then
    if [[ ! $3 ]] ; then
        echo "==== Running trial $2 1 time"
        run_trial $1 $2
    else
        echo "==== Running trial $2 $3 times"
        for ((i=1;i<=$3;i++)); do
            run_trial $1 $2
        done
    fi

else
    if [[ ! $3 ]] ; then
        iterations=1
    else
        iterations=$3
    fi
    
    echo "==== Running all trials from the trials directory"
    # absolute path of the current script
    trials_dir="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )" # https://stackoverflow.com/a/4774063/99379
    # get each file in the trials folder
    for entry in "$trials_dir"/trials/*
    do
        # e.g., kitting.yaml
        trial_file="${entry##*/}"
        # e.g., kitting
        trial_name=${trial_file::-5}

        for ((i=1;i<=iterations;i++)); do
            run_trial $1 $trial_name
        done

    done
fi


