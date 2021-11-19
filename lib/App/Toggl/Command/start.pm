package App::Toggl::Command::start;
# ABSTRACT: start doing a new thing

use App::Toggl -command;
use v5.30;
use warnings;
use experimental 'signatures';

sub opt_spec {
  [ 'project|p=s', 'project shorcut for this timer' ],
}

sub execute ($self, $opt, $args) {
  my $desc = join q{ }, @$args;
  die "gotta have a description\n" unless $desc;

  my $project_id;
  if (my $p = $opt->project) {
    $project_id = $self->toggl->projects->{$p};
  }

  if (my ($sc) = $desc =~ /^@(\w+)/) {
    my $got = $self->toggl->resolve_shortcut($sc);
    die "could not resolve shortcut $desc\n" unless $got;
    $desc = $got;
    $project_id = $self->toggl->projects->{evergreen};
  }

  my $t = $self->toggl->start_timer($desc, $project_id);
  say "started timer: " . $self->toggl->oneline_desc($t);
}

1;
