package Dist::Zilla::Plugin::MakeMaker;

# ABSTRACT: build a Makefile.PL that uses ExtUtils::MakeMaker
use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::BuildRunner';
with 'Dist::Zilla::Role::PrereqSource';
with 'Dist::Zilla::Role::InstallTool';
with 'Dist::Zilla::Role::TestRunner';
with 'Dist::Zilla::Role::TextTemplate';

=head1 DESCRIPTION

This plugin will produce an L<ExtUtils::MakeMaker>-powered F<Makefile.PL> for
the distribution.  If loaded, the L<Manifest|Dist::Zilla::Plugin::Manifest>
plugin should also be loaded.

=cut

use Config;

use Data::Dumper ();
use List::MoreUtils qw(any uniq);

use namespace::autoclean;

use Dist::Zilla::File::InMemory;

my $template = q|
use strict;
use warnings;

{{ $perl_prereq ? qq{ BEGIN { require $perl_prereq; } } : ''; }}

use ExtUtils::MakeMaker {{ $eumm_version }};

{{ $share_dir_block[0] }}

my {{ $WriteMakefileArgs }}

unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

{{ $share_dir_block[1] }}

|;

sub register_prereqs {
  my ($self) = @_;

  $self->zilla->register_prereqs(
    { phase => 'configure' },
    'ExtUtils::MakeMaker' => $self->eumm_version,
  );

  return unless $self->zilla->_share_dir;

  $self->zilla->register_prereqs(
    { phase => 'configure' },
    'File::ShareDir::Install' => 0.03,
  );
}

sub setup_installer {
  my ($self, $arg) = @_;

  (my $name = $self->zilla->name) =~ s/-/::/g;

  my @exe_files =
    $self->zilla->find_files(':ExecFiles')->map(sub { $_->name })->flatten;

  $self->log_fatal("can't install files with whitespace in their names")
    if grep { /\s/ } @exe_files;

  my %test_dirs;
  for my $file ($self->zilla->files->flatten) {
    next unless $file->name =~ m{\At/.+\.t\z};
    (my $dir = $file->name) =~ s{/[^/]+\.t\z}{/*.t}g;

    $test_dirs{ $dir } = 1;
  }

  my @share_dir_block = (q{}, q{});

  if (my $share_dir = $self->zilla->_share_dir) {
    my $share_dir = quotemeta $share_dir;
    @share_dir_block = (
      qq{use File::ShareDir::Install;\ninstall_share "$share_dir";\n},
      qq{package\nMY;\nuse File::ShareDir::Install qw(postamble);\n},
    );
  }

  my $prereqs = $self->zilla->prereqs;
  my $perl_prereq = $prereqs->requirements_for(qw(runtime requires))
                  ->as_string_hash->{perl};

  my $prereqs_dump = sub {
    $prereqs->requirements_for(@_)
            ->clone
            ->clear_requirement('perl')
            ->as_string_hash;
  };

  my $build_prereq
    = $prereqs->requirements_for(qw(build requires))
    ->clone
    ->add_requirements($prereqs->requirements_for(qw(test requires)))
    ->as_string_hash;

  my %write_makefile_args = (
    DISTNAME  => $self->zilla->name,
    NAME      => $name,
    AUTHOR    => $self->zilla->authors->join(q{, }),
    ABSTRACT  => $self->zilla->abstract,
    VERSION   => $self->zilla->version,
    LICENSE   => $self->zilla->license->meta_yml_name,
    EXE_FILES => [ @exe_files ],

    CONFIGURE_REQUIRES => $prereqs_dump->(qw(configure requires)),
    BUILD_REQUIRES     => $build_prereq,
    PREREQ_PM          => $prereqs_dump->(qw(runtime   requires)),

    test => { TESTS => join q{ }, sort keys %test_dirs },
  );

  $self->__write_makefile_args(\%write_makefile_args);

  my $makefile_args_dumper = Data::Dumper->new(
    [ \%write_makefile_args ],
    [ '*WriteMakefileArgs' ],
  );
  $makefile_args_dumper->Sortkeys( 1 );
  $makefile_args_dumper->Indent( 1 );

  my $content = $self->fill_in_string(
    $template,
    {
      eumm_version      => \($self->eumm_version),
      perl_prereq       => \$perl_prereq,
      share_dir_block   => \@share_dir_block,
      WriteMakefileArgs => \($makefile_args_dumper->Dump),
    },
  );

  my $file = Dist::Zilla::File::InMemory->new({
    name    => 'Makefile.PL',
    content => $content,
  });

  $self->add_file($file);
  return;
}

# XXX:  Just here to facilitate testing. -- rjbs, 2010-03-20
has __write_makefile_args => (
  is   => 'rw',
  isa  => 'HashRef',
);

has 'make_path' => (
  isa => 'Str',
  is  => 'ro',
  default => $Config{make} || 'make',
);

sub build {
  my $self = shift;

  my $make = $self->make_path;
  system($^X => 'Makefile.PL') and die "error with Makefile.PL\n";
  system($make)                and die "error running $make\n";

  return;
}

sub test {
  my ( $self, $target ) = @_;

  my $make = $self->make_path;
  $self->build;
  system($make, 'test') and die "error running $make test\n";

  return;
}

has 'eumm_version' => (
  isa => 'Str',
  is  => 'rw',
  default => '6.31',
);

__PACKAGE__->meta->make_immutable;
no Moose;
1;
