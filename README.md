# New project!

The goal is to construct a collection of useful or educational
scripts for use with Slurm that can be accessed via the "s"
command or shortcuts. So place the scripts and scripts/aliases
directories in your path and enter:

    s  # get a menu of available commands

### try some of the shortcuts
    queues   # open and close queues/partitions
    pending  # show expanded list of pending jobs
    running  # show expanded list of running jobs
    lsload   # list node loads


## Slurm jobs must be ASCII

    # determine if file is not ASCII
    file my_script
    #
    # if UTF8 use
    conv -c -f UTF-8 -t ASCII my_script > fixed_script
    # or
    dos2unix -7 <my_script > fixed_script
    # or
    recode --list
    recode ibmpc..lat1 my_script

## Slurm output directory must be writable or output vanishes

## example job
```bash
#!/bin/bash
#
# be careful of resource limits inherited from environment submitted in
# ulimit -a
cat /proc/self/limits
#
scontrol show jobid=$SLURM_JOB_ID
# Write the batch script for a given job_id to stdout
scontrol write batch_script jobid=$SLURM_JOB_ID -
#
# be careful of values inherited from environment submitted in
env
module list
# some statistics
cat /proc/self/status
sleep 120
```
