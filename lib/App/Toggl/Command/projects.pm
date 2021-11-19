package App::Toggl::Command::projects;
# ABSTRACT: list the buckets things can go in

use App::Toggl -command;
use v5.30;
use warnings;
use experimental 'signatures';
use utf8;

sub execute ($self, $opt, $args) {
  my $projects = $self->toggl->projects;

  unless (%$projects) {
    say "no projects configured  ¯\_(ツ)_/¯";
    return;
  }

  for my $k (sort keys %$projects) {
    say "- $k ($projects->{$k})";
  }
}

1;
