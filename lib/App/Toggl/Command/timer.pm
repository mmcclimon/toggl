package App::Toggl::Command::timer;
# ABSTRACT: what are you doing right now?

use App::Toggl -command;
use v5.30;
use warnings;
use experimental 'signatures';

sub command_names { 'timer', 'current', 'now' }

sub execute ($self, $opt, $args) {
  my $timer = $self->toggl->get_current_timer;

  unless ($timer) {
    say "You don't have a running timer!";
    return;
  }

  printf "%s so far: %s\n",
    $self->format_duration(time + $timer->{duration}),
    $self->toggl->oneline_desc($timer);
}

1;
