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
# a variety of  commands useful for debugging, creating job pedigrees
# and common tasks
#
#------------------------------
# be careful of resource limits inherited from environment submitted from
cat /proc/self/limits
#------------------------------
# show job parameters
scontrol show jobid=$SLURM_JOB_ID
# Write the batch script for a given job_id to stdout
scontrol write batch_script jobid=$SLURM_JOB_ID -
#------------------------------
: file permission mask
umask
umask 077
#------------------------------
# ensure any srun(1) command does not have exporting off
# in case this job requested exporting be off
export SRUN_EXPORT_ENV=ALL
#------------------------------
# combine stderr with stdout
exec 2>&1
# turn command echo on
set -v -x
#------------------------------
cat <<\EOF
===============================================================================
hostname  $(hostname)
pwd       $(pwd)
jobid     $SLURM_JOB_ID
umask     $(umask)
TMPDIR    $TMPDIR
TMP       $TMP
===============================================================================
EOF
# be careful of values inherited from environment submitted from
env
which module && module list
#------------------------------
# link to stdout of job
export SLURM_OUTPUT=/proc/self/fd/1
ln -s $SLURM_OUTPUT OUTPUT
# mail stdout of job
mail -s "job: $SLURM_JOB_ID hostname:$(hostname) date:$(date)" < OUTPUT
#------------------------------
# some statistics from Linux
cat /proc/self/status
#------------------------------
sleep 120
```
