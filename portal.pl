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
use constant REGEX_TRUE => qr/^\s*(?:true|(?:t)|(?:y)|yes|(?:1))\s*$/i;

open ERROR, '>>', 'errors.log';
STDERR->fdopen( \*ERROR, 'a' ) or warn "failed to pipe errors to logfile\n";

my $cfg         = new Config::Simple('HCUtil.conf');
my $page_name   = $cfg->param('page_name');
my $header_name = $cfg->param('header_name');

my ( $encode, $decode, $show_commented, $submitted, $strict );
GetOptions( 'encode:s'    => \$encode,
			'decode:s'    => \$decode,
			'comments:s'  => \$show_commented,
			'strict:s'    => \$strict,
			'submitted:s' => \$submitted,
);

print_proto();
print_header();
if ( $encode || $decode ) {
	print_result();
}
else {
	print_error( { no_opts => 1 } ) if $submitted;
}
print_form();
print_footer();

sub load_updt {
	my $updt_file = 'updtcode.h';
	return unless ( -f $updt_file );
	open( my $fh, '<', $updt_file )
		or return;
	my @file = <$fh>;
	close $fh;
	return \@file;
}

sub encode {
	my ($table_name) = @_;
	my $file_aref = load_updt();
	return unless $file_aref;
	$table_name =~ s/\s//g;
	my ( @codes, @names );
	for (@$file_aref) {
		unless ($show_commented) {
			if ( m!^/\*! .. m!^\*/! ) {
				next;
			}
			elsif (m!^//!) {
				next;
			}
		}
		chomp;
		if ( $strict && m/_$table_name\s+(\d+)/i ) {
			push @codes, $1;
		}
		elsif ( !$strict && m/$table_name\w*\s+(\d+)/i ) {
			push @codes, $1;
			m/_(\w*$table_name\w*)/i;
			push @names, $1;
		}

	}
	return ( \@codes, \@names );
}

sub decode {
	my ($header_code) = @_;
	my $file_aref = load_updt();
	return unless $file_aref;
	$header_code =~ s/\s//g;
	my @tables;
	for (@$file_aref) {
		unless ($show_commented) {
			if ( m!^/\*! .. m!^\*/! ) {
				next;
			}
			elsif (m!^//!) {
				next;
			}
		}
		chomp;
		if (    m/#define\s*[A-Z]+?_(\w+)\s+$header_code$/i
			 || m/#define\s*[A-Z]+?_(\w+)\s+$header_code\s+/i )
		{
			push @tables, $1;
		}
	}
	return \@tables;
}

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
		<title>The $page_name HCUtil</title>
		<link type='text/css' rel='stylesheet' href='styles.css' />
	</head>
	<body>
	
		<table>
			<tr>
				<td>
				<h3>
					<a href='http://slider.qai.qaisoftware.com:1337/' class='home'>$header_name Header Code Encoder/Decoder Utility</a>	
				</h3>
				</td>
			</tr>
			<tr>
				<td>
					<h5>
						<script language='javascript' src='http://www.quotedb.com/quote/quote.php?action=random_quote&=&=&'></script>
					</h5>
				</td>
			</tr>
			<tr>
			<td>
			&nbsp
			</td>
			</tr>";

}

sub print_result {
	my $mode = shift;

	my @enabled_options;
	if ($strict) {
		push @enabled_options, 'Strict Matching';
	}
	elsif ($show_commented) {
		push @enabled_options, 'Searching Comments';
	}

	print "<table class='result'>";
	if ($encode) {
		my ( $codes_aref, $names_aref ) = encode($encode);

		if ( scalar @{$codes_aref} ) {
			my $uc_encode = uc $encode;
			print "
			<tr>
				<th colspan='2'>
					<h3>
						<FONT COLOR='672280'>Encoded: $uc_encode</FONT>
					</h3>
				</th>
			</tr>
			";

			my $colspan = '';
			if ( $strict && scalar @$codes_aref ) {
				$colspan = 'colspan="2"';
			}
			my $c = 0;
			for (@$codes_aref) {
				print "
					<tr>
				";
				unless ($strict) {
					print "
						<td>
							<h4>
								<FONT COLOR='3BAD3D'>$names_aref->[$c]</FONT>
							</h4>
						</td>
					";
					$c++;
				}
				print "
						<td $colspan>
							<h4>
								<FONT COLOR='4FDE3C'>$_</FONT>
							</h4>
						</td>
					</tr>	
				";
			}

		}
		else {
			print "<tr>
					<td>
						<h4 class='error'>
								<a href='http://www.youtube.com/watch?v=zQVfOguNWBw' class='youtube'>Robin:</a>\tHoly haberdashery, Batman!
								<br>
								No header codes found for table name:
								<br>
								<p class='bad'>$encode</p>
						</h4>
					</td>
				</tr>";
		}
	}
	if ($decode) {
		my $tables_aref = decode($decode);
		print "
		</table>
		<br>
		<table class='result'>
		" if $encode;
		if ( scalar @{$tables_aref} ) {
			print "
			<tr>
				<th colspan='2'>
					<h3>
						<FONT COLOR='672280'>Decoded: $decode</FONT>
					</h3>
				</th>
			</tr>
			";
			print "
				<tr>
					<td colspan='2'>
						<h4><FONT COLOR='3BAD3D'>$_</FONT></h4>
					</td>
				</tr>	
			" for @$tables_aref;
		}
		else {
			print "<tr>
				<td>
					<h4 class='error'>
							<a href='http://www.youtube.com/watch?v=h7l8rWfLAus' class='youtube'>Obi-Wan:</a>\tThese aren't the droids you're looking for.
							<br>
							No tables found for header code:
							<br>
							<p class='bad'>[$decode]</p>
					</h4>
				</td>
			</tr>";
		}
	}
	print "</table>";
}

sub print_form {
	my $strict_checked = !$submitted
		|| ( $strict && $submitted ) ? 'checked' : '';
	print "
			<form method='POST'>
				<table>
				<tr>
					<td colspan='2'><hr></td>
				</tr>
				<tr>
					<td>
						<fieldset>
						<div>
						<label for='e'><b><FONT COLOR='E0741B'>Table Name</FONT></b></label>
						</div>
						</fieldset>
					</td>
					<td>
						<input type='text' name='encode' id='e'>
					</td>
				</tr>
				<tr>
					<td align='center'>
						<b>and/or&nbsp&nbsp&nbsp&nbsp</b>
					</td>
					<td>
					</td>
				</tr>
				<tr>
					<td>
						<fieldset>
						<div>
						<label for='h'><b><FONT COLOR='E0741B'>Header Code</FONT></b></label>
						</div>
						</fieldset>
					</td>
					<td>
						<input type='text' name='decode' id='h'>		
					</td>
				</tr>
				<tr>
					<td colspan='2'><hr></td>
				</tr>
				<tr>
					<td>
						<fieldset>
						<div>
						<input type='checkbox' name='comments' value='comments' id='c' /><label for='c'><b><h5><FONT COLOR='E0741B'>Search Comments</FONT></h5></b></label>
						</div>
						</fieldset>
					</td>
					<td>
						<fieldset>
						<div>
						<input type='checkbox' name='strict' value='strict' id='s' $strict_checked /><label for='s'><b><h5><FONT COLOR='E0741B'>Strict Matching</FONT></h5></b></label>
						</div>
						</fieldset>
					</td>
				</tr>
				<tr>
					<td colspan='2' class='sub'>
						<input type='submit' name='submitted' value='Make it so.' />
					</td>
				</tr>
				</table>
				
			</form>";
}
