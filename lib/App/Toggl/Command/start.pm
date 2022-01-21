package App::Toggl::Command::start;
# ABSTRACT: start doing a new thing

use App::Toggl -command;
use v5.30;
use warnings;
use experimental 'signatures';

sub opt_spec {
  [ 'project|p=s', 'project shorcut for this timer' ],
  [ 'id|i=s',      'linear id for this timer' ],
}

sub execute ($self, $opt, $args) {
  my $desc = join q{ }, @$args;
  die "gotta have a description or an id\n" unless $opt->id xor $desc;

  if (my $task_id = $opt->id) {
    my $task = $self->toggl->resolve_linear_id(uc $task_id);
    die "sorry, couldn't find that task\n" unless $task;

    return $self->_start($task->@{qw(description project_id)});
  }

  my $project_id;
  if (my $p = $opt->project) {
    $project_id = $self->toggl->projects->{$p};
  }

  if (my ($sc) = $desc =~ /^@(\w+)/) {
    my $got = $self->toggl->resolve_shortcut($sc);
    die "could not resolve shortcut $desc\n" unless $got;

    $desc = $got->{desc};

    my $pname = $got->{project};
    $project_id = $self->toggl->projects->{$pname};
  }

  return $self->_start($desc, $project_id);
}

sub _start ($self, $desc, $project_id) {
  my $t = $self->toggl->start_timer($desc, $project_id);
  say "started timer: " . $self->toggl->oneline_desc($t);
}

1;
