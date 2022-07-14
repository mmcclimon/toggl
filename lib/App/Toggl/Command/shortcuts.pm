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

    # if this is a description-less task, just use the project
    my $desc = $task->{desc}
             ? "$task->{desc} ($task->{project})"
             : "$task->{project} (*taskless*)";

    printf "%-${len}s  %s\n", "\@$sc", $desc;
  }
}

1;
