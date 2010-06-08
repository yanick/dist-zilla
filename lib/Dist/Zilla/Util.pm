use strict;
use warnings;
package Dist::Zilla::Util;
# ABSTRACT: random snippets of code that Dist::Zilla wants

use String::RewritePrefix 0.002; # better string context behavior

{
  package
    Dist::Zilla::Util::PEA;
  use Pod::Eventual 0.091480; # better nonpod/blank events
  use base 'Pod::Eventual';
  sub _new  { bless {} => shift; }
  sub handle_nonpod {
    my ($self, $event) = @_;
    return if $self->{abstract};
    return $self->{abstract} = $1
      if $event->{content}=~ /^\s*#+\s*ABSTRACT:\s*(.+)$/m;
    return;
  }
  sub handle_event {
    my ($self, $event) = @_;
    return if $self->{abstract};
    if (
      ! $self->{in_name}
      and $event->{type} eq 'command'
      and $event->{command} eq 'head1'
      and $event->{content} =~ /^NAME\b/
    ) {
      $self->{in_name} = 1;
      return;
    }

    return unless $self->{in_name};
    
    if (
      $event->{type} eq 'text'
      and $event->{content} =~ /^\S+\s+-+\s+(.+)$/
    ) {
      $self->{abstract} = $1;
    }
  }
}

=method abstract_from_file

This method, I<which is likely to change or go away>, tries to guess the
abstract of a given file, assuming that it's Perl code.  It looks for a POD
C<=head1> section called "NAME" or a comment beginning with C<ABSTRACT:>.

=cut

sub abstract_from_file {
  my ($self, $filename) = @_;
  my $e = Dist::Zilla::Util::PEA->_new;
  $e->read_file($filename);
  return $e->{abstract};
}

=method expand_config_package_name 

  my $pkg_name = Util->expand_config_package_name($string);

This method, I<which is likely to change or go away>, rewrites the given string
into a package name.  Consult L<Dist::Zilla::Config|Dist::Zilla::Config> for
more information.

=cut

sub expand_config_package_name {
  my ($self, $package) = @_;

  my $str = String::RewritePrefix->rewrite(
    {
      '=' => '',
      '@' => 'Dist::Zilla::PluginBundle::',
      '%' => 'Dist::Zilla::Stash::',
      ''  => 'Dist::Zilla::Plugin::',
    },
    $package,
  );

  return $str;
}

1;
