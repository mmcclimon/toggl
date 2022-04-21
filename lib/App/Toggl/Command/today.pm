package App::Toggl::Command::today;
# ABSTRACT: what are the things you've done today?

use App::Toggl -command;
use v5.30;
use warnings;
use experimental 'signatures';

# from docs: if the time entry is currently running, the duration attribute
# contains a negative value, denoting the start of the time entry in seconds
# since epoch (Jan 1 1970). The correct duration can be calculated as
# current_time + duration, where current_time is the current time in seconds
# since epoch.
my sub real_dur ($dur) { $dur >= 0 ? $dur : time + $dur }

sub execute ($self, $opt, $args) {
  require DateTime;
  require List::Util;

  my $start = DateTime->now(time_zone => 'local')->truncate(to => 'day');
  my $end = DateTime->now(time_zone => 'local');

  my $entries = $self->toggl->get_time_entries($start, $end);

  # we build a map of $project/description => duration
  my %entries;
  for my $e (@$entries) {
    my $k = sprintf "%s!%s", $e->{pid} // '0', $e->{description} // '';
    $entries{$k} += real_dur($e->{duration});
  }

  my $total = 0;

  for my $k (sort keys %entries) {
    my ($pid, $title) = split /!/, $k, 2;
    my $dur = $entries{$k} / 3600;    # in hours

    $total += $entries{$k};

    my $project = $self->toggl->project_name_for($pid);
    my $desc = $title ? "$title ($project)" : $project;
    printf "%5.2fh  %s\n", $dur, $desc;
  }

  printf "------\n";
  printf "%5.2fh  total (%s)\n", $total / 3600, $self->format_duration($total);
}

1;
