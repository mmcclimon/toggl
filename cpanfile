# This file is generated by Dist::Zilla::Plugin::CPANFile v6.020
# Do not edit this file directly. To change prereqs, edit the `dist.ini` file.

requires "App::Cmd::Command" => "0";
requires "App::Cmd::Setup" => "0";
requires "DateTime" => "0";
requires "DateTime::Format::ISO8601" => "0";
requires "JSON::MaybeXS" => "0";
requires "LWP::UserAgent" => "0";
requires "List::Util" => "0";
requires "MIME::Base64" => "0";
requires "Moo" => "0";
requires "Time::Duration" => "0";
requires "URI" => "0";
requires "base" => "0";
requires "experimental" => "0";
requires "perl" => "v5.30.0";
requires "warnings" => "0";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "Test::More" => "0.96";
  requires "strict" => "0";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};

on 'develop' => sub {
  requires "Encode" => "0";
  requires "Test::More" => "0";
  requires "Test::Pod" => "1.41";
  requires "strict" => "0";
};