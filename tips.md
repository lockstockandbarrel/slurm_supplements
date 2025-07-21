# Login scripts for Slurm sites

Login scripts for Slurm clusters are typically shell scripts (often
Bash scripts) that are executed upon a user's successful SSH login to a
cluster's login node. These scripts are designed to set up the user's
environment, display important information, and guide the user on how
to interact with the Slurm scheduling system.

## Key elements of Slurm login scripts

    *Shebang*: The first line of a login script should be a shebang,
    indicating the interpreter to be used (e.g., #!/bin/bash). A useful
    practice is to include the -l flag (e.g., #!/bin/bash -l) to ensure
    that dot files (like .profile, .bashrc) are processed appropriately,
    impacting how environment variables are set.

    *Environment Setup*: Login scripts are the ideal place to load
    modules which provide access to different software versions and
    tools available on the cluster. Modules help manage the software
    environment and avoid conflicts between different software versions
    or applications.

        #!/bin/bash -l
        # Load necessary modules for the user's typical workflow
        module load anaconda3/2024.6
        module load openmpi

* Information Display*: Login scripts can display essential information
like cluster announcements, system status, or personal usage statistics.

*Job Submission Guidance*: A login script can guide the user on how to
submit jobs to the Slurm scheduler, perhaps by providing examples or
pointing to relevant documentation.

*Submitting jobs*: The sbatch command is used to submit a job script
(containing the job's parameters and commands) to the Slurm scheduler. For
example: sbatch job_script.sh.

*Interactive Work Guidance*: For interactive sessions requiring more
resources than the login node provides, a script can instruct the
user on how to utilize the salloc command to obtain an allocation
on a compute node. For example, 

    salloc --nodes=1 --ntasks=1 --mem=4G --time=00:20:00

would request a single CPU core, 4 GB of memory, and 20 minutes of
runtime.

## Environment variables in login scripts

    Login scripts can set and export environment variables that will be
    available to all shells and processes launched by the user during
    that session.

    *SLURM-specific variables*: Slurm itself sets numerous environment
    variables that a login script (or a job script) can utilize, like
    SLURM_JOB_ID (unique ID for a job), SLURM_SUBMIT_DIR (directory
    from which the job was submitted), and others. You can view these
    variables within a job by executing commands like env | grep SLURM.


Best practices

    *Full Paths*: When specifying file paths, it is generally recommended
    to use full paths to avoid ambiguity.

    *Avoid Intensive Work on Login Nodes*: Login nodes are shared
    resources. Performing computationally intensive tasks on them will
    negatively impact other users and may result in the termination of
    the problematic process.

    *Estimate Resource Needs*: Carefully estimate the necessary resources
    (CPUs, memory, time) for jobs to minimize queuing time and avoid
    overspending on core hours.

    *Test Jobs*: Before submitting large, resource-intensive jobs, it
    is advisable to test the code with a smaller dataset or a shorter
    runtime to ensure it works as expected.

    *Combine Small Jobs*: If you have numerous short jobs, consider
    combining them into a single larger job using loops within a
    batch script to reduce the overhead associated with individual
    job submissions.

    *Checkpoints*: If the application supports it, use checkpointing to
    save the job's progress. This allows restarting the job from the
    last saved state in case of unexpected termination, rather than
    restarting from the beginning.


By implementing these practices in login and job scripts, users can
maximize their efficiency on Slurm clusters while respecting shared
resources and collaborating effectively with other users.

## Best practices 

Do NOT run long jobs in the login nodes. Remember that login nodes (cl1,
cl2, cla1) are shared nodes used by all users. Short testing, compilation,
file transfers, ...
