package App::Toggl::Command::today;
# ABSTRACT: today's timesheet

use App::Toggl -command;
use v5.30;
use warnings;
use experimental 'signatures';

sub execute ($self, $opt, $args) {
  ...
}

1;
