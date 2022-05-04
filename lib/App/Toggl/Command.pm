use v5.30;
use warnings;
package App::Toggl::Command;

use parent 'App::Cmd::Command';
use experimental 'signatures';
use Toggl;

sub toggl {
  state $toggl = Toggl->new;
  return $toggl;
}

sub format_duration ($self, $dur) {
  return $self->toggl->format_duration($dur);
}

1;
