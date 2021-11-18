package App::Toggl::Command::today;
# ABSTRACT: today's timesheet

use App::Toggl -command;
use v5.30;
use warnings;
use experimental 'signatures';

sub execute ($self, $opt, $args) {
  require DateTime;
  require List::Util;

  my $start = DateTime->now->truncate(to => 'day');
  my $end = DateTime->now;

  my $entries = $self->toggl->get_time_entries($start, $end);

  my $total = List::Util::sum0(map {; $_->{duration}} @$entries);

  say "total logged today: " . $self->format_duration($total);
}

1;
