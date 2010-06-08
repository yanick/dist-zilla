package Dist::Zilla::Plugin::DistINI;
# ABSTRACT: a plugin to add a dist.ini to newly-minted dists
use Moose;
with qw(Dist::Zilla::Role::FileGatherer);

use Dist::Zilla::File::FromCode;

=head1 DESCRIPTION

This plugins produces a F<dist.ini> file in a new dist, specifying the required
core attributes from the dist being minted.

This plugin is dead simple and pretty stupid, but should get better as dist
minting facilities improve.  For example, it will not specify any plugins.

In the meantime, you may be happier with a F<dist.ini> template.

=cut

sub gather_files {
  my ($self, $arg) = @_;

  my $zilla = $self->zilla;
  my $code = sub {
    my @core_attrs = qw(name authors copyright_holder);

    my $license = ref $zilla->license;
    if ($license =~ /^Software::License::(.+)$/) {
      $license = $1;
    } else {
      $license = "=$license";
    }

    my $content = '';
    $content .= sprintf "name    = %s\n", $zilla->name;
    $content .= sprintf "author  = %s\n", $_ for @{ $zilla->authors };
    $content .= sprintf "license = %s\n", $license;
    $content .= sprintf "copyright_holder = %s\n", $zilla->copyright_holder;
    $content .= sprintf "copyright_year   = %s\n", (localtime)[5] + 1900;
    $content .= "\n";
  };

  my $file = Dist::Zilla::File::FromCode->new({
    name => 'dist.ini',
    code => $code,
  });

  $self->add_file($file);
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
