package App::Toggl::Command::resume;
# ABSTRACT: restart the last thing you were doing

use App::Toggl -command;
use v5.30;
use warnings;
use experimental 'signatures';

sub execute ($self, $opt, $args) {
  require DateTime;
  my $start = DateTime->now(time_zone => 'local')->subtract(hours => 6);
  my $end   = DateTime->now(time_zone => 'local');

  # I'm assuming here that these will come back in sorted order
  my $entries = $self->toggl->get_time_entries($start, $end);
  my $last = $entries->[-1];

  unless ($last) {
    say "I dunno what you were last up to, sorry.";
    return;
  }

  my $timer = $self->toggl->start_timer($last->{description}, $last->{pid});

  printf "started timer: %s\n", $self->toggl->oneline_desc($timer);
}

1;
