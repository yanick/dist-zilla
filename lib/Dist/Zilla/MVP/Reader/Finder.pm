package Dist::Zilla::MVP::Reader::Finder;
use Moose;
use Config::MVP::Reader 2.101540; # if_none
extends 'Config::MVP::Reader::Finder';
# ABSTRACT: the reader for dist.ini files

use Dist::Zilla::MVP::Assembler;

sub default_search_path {
  return qw(Dist::Zilla::MVP::Reader Config::MVP::Reader);
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
