#!/bin/bash
#SBATCH --job-name=jobs_in_job  --export=NONE --propagate=NONE
#SBATCH --nodes 3 --ntasks=1 --time 0-0:0:10 --mem-per-cpu=1mb
#SBATCH --output=/tmp/job_in_job.out.%J
#SBATCH
#
# This  example shows a script in which Slurm is used to provide resource
# management for a job by executing the various job steps  as  processors
# become available for their dedicated use.
#
# jobs_in_job.bash
# Submit as follows:
# sbatch -n3 -N1-1 jobs_in_job.bash
# tail -f /tmp/job_in_job.out.*
#
################################################################################
cat >job.sh <<\MAKEFILE
#!/bin/bash
#SBATCH --job-name=job_in_job  --export=NONE --propagate=NONE
#SBATCH --nodes 1-1 --ntasks=1 --time 0-0:0:10 --mem-per-cpu=1mb
#SBATCH --output=/tmp/job_in_job.out.%J
for (( i=0 ; i<=100 ; i=i+1 ))
do
   echo "job_in_job $SLURM_ID $i";sleep 1
done
MAKEFILE
################################################################################
#
srun -n2 --exclusive job.sh &
srun -n1 --exclusive job.sh &
srun -n1 --exclusive job.sh &
srun -n1 --exclusive job.sh &
srun -n1 --exclusive job.sh &
wait
