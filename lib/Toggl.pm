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

has config => (
  is => 'ro',
  lazy => 1,
  default => sub ($self) {
    require Path::Tiny;

    my $filename = $ENV{TOGGL_CONFIG_FILE} // '~/.togglrc';
    my $path = Path::Tiny::path("~/.togglrc");

    return {} unless $path->is_file;

    require TOML::Parser;
    return TOML::Parser->new->parse($path->slurp);
  },
);

for my $attr (qw( api_token workspace_id )) {
  has $attr => (
    is => 'ro',
    lazy => 1,
    default => sub ($self) { $self->config->{$attr} }
  );
}

has auth_header => (
  is => 'ro',
  lazy => 1,
  default => sub ($self) {
    my $auth = encode_base64(join(q{:}, $self->api_token, 'api_token'), '');
    return [ Authorization => "Basic $auth" ];
  },
);

has projects => (
  is => 'ro',
  lazy => 1,
  default => sub ($self) { $self->config->{project_shortcuts} }
);

has _proj_by_id => (
  is => 'ro',
  lazy => 1,
  default => sub ($self) { +{ reverse $self->projects->%* } }
);

# shortcut => description
has task_shortcuts => (
  is => 'ro',
  lazy => 1,
  default => sub ($self) { $self->config->{task_shortcuts} // {} }
);

has ua_string => (
  is => 'ro',
  lazy => 1,
  default => sub ($self) { $self->config->{ua_string} // 'toggl/perl' }
);

has linear_conf => (
  is => 'ro',
  lazy => 1,
  default => sub ($self) {
    my $conf = $self->config->{linear};
    die "tried to call ->linear_conf, but there isn't one!\n" unless $conf;
    return $conf;
  },
);

has linear_client => (
  is => 'ro',
  lazy => 1,
  default => sub ($self) {
    require Linear::Client;
    return Linear::Client->new({
      auth_token => $self->linear_conf->{api_token},
    });
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

sub _decode_or_throw ($self, $http_res) {
  unless ($http_res->is_success) {
    die "d'oh, http error\n" . $http_res->as_string;
  }

  return decode_json($http_res->decoded_content);
}

sub _do_get ($self, $endpoint, $arg = {}) {
  my $res = $self->lwp->get($self->url_for($endpoint, $arg));
  return $self->_decode_or_throw($res);
}

sub _do_put ($self, $endpoint, $arg = {}) {
  my $res = $self->lwp->put($self->url_for($endpoint, $arg));
  return $self->_decode_or_throw($res);
}

sub _do_post ($self, $endpoint, $data) {
  my $res = $self->lwp->post(
    $self->url_for($endpoint),
    Content => encode_json($data),
  );

  return $self->_decode_or_throw($res);
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

sub get_current_timer ($self) {
  my $data = $self->_do_get('/time_entries/current');
  return $data->{data};   # maybe undef
}

sub stop_current_timer ($self) {
  my $timer = $self->_do_get('/time_entries/current')->{data};
  return unless $timer;

  my $data = $self->_do_put("/time_entries/$timer->{id}/stop");
  return $data->{data};
}

sub abort_current_timer ($self) {
  my $timer = $self->_do_get('/time_entries/current')->{data};
  return unless $timer;

  my $res = $self->lwp->delete($self->url_for("/time_entries/$timer->{id}"));
  die "d'oh, http error\n" . $res->as_string unless $res->is_success;

  return $timer;
}

sub start_timer ($self, $description, $project_id = undef) {
  require DateTime;
  require DateTime::Format::ISO8601;
  my $now = DateTime->now(time_zone => 'local');

  my $timer = $self->_do_post('/time_entries/start', {
    time_entry => {
      description  => $description,
      created_with => $self->ua_string,
      start        => DateTime::Format::ISO8601->format_datetime($now),
      wid          => $self->workspace_id,
      ($project_id ? (pid => $project_id) : ()),
    }
  });

  return $timer->{data};
}

sub project_name_for ($self, $pid) { $self->_proj_by_id->{$pid} // '--' }

sub oneline_desc ($self, $timer) {
  my $proj = $self->project_name_for($timer->{pid} // '');

  # we don't use a description and log all time against the project itself
  return $proj if $proj && ! $timer->{description};

  return "$timer->{description} ($proj)";
}

sub resolve_shortcut ($self, $sc) { $self->task_shortcuts->{$sc} }

sub resolve_linear_id ($self, $id) {
  my $res = $self->linear_client->do_query(
    q[
      query Issue ($id: String!) {
        issue (id: $id) {
          title
          identifier
          project { slugId }
        }
      }
    ],
    { id => $id },
  )->await;

  return unless $res->is_done;

  my $issue = $res->result->{data}{issue};
  return unless $issue;

  my $desc = lc($issue->{identifier}) . q{: } . $issue->{title};
  my $slug = $issue->{project}{slugId} // '';

  my $projects = $self->linear_conf->{projects};
  my $proj = $projects->{$slug} // $projects->{DEFAULT};

  return {
    description => $desc,
    project_id  => $proj,
  };
}

1;
