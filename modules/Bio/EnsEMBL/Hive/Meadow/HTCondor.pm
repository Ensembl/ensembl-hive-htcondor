=pod

=head1 NAME

    Bio::EnsEMBL::Hive::Meadow::HTCondor

=head1 DESCRIPTION

    This is the 'HTCondor' implementation of Meadow

=head1 LICENSE

    Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

    Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

         http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software distributed under the License
    is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and limitations under the License.

=head1 EXTERNAL CONTRIBUTION

This module has been written in collaboration between Lel Eory (University of Edinburgh) and Javier Herrero (University College London) based on the LSF.pm module. Hence keeping the same LICENSE note.

=head1 CONTACT

    Please subscribe to the Hive mailing list:  http://listserver.ebi.ac.uk/mailman/listinfo/ehive-users  to discuss Hive-related questions or to be notified of our updates

=cut


package Bio::EnsEMBL::Hive::Meadow::HTCondor;

use strict;

use base ('Bio::EnsEMBL::Hive::Meadow');


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

    if (-e $job_description) {
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
    #warn "PREFIX: $job_name_prefix\n";
    my @jobs;
    open(my $fh, '-|', @cmd);
    while (<$fh>) {
        #warn "JOB: $_\n";
        my ($cluster_id, $proc_id, $owner, $job_status, $env) = split /\t/;

        my $rc_name = '__unknown_rc_name__';

        if ($env =~ /EHIVE_SUBMISSION_NAME=([^;]+)/) {
            # skip the hive jobs that belong to another pipeline
            my $job_name = $1;
            #warn "with job name $job_name\n";
            next if (($job_name =~ /Hive-/) and (index($job_name, $job_name_prefix) != 0));

            if ($job_name =~ /^\Q${job_name_prefix}\E(\S+)\-\d+(\[\d+\])?$/) {
                $rc_name = $1;
            }
        }

        #warn "RC $rc_name\n";
        push @jobs, ["${cluster_id}\[${proc_id}\]", $owner, $condor_job_status_index_2_hive_job_status{$job_status}, $rc_name];
    }
    close($fh);
    #use Data::Dumper;
    #warn Dumper(\@jobs);
    return \@jobs;
}


sub check_worker_is_alive_and_mine {
    my ($self, $worker) = @_;

    my $process_id = $worker->process_id();
    my $condor_id  = $self->_hive_process_id_2_condor_id($process_id);

    my $matches = $self->_query_active_jobs(undef, $condor_id);
    return scalar(@$matches);
}


sub kill_worker {
    my ($self, $worker, $fast) = @_;

    my $process_id = $worker->process_id();
    my $condor_id  = $self->_hive_process_id_2_condor_id($process_id);

    system('condor_rm', $condor_id);
}




sub submit_workers {
    my ($self, $worker_cmd, $required_worker_count, $iteration, $rc_name, $rc_specific_submission_cmd_args, $submit_log_subdir) = @_;

    my $job_name                            = $self->job_array_common_name($rc_name, $iteration);
    my $meadow_specific_submission_cmd_args = $self->config_get('SubmissionOptions');

    #$submit_log_subdir = 'TEST';

    $worker_cmd =~ /^(\S+)\s+(.*)/;
    my $executable = $1;
    my $parameters = $2;
    #warn "****'$worker_cmd'\n";

    # TODO: add $rc_specific_submission_cmd_args

    open(my $fh, '|-', "condor_submit ${meadow_specific_submission_cmd_args}");
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
    print $fh "Queue $required_worker_count\n";
    close($fh);
    $? && die "Could not submit job(s): $!, $?";  # let's abort the beekeeper and let the user check the syntax
}

1;