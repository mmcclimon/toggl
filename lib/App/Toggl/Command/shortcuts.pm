package App::Toggl::Command::shortcuts;
# ABSTRACT: list the things can you start easily

use App::Toggl -command;
use v5.30;
use warnings;
use experimental 'signatures';

sub opt_spec {
  [ 'project|p=s', 'project shorcut for this timer' ],
}

sub execute ($self, $opt, $args) {
  my $shortcuts = $self->toggl->task_shortcuts;

  require List::Util;
  my $len = 2 + List::Util::max(map {; length } keys %$shortcuts);

  for my $sc (sort keys %$shortcuts) {
    my $task = $shortcuts->{$sc};
    printf "%-${len}s  %s (%s)\n", "\@$sc", $task->{desc}, $task->{project};
  }
}

1;
