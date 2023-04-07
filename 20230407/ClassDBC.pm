#!/usr/bin/perl

package ClassDBC;

use strict;
use warnings;
# database
use DBI;

sub new {
  my $class = shift;
  my $self = {
    _base => shift,
    _user => shift,
    _pass => shift,
    _dbch => undef
  };
  $self->{_dbch} = DBI->connect($self->{_base}, $self->{_user}, $self->{_pass});
  return undef unless $self->{_dbch};
  bless $self, $class;
  return $self;
}

sub sql_exec {
  my $self = shift;
  my $sql = shift;
  my @list = ();
  return @list unless defined $sql;
  my $sth = $self->{_dbch}->prepare($sql);
  $sth->execute(@_);
  if ((defined $sth->{NUM_OF_FIELDS}) && ($sth->{NUM_OF_FIELDS} > 0)) {
    while (my $href = $sth->fetchrow_hashref) {
      push(@list, $href);
    }
  }
  $sth->finish();
  return @list;
}

sub DESTROY {
  my $self = shift;
  $self->{_dbch}->disconnect();
}

1;
