#! perl -w

# front end html generation for PWebApp.pm

# TODO: gut HCUtil logic and make generic for framework
# integrate AppConfig
# create portal specific logfile
# INV: elegant way to add/remove/define passed CGI args?
# AppConfig/Getopt::Long relationship

use strict;
use Getopt::Long;
use IO::Handle;
use Config::Simple;
use lib '..';
# TASK change to package name
use PerlWebApp;

my $test_inputs = 1;

print_proto();
print_header();
if ( $test_inputs ) {
	print_result();
}
else {
	print_error( { no_opts => 1 } );
}
print_form();
print_footer();


sub print_proto {
	print "HTTP/1.0 200 OK\r\n";
	print "Content-type: text/html\n\n";
}

sub print_error {
	my $error = shift;
	print "
	<tr>
		<td>
		<h4 class='error'>
		<p>Wilson: Who's Harvey?<br>
Miss Kelly: A white rabbit, six feet tall.<br>
Wilson: Six feet?<br>
Elwood P. Dowd: Six feet three and a half inches. Now let's stick to the facts.</p><br>You must enter something if you hope to find your <a href='http://www.youtube.com/watch?v=xXVwMsk7JK8' class='youtube'>pooka</a>:
		</h4>
		</td>
	</tr>" if exists $error->{no_opts} && $error->{no_opts} =~ REGEX_TRUE;
}

sub print_footer {
	print "
	</table>
	</body>
</html>
";
}

sub print_header {
	print "
	<html>
	<head>
		<title></title>
		<link type='text/css' rel='stylesheet' href='styles.css' />
	</head>
	<body>
";

}

sub print_result {

}

sub print_form {
	print "
			<form method='POST'>
			</form>";
}
