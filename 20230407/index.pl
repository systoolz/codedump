#!/usr/bin/perl

use strict;
use warnings;
# web
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use HTML::Entities qw(encode_entities);
# config
require './config.pl';
# database
use ClassDBC;

# subroutine
sub val_post {
  my $name = shift;
  return undef unless defined $name;
  my $value = shift;
  my $cgi = CGI->new;
  if ($cgi->request_method && ($cgi->request_method eq 'POST') && ($cgi->param($name))) {
    $value = $cgi->param($name);
  }
  return $value;
}

  # max rows to show
  my $show_max = 100;
  # CGI
  my $cgi = CGI->new;
  # read input
  my $address = val_post('address', '');
  # trim input
  $address =~ s/^\s+|\s+$//go;
  # page name
  my $page = $1 if __FILE__ =~ /([^\/\\]+)$/o;
  # HTML header
  $page =
    "<html>".
    "<head>".
    "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">".
    "<title>Address search</title>".
    "<style>".
    "table,td,th{border:1px solid black;}".
    "table{border:0;border-collapse:collapse;}".
    "td,th{padding:3pt;}".
    "</style>".
    "</head>".
    "<body><center>\n".
    "<form method=\"POST\" action=\"".encode_entities($page)."\">".
    "<input type=\"text\" name=\"address\" value=\"".encode_entities($address)."\" autofocus>&nbsp;".
    "<input type=\"submit\" value=\"search\">".
    "</form>\n";
  # non-empty input
  if ($address) {
    # connect to database
    my $db = ClassDBC->new(sql_get_base(), sql_get_user(), sql_get_pass());
    if ($db) {
      # row_number for log with the same time to be shown in the right order
      my $sql =
        "SELECT (\@row_number:=\@row_number + 1) AS num,created,str ".
        "FROM log, (SELECT \@row_number:=0) AS t WHERE int_id IN ".
        "(SELECT a.int_id FROM log AS a LEFT OUTER JOIN message AS b ON ".
        "a.int_id = b.int_id WHERE a.address = LOWER(?) AND b.status = 0 ".
        "GROUP BY a.int_id) ORDER BY int_id,created DESC,num DESC LIMIT ?";
      my @list = $db->sql_exec($sql, $address, $show_max + 1);
      # got any results
      if (scalar @list) {
        $page .= "<table><tr><th>#</th><th>date time</th><th>log record</th></tr>\n";
        # more than max
        if ((scalar @list) > $show_max) {
          $page .= "<tr><th colspan=\"3\" style=\"background-color:lightgrey;\">Too much rows - first $show_max shown.</th></tr>\n";
          # drop last row
          pop(@list);
        }
        my $i = 0;
        while (scalar @list) {
          # in reverse order
          my $row = pop(@list);
          $i++;
          $page .=
            "<tr>".
            "<th>$i</th>".
            "<td>".encode_entities($row->{created})."</td>".
            "<td>".encode_entities($row->{str})."</td>".
            "</tr>\n";
        }
        $page .= "</table>\n";
      } else {
        $page .= "<p>No matching records found.</p>\n";
      }
    } else {
      $page .= "<p><b>Error: database connection failed.</b></p>\n";
    }
  }
  # HTML footer
  $page .= "</center></body></html>\n";
  # output page with header
  print $cgi->header(
    -type => 'text/html',
    -charset => 'utf-8'
  ).$page;
