use strict;
use warnings;

package Dist::Zilla::App::Command::plugins;
# ABSTRACT: prints available Dist::Zilla plugins

use Dist::Zilla::App -command;

use autodie;

use Moose::Autobox;

use Module::Pluggable search_path => 'Dist::Zilla::Plugin', require => 1;

sub abstract { 'print all available plugins' }

sub execute {
  my ($self, $opt, $arg) = @_;

  my %loaded_plugins = map { $_->plugin_name => 1 } @{ $self->zilla->plugins };

  for my $plugin ( sort $self->plugins ) {
      ( my $t = $plugin ) =~ s/::/\//g;
      $t .= '.pm';

      my $abstract = get_plugin_abstract( $INC{$t} ) or next;

      $plugin =~ s/^.*:://;
      $abstract =~ s/Dist::Zilla::Plugin:://;

      print $loaded_plugins{ $plugin } ? '* ' : '  ';
      print $abstract, "\n";
  }

}

sub get_plugin_abstract {
    my $filename = shift or return;

    local $/ = undef; 
    open my $fh, '<', $filename;

    my $pod = <$fh>;

    return $pod =~ /=head1\s+NAME\s+?\n(^.*$)/m ? $1 : undef;
}

1;

__END__

=head1 SYNOPSIS

Show all available Dist::Zilla plugins on the system:

  dzil plugins

Plugins that are active for this distribution will be labelled with a start ('*').

=cut
