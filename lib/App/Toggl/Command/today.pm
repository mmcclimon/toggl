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

  my $start = DateTime->now(time_zone => 'local')->truncate(to => 'day');
  my $end = DateTime->now(time_zone => 'local');

  my $entries = $self->toggl->get_time_entries($start, $end);
  $self->toggl->format_entry_list($entries);
}

1;
