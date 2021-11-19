package App::Toggl::Command::abort;
# ABSTRACT: actually, you weren't doing that thing after all

use App::Toggl -command;
use v5.30;
use warnings;
use experimental 'signatures';

sub execute ($self, $opt, $args) {
  my $timer = $self->toggl->abort_current_timer;

  unless ($timer) {
    say "You don't have a running timer!";
    return;
  }

  say "aborted timer: " . $self->toggl->oneline_desc($timer);
}

1;
