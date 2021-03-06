package App::Toggl::Command::stop;
# ABSTRACT: stop doing the thing you're doing

use App::Toggl -command;
use v5.30;
use warnings;
use experimental 'signatures';

sub command_names { 'stop', 'stpo' }

sub execute ($self, $opt, $args) {
  my $timer = $self->toggl->stop_current_timer;

  unless ($timer) {
    say "You don't have a running timer!";
    return;
  }

  printf "spent %s: %s\n",
    $self->format_duration($timer->{duration}),
    $self->toggl->oneline_desc($timer);
}

1;
