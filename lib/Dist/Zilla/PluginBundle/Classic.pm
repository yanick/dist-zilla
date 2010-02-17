package Dist::Zilla::PluginBundle::Classic;
# ABSTRACT: build something more or less like a "classic" CPAN dist
use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::PluginBundle';

sub bundle_config {
  my ($self) = @_;
  my $class = (ref $self) || $self;

  my @classes = qw(
    Dist::Zilla::Plugin::AllFiles
    Dist::Zilla::Plugin::PruneCruft
    Dist::Zilla::Plugin::ManifestSkip
    Dist::Zilla::Plugin::MetaYAML
    Dist::Zilla::Plugin::License
    Dist::Zilla::Plugin::Readme
    Dist::Zilla::Plugin::PodTests
    Dist::Zilla::Plugin::ExtraTests
    Dist::Zilla::Plugin::InstallDirs

    Dist::Zilla::Plugin::MakeMaker
    Dist::Zilla::Plugin::Manifest

    Dist::Zilla::Plugin::UploadToCPAN
  );

  eval "require $_; 1" or die for @classes; ## no critic Carp

  return @classes->map(sub { [ "$class/$_" => $_ => {} ] })->flatten;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
__END__

=head1 DESCRIPTION

This bundle is meant to do just about everything needed for building a plain
ol' CPAN distribution in the manner of our forefathers.

It includes the following plugins with their default configuration:

=over

=item * L<Dist::Zilla::Plugin::AllFiles>

=item * L<Dist::Zilla::Plugin::PruneCruft>

=item * L<Dist::Zilla::Plugin::ManifestSkip>

=item * L<Dist::Zilla::Plugin::MetaYAML>

=item * L<Dist::Zilla::Plugin::License>

=item * L<Dist::Zilla::Plugin::Readme>

=item * L<Dist::Zilla::Plugin::PkgVersion>

=item * L<Dist::Zilla::Plugin::PodVersion>

=item * L<Dist::Zilla::Plugin::PodTests>

=item * L<Dist::Zilla::Plugin::ExtraTests>

=item * L<Dist::Zilla::Plugin::InstallDirs>

=item * L<Dist::Zilla::Plugin::MakeMaker>

=item * L<Dist::Zilla::Plugin::Manifest>

=back

=cut

