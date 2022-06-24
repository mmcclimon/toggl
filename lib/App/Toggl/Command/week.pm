package App::Toggl::Command::week;
# ABSTRACT: how's the week been?

use App::Toggl -command;
use v5.30;
use warnings;
use experimental 'signatures';

sub opt_spec {
  [ 'client|c=s', 'only include data for this client' ],
}

sub execute ($self, $opt, $args) {
  require DateTime;
  require List::Util;

  my $start = DateTime->now(time_zone => 'local')->truncate(to => 'week');
  my $end = DateTime->now(time_zone => 'local');

  my $entries = $self->toggl->get_time_entries($start, $end);
  $self->toggl->format_entry_list($entries, $opt->client);
}

1;
