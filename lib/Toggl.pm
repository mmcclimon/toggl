use v5.30;
use warnings;
package Toggl;
# ABSTRACT: it's an api client

use Moo;
use experimental 'signatures';

use JSON::MaybeXS qw(encode_json decode_json);
use LWP::UserAgent;
use MIME::Base64 qw(encode_base64);
use URI;

has lwp => (
  is => 'ro',
  lazy => 1,
  default => sub ($self) {
    my $lwp = LWP::UserAgent->new;
    $lwp->default_header($self->auth_header->@*);
    $lwp->default_header(Content_Type => 'application/json');
    return $lwp;
  },
);

has api_token => (
  is => 'ro',
  lazy => 1,
  default => sub { $ENV{TOGGL_API_TOKEN} },
);

has auth_header => (
  is => 'ro',
  lazy => 1,
  default => sub ($self) {
    my $auth = encode_base64(join(q{:}, $self->api_token, 'api_token'), '');
    return [ Authorization => "Basic $auth" ];
  },
);

sub BUILD ($self, $args) {
  die "no api token found! (maybe set TOGGL_API_TOKEN?)\n"
    unless $self->api_token;
}

sub url_for ($self, $endpoint, $params = {}) {
  my $uri = URI->new('https://api.track.toggl.com/api/v8' . $endpoint);
  $uri->query_form(%$params) if $params;
  return $uri;
}

sub _do_get ($self, $endpoint, $arg = {}) {
  my $res = $self->lwp->get($self->url_for($endpoint, $arg));
  unless ($res->is_success) {
    die "d'oh, error trying to GET $endpoint\n" . $res->as_string;
  }

  return decode_json($res->decoded_content);
}

sub get_time_entries ($self, $start, $end) {
  # GET https://api.track.toggl.com/api/v8/time_entries
  require DateTime::Format::ISO8601;
  my $s = DateTime::Format::ISO8601->format_datetime($start);
  my $e = DateTime::Format::ISO8601->format_datetime($end);

  my $params = { start_date => $s, end_date => $e };

  my $entries = $self->_do_get('/time_entries', $params);
  return $entries;
}

1;
