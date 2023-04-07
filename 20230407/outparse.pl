#!/usr/bin/perl

use strict;
use warnings;
# config
require './config.pl';
# database
use ClassDBC;

sub log_parse {
  # output database
  my $db = ClassDBC->new(sql_get_base(), sql_get_user(), sql_get_pass());
  return 2 unless $db;
  # input file
  my $filename = shift;
  return 3 unless defined $filename;
  open(HFILE, '<', $filename) or return 4;
  # for each line
  while (<HFILE>) {
    # sanity checks from eximstats
    my $length = length($_);
    # too short
    next if ($length < 38);
    # no correct date time at start (misc log information)
    # also add ######-######-## since misc log not needed
    next unless /^(\d{4}\-\d\d-\d\d\s\d\d:\d\d:\d\d)(\.\d+)?(\s[-+]\d\d\d\d)?(\s\[\d+\])?\s(([\da-zA-Z]{6}\-[\da-zA-Z]{6}\-[\da-zA-Z]{2})\s(.+))/o;
    my $created = $1;
    my $int_id = $6;
    my $str = $5;
    my $txt = $7;
    my $op = $1 if $txt =~ /^([^\s]+)/o;
    my $id = undef;
    my $status = undef;
    my $address = undef;
    if ($op eq '<=') {
      if ($txt =~ /<>\sR=([\da-zA-Z]{6}\-[\da-zA-Z]{6}\-[\da-zA-Z]{2})/o) {
        # delivery failed
        $status = 0;
        $id = $1; # mark
      } elsif ($txt =~ /id=([^\s]+)/o) {
        # delivery started
        $status = 2;
        $id = $1;
      }
    } elsif ($op =~ /^(=>)|(\->)|(\*\*)|(==)$/o) {
      # drop anything related to /dev/null
      if (($txt !~ /:blackhole:/o) && ($txt !~ /R=blackhole_router/o)) {
        $address = $1 if $txt =~ /..\s([^\s:]+)/o;
        # special case on delivery failed
        if ($op eq '**') {
          $status = 0;
        }
      }
    } elsif ($op eq 'Completed') {
      # delivery completed
      $status = 1;
    }
    # log everything
    $db->sql_exec('INSERT INTO log VALUES (?, ?, ?, LOWER(?))', $created, $int_id, $str, $address);
    # only message table applicable
    if (defined $status) {
      if ($status == 2) {
        # new delivery
        $db->sql_exec("INSERT INTO message (created,id,int_id,str) VALUES (?, ?, ?, ?)", $created, $id, $int_id, $str);
      } else {
        # update delivery state
        $int_id = $id if defined $id; # mark
        $db->sql_exec("UPDATE message SET status = ? WHERE int_id = ? AND status IS NULL", $status, $int_id);
      }
    }
  }
  close(HFILE);
  return 0;
}

  if (scalar @ARGV != 1) {
    my $filename = $1 if __FILE__ =~ /([^\/\\]+)$/o;
    print "Usage: $filename <maillog>\n";
    exit 1;
  }
  exit log_parse($ARGV[0]);
