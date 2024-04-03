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

This example jobs shows
a variety of  commands useful for debugging, creating job pedigrees,
and common tasks

```bash
#!/bin/bash -l
# specify shell to use on first line
# add -l to get login setup and execution of user prologue files
#
# be careful of resource limits inherited from environment where 
# job was submitted from. This turns off inheriting the environment
#SBATCH --export=NONE --propagate=NONE --get-user-env=300L
#
# there are macros to help create unique output filenames, like %J
#SBATCH --output=hostname.out.%J  ### --error=hostname.err.%J    # optionally create job stderr file
#
# if memory is not defined the default will be all the node on
# the memory if the adminstrator has not changed it, meaning
# even a job asking for one core will exclusively get the entire
# node
#SBATCH --mem-per-cpu=100mb # Also see --memory .
#
# run a single task, using a single CPU core on a single node
#SBATCH --nodes 1-1 --ntasks=1
#
# the job will backfill more efficiently the closer the job timelimit
# is to the time required; but note default behavior is to kill the
# job if it hits the limit. The administrator can customize the 
# behavior when a job hits the limit, however.
#
#SBATCH --time 0-0:0:10 # maximum job time in D-HH:MM
#
## #SBATCH --job-name=hostname # job name (avoid non-alphanumeric characters)
## #SBATCH --partition debug
## #SBATCH --reservation=MY_RESERVATION
## #SBATCH --mail-type=END,FAIL          # Mail events (NONE, BEGIN, END, FAIL, ALL)
## #SBATCH --mail-user=someone@comcast.net     # Where to send mail

cat /proc/self/limits             # show resource limits

scontrol show jobid=$SLURM_JOB_ID # show job parameters
# Write the batch script for a given job_id to stdout
scontrol write batch_script jobid=$SLURM_JOB_ID -

: file permission mask
umask
umask 077

# ensure any srun(1) command does not have exporting off
# in case this job requested exporting be off
export SRUN_EXPORT_ENV=ALL

exec 2>&1 # combine stderr with stdout regardless of SBATCH directives
set -v -x # turn command echo on

cat <<\EOF
===============================================================================
hostname  $(hostname)
pwd       $(pwd)
hostname  $(hostname)
jobid     $SLURM_JOB_ID
umask     $(umask)
TMPDIR    $TMPDIR
TMP       $TMP
===============================================================================
EOF
env # dump environment. Take particular note of the SLURM_* variables defined

which module && module list

# link to stdout of job
export SLURM_OUTPUT=/proc/self/fd/1
ln -s $SLURM_OUTPUT OUTPUT
# mail stdout of job as use of the "OUTPUT" file
mail -s "job: $SLURM_JOB_ID hostname:$(hostname) date:$(date)" < OUTPUT

# execute some stuff via srun(1) in background and it will be sub-scheduled
# in the current job allocation by default
for (( i=0 ; i<=100 ; i=i+1 ))
do
   echo $i
   srun sleep 1 &
done
wait

# some statistics from Linux
cat /proc/self/status

sleep 120
```
