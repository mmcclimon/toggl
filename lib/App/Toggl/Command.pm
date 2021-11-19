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
  require Time::Duration;
  return Time::Duration::concise(Time::Duration::duration($dur));
}

1;
