#!/usr/bin/env perl
# Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
# Copyright [2016-2017] EMBL-European Bioinformatics Institute
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


use strict;
use warnings;

use Cwd;
use File::Basename;
use File::Temp qw{tempfile};

use Test::More tests => 20;
use Test::Exception;

use Bio::EnsEMBL::Hive::Utils::Config;

BEGIN {
    use_ok( 'Bio::EnsEMBL::Hive::Valley' );
    use_ok( 'Bio::EnsEMBL::Hive::Meadow::HTCondor' );
}

my $htcondor_meadow_path = File::Basename::dirname( File::Basename::dirname( Cwd::realpath($0) ) );

my @config_files = Bio::EnsEMBL::Hive::Utils::Config->default_config_files();
my $config = Bio::EnsEMBL::Hive::Utils::Config->new(@config_files);

throws_ok {
    local $ENV{'PATH'} = $htcondor_meadow_path.'/t/deceptive_bin:'.$ENV{'PATH'};
    my $valley = Bio::EnsEMBL::Hive::Valley->new($config, 'HTCondor');
} qr/Meadow 'HTCondor' does not seem to be available on this machine, please investigate at/, 'No HTCondor meadow if "condor_status" is not present (or does not behave well)';

# WARNING: the data in this script must be in sync with what the fake
# binaries output
local $ENV{'PATH'} = $htcondor_meadow_path.'/t/fake_bin:'.$ENV{'PATH'};

my $test_pipeline_name = 'long_mult';
my $test_meadow_name = 'test_clUster';

my $valley = Bio::EnsEMBL::Hive::Valley->new($config, 'HTCondor', $test_pipeline_name);

my $htcondor_meadow = $valley->available_meadow_hash->{'HTCondor'};
ok($htcondor_meadow, 'Can build the meadow');

# Check that the meadow has been initialised correctly
is($htcondor_meadow->name, $test_meadow_name, 'Found the HTCondor farm name');
is($htcondor_meadow->pipeline_name, $test_pipeline_name, 'Getter/setter pipeline_name() works');

subtest 'get_current_worker_process_id()' => sub
{
    delete $ENV{'_CONDOR_JOB_AD'};
    throws_ok {$htcondor_meadow->get_current_worker_process_id()} qr/Could not find the job description on \$_CONDOR_JOB_AD/, 'Not a HTCondor job';
    local $ENV{'_CONDOR_JOB_AD'} = undef;
    throws_ok {$htcondor_meadow->get_current_worker_process_id()} qr/Could not find the job description on \$_CONDOR_JOB_AD/, 'Not a HTCondor job';
    local $ENV{'_CONDOR_JOB_AD'} = '/non_existent';
    throws_ok {$htcondor_meadow->get_current_worker_process_id()} qr/Could not find the job description on \$_CONDOR_JOB_AD/, 'Not a HTCondor job';

    my ($fh, $tmp_filename) = tempfile(UNLINK => 1);
    close($fh);
    local $ENV{'_CONDOR_JOB_AD'} = $tmp_filename;

    open($fh, '>', $tmp_filename); print $fh "ClusterId = 34\nProcId = 56\n"; close($fh);
    is($htcondor_meadow->get_current_worker_process_id(), '34[56]', 'Job array with index');
    open($fh, '>', $tmp_filename); print $fh "ClusterId = 34\nProcId = 0\n"; close($fh);
    is($htcondor_meadow->get_current_worker_process_id(), '34[0]', 'Even singleton jobs are considered arrays');

    unlink $tmp_filename;
};

is_deeply(
    $htcondor_meadow->status_of_all_our_workers,
    [
        [ '1[0]', 'condoradmin', 'PEND' ],
        [ '2[0]', 'condoradmin', 'RUN' ],
        [ '3[0]', 'condoradmin', 'EXIT' ],
        [ '3[1]', 'condoradmin', 'PEND' ],
        [ '4[1]', 'condoradmin', 'RUN' ],
        [ '5[1]', 'condoradmin', 'DEL' ],
        [ '6[1]', 'otheruser', 'RUN' ],
        [ '6[0]', 'otheruser', 'PEND' ],
        [ '7[0]', 'otheruser', 'RUN' ],
        [ '8[0]', 'condoradmin', 'RUN' ],
        [ '9[0]', 'condoradmin', 'SUSP' ],
        [ '10[0]', 'condoradmin', 'RUN' ],
        [ '11[0]', 'condoradmin', 'RUN' ],
        [ '11[1]', 'condoradmin', 'PEND' ],
        [ '11[2]', 'condoradmin', 'PEND' ],
        [ '11[3]', 'condoradmin', 'RUN' ],
        [ '11[4]', 'condoradmin', 'RUN' ],
        [ '11[5]', 'condoradmin', 'RUN' ],
        [ '11[6]', 'condoradmin', 'RUN' ],
        [ '11[7]', 'condoradmin', 'RUN' ]
    ],
    'status_of_all_our_workers()',
);

is_deeply(
    $htcondor_meadow->status_of_all_our_workers(["otheruser"]),
    [
        [ '6[1]', 'otheruser', 'RUN' ],
        [ '6[0]', 'otheruser', 'PEND' ],
        [ '7[0]', 'otheruser', 'RUN' ],
    ],
    'status_of_all_our_workers(["otheruser"])',
);

use Bio::EnsEMBL::Hive::Worker;
my $worker = Bio::EnsEMBL::Hive::Worker->new();

{
    $worker->meadow_type('HTCondor');
    $worker->meadow_name('imaginary_meadow');
    is($valley->find_available_meadow_responsible_for_worker($worker), undef, 'find_available_meadow_responsible_for_worker() with a worker from another meadow');
    $worker->meadow_name($test_meadow_name);
    is($valley->find_available_meadow_responsible_for_worker($worker), $htcondor_meadow, 'find_available_meadow_responsible_for_worker() with a worker from that meadow');
}

{
    local $ENV{USER} = 'otheruser';
    $worker->process_id('7[0]');
    ok($htcondor_meadow->check_worker_is_alive_and_mine($worker), 'An existing process that belongs to me');
    $worker->process_id('11[1]');
    ok(!$htcondor_meadow->check_worker_is_alive_and_mine($worker), 'An existing process that belongs to condoradmin');
    $worker->process_id('123456789');
    ok(!$htcondor_meadow->check_worker_is_alive_and_mine($worker), 'A missing process');
}

my $submitted_pids;
lives_ok( sub {
    local $ENV{EHIVE_EXPECTED_JOB_AD} = $htcondor_meadow_path.'/t/fake_bin/job_ad.1.txt';
    $submitted_pids = $htcondor_meadow->submit_workers_return_meadow_pids('/worker_cmd/ params', 1, 56, '/resource_class/', '/rc_args/');
}, 'Can submit something');
is_deeply($submitted_pids, ['12345[0]'], 'Returned the correct pid');

lives_ok( sub {
    local $ENV{EHIVE_EXPECTED_JOB_AD} = $htcondor_meadow_path.'/t/fake_bin/job_ad.2.txt';
    $submitted_pids = $htcondor_meadow->submit_workers_return_meadow_pids('/worker_cmd/ params', 4, 56, '/resource_class/', '/rc_args/');
}, 'Can submit something');
is_deeply($submitted_pids, ['12345[0]', '12345[1]', '12345[2]', '12345[3]'], 'Returned the correct pids');

lives_ok( sub {
    local $ENV{EHIVE_EXPECTED_JOB_AD} = $htcondor_meadow_path.'/t/fake_bin/job_ad.3.txt';
    $submitted_pids = $htcondor_meadow->submit_workers_return_meadow_pids('/worker_cmd/ params', 1, 56, '/resource_class/', '/rc_args/', '/submit_log_dir/');
}, 'Can submit something with a submit_log_dir');
is_deeply($submitted_pids, ['12345[0]'], 'Returned the correct pid');

done_testing();

