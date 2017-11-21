=pod

=head1 NAME

Bio::EnsEMBL::Hive::Meadow::HTCondor

=head1 DESCRIPTION

    This is the 'HTCondor' implementation of Meadow

=head1 LICENSE

    Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
    Copyright [2016-2017] EMBL-European Bioinformatics Institute

    Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

         http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software distributed under the License
    is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and limitations under the License.

=head1 CONTACT

    Please subscribe to the Hive mailing list:  http://listserver.ebi.ac.uk/mailman/listinfo/ehive-users  to discuss Hive-related questions or to be notified of our updates

=cut


package Bio::EnsEMBL::Hive::Meadow::HTCondor;

use strict;
use warnings;

use Capture::Tiny 'tee_stdout';
use File::Temp qw/tempfile/;

use Bio::EnsEMBL::Hive::Utils ('whoami');

use base ('Bio::EnsEMBL::Hive::Meadow');


our $VERSION = '5.0';       # Semantic version of the Meadow interface:
                            #   change the Major version whenever an incompatible change is introduced,
                            #   change the Minor version whenever the interface is extended, but compatibility is retained.



sub name {  # also called to check for availability;

    # Query the name of the HTCondor master
    my $cmd = 'condor_status -master 2> /dev/null | tail -n 1';

    if(my $name = `$cmd`) {
        chomp($name);
        return $name;
    }
}


sub get_current_worker_process_id {
    my ($self) = @_;

    my $job_description = $ENV{'_CONDOR_JOB_AD'};

    if ($job_description && -e $job_description) {
        my $cluster_id;     # Main job index
        my $proc_id;        # Sub-index for job arrays
        open(my $fh, '<', $job_description);
        while (<$fh>) {
            if (/^ClusterId\s+=\s+(.*)$/) {
                $cluster_id = $1;
            } elsif (/^ProcId\s+=\s+(.*)$/) {
                $proc_id = $1;
            }
        }
        close($fh);
        # ProcId is always defined, even for single jobs.
        # I couldn't find a way of distinguishing them from job-arrays
        # consisting of 1 job only.
        return "${cluster_id}\[${proc_id}\]";
    } else {
        die 'Could not find the job description on $_CONDOR_JOB_AD';
    }
}


sub deregister_local_process {
    my ($self) = @_;

    delete $ENV{'_CONDOR_JOB_AD'};
}


sub status_of_all_our_workers { # returns an arrayref
    my $self                        = shift @_;
    my $meadow_users_of_interest    = shift @_;

    $meadow_users_of_interest = [ undef ] unless ($meadow_users_of_interest && scalar(@$meadow_users_of_interest));

    my $job_name_prefix = $self->job_name_prefix();

    my @all_workers;
    foreach my $meadow_user (@$meadow_users_of_interest) {
        my $some_jobs = $self->_query_active_jobs($meadow_user, undef, $job_name_prefix);
        push @all_workers, @$some_jobs;
    }

    return \@all_workers;
}

sub _hive_process_id_2_condor_id {
    my ($self, $process_id) = @_;
    $process_id =~ s/\[/\./;
    $process_id =~ s/\]//;
    return $process_id;
}

my %condor_job_status_index_2_hive_job_status = (
    # From http://research.cs.wisc.edu/htcondor/manual/v7.7/11_Appendix_A.html
    1 => 'PEND',    # Idle
    2 => 'RUN',     # Running
    3 => 'DEL',     # Removed
    4 => 'EXIT',    # Completed
    5 => 'SUSP',    # Held
    6 => 'RUN',     # Transferring Output
    7 => 'SUSP',    ## This one is actually not documented
);

sub _query_active_jobs {
    my ($self, $user, $worker_id, $job_name_prefix) = @_;

    my @cmd = qw(condor_q -format %d\t ClusterId -format %d\t ProcId -format %s\t Owner -format %s\t JobStatus -format %s\n Env);

    if ($user) {
        push @cmd, $user;

    } elsif ($worker_id) {
        push @cmd, $worker_id;

    }

    #warn "CMD: ", join(' ', @cmd), "\n";
    #warn "PREFIX: ", $job_name_prefix||"<NA>", "\n";
    my @jobs;
    open(my $fh, '-|', @cmd);
    while (<$fh>) {
        #warn "JOB: $_";
        my ($cluster_id, $proc_id, $owner, $job_status, $env) = split /\t/;

        unless (defined $env) {
            warn "Cannot parse this line: $_";
            next;
        }

        if (($env =~ /EHIVE_SUBMISSION_NAME=([^;]+)/) && $job_name_prefix) {
            # skip the hive jobs that belong to another pipeline
            my $job_name = $1;
            #warn "with job name $job_name\n";
            next if (($job_name =~ /Hive-/) and (index($job_name, $job_name_prefix) != 0));
        }

        push @jobs, ["${cluster_id}\[${proc_id}\]", $owner, $condor_job_status_index_2_hive_job_status{$job_status}];
    }
    close($fh);
    #use Data::Dumper;
    #warn Dumper(\@jobs);
    return \@jobs;
}


sub check_worker_is_alive_and_mine {
    my ($self, $worker) = @_;

    my $process_id = $worker->process_id();
    my $this_user  = whoami();
    my $condor_id  = $self->_hive_process_id_2_condor_id($process_id);

    my $matches = $self->_query_active_jobs(undef, $condor_id);
    return scalar(grep {$_->[1] eq $this_user} @$matches);
}


sub kill_worker {
    my ($self, $worker, $fast) = @_;

    my $process_id = $worker->process_id();
    my $condor_id  = $self->_hive_process_id_2_condor_id($process_id);

    system('condor_rm', $condor_id);
}




sub submit_workers_return_meadow_pids {
    my ($self, $worker_cmd, $required_worker_count, $iteration, $rc_name, $rc_specific_submission_cmd_args, $submit_log_subdir) = @_;

    my $job_name                            = $self->job_array_common_name($rc_name, $iteration);
    my $meadow_specific_submission_cmd_args = $self->config_get('SubmissionOptions') || '';

    #$submit_log_subdir = 'TEST';

    my ($executable, $parameters);
    # Assuming the executable has no space in it
    if ($worker_cmd =~ /^(\S+)\s+(.*)/) {
        $executable = $1;
        $parameters = $2;
    } else {
        $executable = $worker_cmd;
        $parameters = '';
    }
    #warn "****'$worker_cmd'\n";

    # The submission file
    my ($fh, $filename) = tempfile(UNLINK => 1);
    print $fh "Universe = vanilla\n";
    print $fh "Executable = $executable\n";
    print $fh "Arguments = $parameters\n";
    print $fh "Environment = EHIVE_SUBMISSION_NAME=$job_name\n";
    print $fh "GetEnv = True\n";
    if ($submit_log_subdir) {
        print $fh "Output = ${submit_log_subdir}/log_${rc_name}_\$(Cluster)_\$(Process).out\n";
        print $fh "Error  = ${submit_log_subdir}/log_${rc_name}_\$(Cluster)_\$(Process).err\n";
        print $fh "Log    = ${submit_log_subdir}/log_${rc_name}_\$(Cluster)_\$(Process).log\n";
    }
    print $fh $rc_specific_submission_cmd_args, "\n";
    print $fh "Queue $required_worker_count\n";
    close($fh);

    # Submit the workers and get their pids
    # FIXME: Should $meadow_specific_submission_cmd_args rather be used in the job file like $rc_specific_submission_cmd_args ?
    my $condor_submit_output = tee_stdout {
        system("condor_submit ${meadow_specific_submission_cmd_args} $filename");
        $? && die "Could not submit job(s): $!, $?";  # let's abort the beekeeper and let the user check the syntax
    };

    # Expecting something like:
    #> Submitting job(s).
    #> 1 job(s) submitted to cluster 6.
    my $condor_jobid;
    if($condor_submit_output=~/^\d+ job\(s\) submitted to cluster (\d+)\./m) {
        $condor_jobid = $1;
    }

    if($condor_jobid) {
        return [ map { $condor_jobid.'['.$_.']' } (0..($required_worker_count-1)) ];
    } else {
        die "Submission unsuccessful\n";
    }
}

1;
