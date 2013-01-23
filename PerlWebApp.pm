#! perl -w

# WebApp framework

# TODO: use AppConfig - supports inline .ini comments! (Config::Simple does not, turns out)
# try/catch for main execution
# add CLI flags and logic
# finish usage w/ optional pod2usage flags and integrate into code
# use Exporter?
# finish static hosting of various filetypes in subdirs
# make sure everything is updated to PerlWebApp package (changed name of this project several times. Hey, I'm indecisive!)

#TASK: enter new package name here
package PerlWebApp;

use strict;
use Config::Simple;
use Getopt::Std qw(getopt);
use Pod::Usage qw(pod2usage);
use base qw(HTTP::Server::Simple::CGI);
use HTTP::Server::Simple::Static;

use constant REGEX_TRUE => qr/^\s*(?:true|(?:t)|(?:y)|yes|(?:1))\s*$/i;

my $package = __PACKAGE__;

my %cfg = ();

load_conf();
parse_cli();

my $server = $package->new( $cfg{port} );
$server->run();

die "$package server has returned and is no longer running\n";

1;

##############################################################################
#	subs
#
##############################################################################

sub handle_request {
	my ( $self, $cgi ) = @_;

	my $params_string = '';
	for ( $cgi->param ) {
		$params_string .= sprintf( '--%s="%s" ', $_, $cgi->param($_) )
			if defined $cgi->param($_);
	}

	my $path = $cgi->path_info;

	# static serve web directory for css, charts (later, ajax)
	if ( $path =~ m/\.(css|xls|js|ico)/ ) {
		$self->serve_static( $cgi, './web' );
		return;
	}

	if ( $path =~ m/styles\.css/ ) {
		$self->serve_static( $cgi, './css' );
		return;
	}
	elsif ( $path =~ m// ) {

	}

	write_log(
			 { type => 'INFO', msg => "$cgi->remote_addr\t$params_string" } );

	print `perl portal.pl $params_string`;
}

sub parse_cli {
	my %cli_opts = ();
	unless ( getopt( 'th', \%cli_opts ) ) {
		write_log(
				 { type => 'WARN',
				   msg  => "aborting... error(s) parsing CLI arguments: @ARGV"
				 }
		);
		usage();
	}
}

sub load_conf {
	my %conf_file = ();
	Config::Simple->import_from( "$package.conf", \%conf_file )
		or write_log(
		{  type => 'WARN',
		   msg =>
			   "error(s) in loading config file: $package.conf\tall configs will be default values"
		}
		);

	$cfg{port} = $conf_file{'server.port'}
		or write_log(
		{  type => 'WARN',
		   msg =>
			   'no port specified in config file, using default (typically 8080)'
		}
		);

	$cfg{server_logfile} = $conf_file{'server.logfile'} || "$package.log"
		and write_log(
		{  type => 'WARN',
		   msg =>
			   "no server logfile specified in configs, using default: $package.log"
		}
		);

	$cfg{verbosity}      = $conf_file{verbosity}      || 0;
	$cfg{enable_logging} = $conf_file{enable_logging} || 1;
	$cfg{stylesheet}     = $conf_file{stylesheet}     || 'styles.css';

}

sub write_log {
	my $entry_href = shift;

	( warn "Passed non-href value to write_log\n" and return )
		unless ( ref($entry_href) eq 'HASH' );

	my %entry = %{$entry_href};

	open my $log_fh, '>>', $cfg{server_logfile};
	printf $log_fh "[%s]\t[%s]\t%s\t%s\n", timestamp(), $entry{type},
		$entry{msg};
	close $log_fh;
}

sub timestamp {
	my @now
		= $cfg{log_tz} =~ m/(?:GM[T]?|UT[C]?)/i
		? gmtime(time)
		: localtime(time);
	return
		sprintf "%4d-%02d-%02d %02d:%02d:%02d",
		$now[5] + 1900,
		$now[4] + 1,
		@now[ 3, 2, 1, 0 ];
}

sub usage {
	my $usage_href = shift;
	my %usage      = %{$usage_href};

	pod2usage(
		{  -msg      => $usage{msg},
		   -exitval  => $usage{exit_val},
		   -verbose  => $usage{verbosity} || $cfg{verbosity},
		   -sections => $usage{sections},

		}
	);
}

=pod

=head1 NAME

PWebApp - a framework for simple hosted Perl applications

=head1 SYNOPSIS

edit the handler to generate HTML (or any TCP/IP) output desired
usually best to include in another script to make testing easier:
this allows one to leave the server running while editing the content generation script(s) on the fly
 
=head1 DESCRIPTION

this is a basic framework for cobbling together quick and dirty hosted Perl scripts
definitely nothing fancy and probably not best used for anything external
but it gets the job done quickly and easily for most simple applications
	
=head2 METHODS

=over 12

item C<handle_request>

Content generation script should be called here along with any statically hosted files.
Also included is a CGI parameter parser which converts CGI args (POST or GET) into a CLI arg string.
This string can then be passed to content generation scripts and args can be easily parsed using L<Getopt::Long> 

=item C<write_log>

General purpose sub for writing to server log. Useful for debugging based on verbosity level.
Logging must be enabled (which it is by default)
Can be disabled in config file or by reducing verbosity level to filter logging by severity

=head3 Log Entry Flavors:

=over 6

=item [INFO]

Basic reporting. Reserved for usage stats and recording normal operations for monitoring.

=item [WARN]

Reports possible errors in execution or configuration but are (expected to be) recoverable.
Accompanied by a C<warn>ing to STDERR.

=item [ERROR]

Significant execution or configuration errrors are logged under this tag.
Most likely this was logged immediately prior to the C<die>ing or an outright crash.

=back

=item C<timestamp>

Returns a formatted SQL DateTime-style timestamp for writing to server logfile.

=back

=head2 FILES

=over 12

item F<portal.pl>

Default content generation script.
CGI args are passed as long CLI args to this script and run in another process.
Run the server (this module) and then edit this script on the fly to create app.

item F<PWebApp.conf>

Basic .ini config file for setting options.
Nothing is required in this file it is purely for customization purposes.

item F<css/styles.css>

Stylesheet statically hosted for HTML generation portals.
Can change the name in configs but all statically hosted files should be kept
in subdirectories to prevent hosting up cleartext Perl code behind server and 
content gen script.

item F<js/js.js>

Custom application-specific Javascript code goes in this file.
It is always loaded in the F<portal.pl> content generation script.

=over 6

item C<Test_JS>

Test function to ensure that any user added Javascript is interpreted OK.
Of course, the user will be require to make sure any additions actually do what they want =P

=back

item F<js/jquery.js>

L<JQuery library - 1.9.0 | http://code.jquery.com/jquery-1.9.0.js>
Not loaded automatically in F<portal.pl> due to overhead.
Incredibly useful library in more complex applications.

=back

=head1 LICENSE

Copyright 2013 Matt Shockley 

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Matt Shockley aka mshock 
L<mshock|http://github.com/mshock>

=cut
