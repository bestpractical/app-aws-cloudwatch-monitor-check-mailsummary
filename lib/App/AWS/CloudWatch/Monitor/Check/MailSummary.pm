# Copyright 2021 Best Practical Solutions, LLC <sales@bestpractical.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

package App::AWS::CloudWatch::Monitor::Check::MailSummary;

use strict;
use warnings;

use parent 'App::AWS::CloudWatch::Monitor::Check';

use Getopt::Long qw(:config pass_through);
use Time::Piece;
use Time::Seconds;

our $VERSION = '0.01';

sub check {
    my $self = shift;
    my $arg  = shift;

    Getopt::Long::GetOptionsFromArray( $arg, \my %opt, 'maillog-path=s', 'maillog-time=s' );

    die "Option: maillog-path is required" unless $opt{'maillog-path'};

    my $t;
    if ( $opt{'maillog-time'} ) {
        die 'Option: maillog-time must be 24hr hour and minute (hh:mm)'
            unless $opt{'maillog-time'} =~ /^(0[0-9]|1[0-9]|2[0-3]):[0-5][0-9]$/;

        $t = Time::Piece->strptime( $opt{'maillog-time'}, '%H:%M' );
    }
    else {
        $t = localtime;
    }

    my $now = $t->hour;
    $now = '0' . $now if $now < 10;
    $now = $now . '00';

    $t -= ONE_HOUR;
    my $start_hour = $t->hour;
    $start_hour = '0' . $start_hour if $start_hour < 10;
    $start_hour = $start_hour . '00';

    my $time_key = $start_hour . '-' . ( $start_hour == 2300 ? 2400 : $now );
    my $scope    = ( $time_key eq '2300-2400' ? 'yesterday' : 'today' );

    # TODO: find pflogsumm bin location
    my @pflogsumm_command = ( qw{ /usr/sbin/pflogsumm -d }, $scope, $opt{'maillog-path'}, qw{ --detail 0 } );
    my ( $exit, $stdout, $stderr ) = $self->run_command( \@pflogsumm_command );

    if ($exit) {
        die "$stderr\n";
    }

    return unless $stdout;

    my $traffic_summary_per_hour = {};
    foreach my $line ( @{$stdout} ) {
        next unless $line =~ /(\d{4}-\d{4})\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/;

        $traffic_summary_per_hour->{$1} = {
            Received  => $2,
            Delivered => $3,
            Deferred  => $4,
            Bounced   => $5,
            Rejected  => $6,
        };
    }

    my $metrics;
    foreach my $key ( sort keys %{ $traffic_summary_per_hour->{$time_key} } ) {
        push @{$metrics},
            {
            MetricName => "mail-$key",
            Unit       => 'Count',
            RawValue   => $traffic_summary_per_hour->{$time_key}{$key},
            },
    }

    return $metrics;
}

1;

__END__

=pod

=head1 NAME

App::AWS::CloudWatch::Monitor::Check::MailSummary - gather mail traffic summary data

=head1 SYNOPSIS

 my $plugin  = App::AWS::CloudWatch::Monitor::Check::MailSummary->new();
 my $metrics = $plugin->check( $args_arrayref );

 aws-cloudwatch-monitor --check MailSummary --maillog-path /var/log/mail.log --maillog-time 23:00

=head1 DESCRIPTION

C<App::AWS::CloudWatch::Monitor::Check::MailSummary> is a L<App::AWS::CloudWatch::Monitor::Check> module which gathers mail traffic summary data for a specified hour.

=head1 METRICS

Data for this check is read from L<pflogsumm(1)>.  The following metrics are returned.

=over

=item mail-Received

=item mail-Delivered

=item mail-Deferred

=item mail-Bounced

=item mail-Rejected

=back

=head1 METHODS

=over

=item check

Gathers the metric data and returns an arrayref of hashrefs with keys C<MetricName>, C<Unit>, C<RawValue>.

=back

=head1 ARGUMENTS

=over

=item --maillog-path </path/to/maillog>

The C<--maillog-path> argument is required and defines the full path, with filename, where the maillog can be read.

 aws-cloudwatch-monitor --check MailSummary --maillog-path /var/log/mail.log

=item --maillog-time <hh:mm>

The optional C<--maillog-time> argument may be defined to specify which hour to get mailstats for.

 aws-cloudwatch-monitor --check MailSummary --maillog-path /var/log/mail.log --maillog-time 23:00

C<maillog-time> must be formatted 24hr and minute (hh:mm).

If C<maillog-time> isn't defined, mailstats are gathered for the previous hour.

=back

=head1 DEPENDENCIES

C<App::AWS::CloudWatch::Monitor::Check::MailSummary> depends on the external program, L<pflogsumm(1)>.

=cut
