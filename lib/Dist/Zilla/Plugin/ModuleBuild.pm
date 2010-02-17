package Dist::Zilla::Plugin::ModuleBuild;
# ABSTRACT: build a Build.PL that uses Module::Build
use List::MoreUtils qw(any uniq);
use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::BuildRunner';
with 'Dist::Zilla::Role::InstallTool';
with 'Dist::Zilla::Role::TextTemplate';
with 'Dist::Zilla::Role::TestRunner';
with 'Dist::Zilla::Role::MetaProvider';

use Dist::Zilla::File::InMemory;
use List::MoreUtils qw(any uniq);
=head1 DESCRIPTION

This plugin will create a F<Build.PL> for installing the dist using
L<Module::Build>.

=cut

=attr mb_version

B<Optional:> Specify the minimum version of L<Module::Build> to depend on.

Defaults to 0.3601

=cut

has 'mb_version' => (
  isa => 'Str',
  is  => 'rw',
  default => '0.3601',
);

my $template = q|
use strict;
use warnings;

use Module::Build 0.3601;

my {{ $module_build_args }}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
|;

sub metadata {
  my ($self) = @_;
  return {
    configure_requires => { 'Module::Build' => $self->mb_version },
    build_requires     => { 'Module::Build' => $self->mb_version },
  };
}

sub setup_installer {
  my ($self, $arg) = @_;

  Carp::croak("can't build a Build.PL; license has no known META.yml value")
    unless $self->zilla->license->meta_yml_name;

  (my $name = $self->zilla->name) =~ s/-/::/g;

  # XXX: SHAMELESSLY COPIED AND PASTED FROM MakeMaker -- rjbs, 2010-01-05
  my @dir_plugins = $self->zilla->plugins
    ->grep( sub { $_->isa('Dist::Zilla::Plugin::InstallDirs') })
    ->flatten;

  my @bin_dirs    = uniq map {; $_->bin->flatten   } @dir_plugins;
  my @share_dirs  = uniq map {; $_->share->flatten } @dir_plugins;

  confess "can't install more than one ShareDir" if @share_dirs > 1;

  my @exe_files = $self->zilla->files
    ->grep(sub { my $f = $_; any { $f->name =~ qr{^\Q$_\E[\\/]} } @bin_dirs; })
    ->map( sub { $_->name })
    ->flatten;

  confess "can't install files with whitespace in their names"
    if grep { /\s/ } @exe_files;

  my %module_build_args = (
    module_name   => $name,
    license       => $self->zilla->license->meta_yml_name,
    dist_abstract => $self->zilla->abstract,
    dist_name     => $self->zilla->name,
    dist_version  => $self->zilla->version,
    dist_author   => [ $self->zilla->authors->flatten ],
    script_files  => \@exe_files,
    (defined $share_dirs[0] ? (share_dir => $share_dirs[0]) : ()),

    # I believe it is a happy coincidence, for the moment, that this happens to
    # return just the same thing that is needed here. -- rjbs, 2010-01-22
    $self->zilla->prereq->as_distmeta->flatten,
  );

  my $module_build_dumper = Data::Dumper->new(
    [ \%module_build_args ],
    [ '*module_build_args' ],
  );

  my $content = $self->fill_in_string(
    $template,
    {
      module_build_args => \($module_build_dumper->Dump),
    },
  );

  my $file = Dist::Zilla::File::InMemory->new({
    name    => 'Build.PL',
    content => $content,
  });

  $self->add_file($file);
  return;
}

sub build {
  my $self = shift;
  system($^X => 'Build.PL') and die "error with Build.PL\n";
  system('./Build')         and die "error running ./Build\n";
  return;
}

sub test {
  my ( $self, $target ) = @_;
  ## no critic Punctuation
  $self->build;
  system('./Build test') and die "error running ./Build test\n";
  return;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
