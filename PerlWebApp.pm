#! perl -w

# WebApp framework

# TODO update pod
# TODO test exporter
# TODO switch logging to log4perl
# TODO add basic db handle building framework

# TASK update package name here
# TASK rename module and directory to package name

package PerlWebApp;

use strict;
use feature 'say';
use AppConfig qw(:argcount);
use Pod::Usage qw(pod2usage);
use Exporter 'import';
use constant REGEX_TRUE => qr/^\s*(?:true|(?:t)|(?:y)|yes|(?:1))\s*$/i;

# stuff to export to all subscripts
our @EXPORT = qw(load_conf usage redirect_stderr exec_time @CLI REGEX_TRUE);

# anything used only in a single subscript goes here
our @EXPORT_OK = qw();

# add the :all tag to Exporter
our %EXPORT_TAGS = ( all => [ ( @EXPORT, @EXPORT_OK ) ],
					 min => [qw(redirect_stderr load_conf)] );

# for saving @ARGV values for later consumption
our @CLI = @ARGV;

# require/use bounce
# return if being imported as module rather than run directly - also snarky import messages are fun
if ( my @subscript = caller ) {

	# shut up if this is loaded by the report, you'll screw with the protocol!
	# otherwise - loud and proud
	say
		'imported TQASched module for your very own personal amusement! enjoy, pretty boy.'
		unless $subscript[1] =~ m/portal/;
	return 1;
}

my $package = __PACKAGE__;

# run all the configuration routines
# returns a reference to a ref to an AppConfig
my $cfg = ${ init() };

# end of the line if a basic module load/connection test - dryrun
exit( dryrun(scalar @CLI) ) if $cfg->dryrun;

# do all the various tasks requested in the config file and CLI args, if any
execute_tasks();

1;

#-------------------------------------------------------------------
#  subs
#-------------------------------------------------------------------

# glob all the direct-execution initialization and config routines
# returns ref to the global AppConfig
sub init {

	# the ever-powerful and needlessly vigilant config variable - seriously
	my $cfg = load_conf();

# no verbosity check! too bad i can't unsay what's been say'd, without more effort than it's worth
# send all these annoying remarks to dev/null, or close as we can get in M$
# TODO: neither of these methods actually do anything, despite some trying
	disable_say() unless $cfg->verbose;

	# run in really quiet, super-stealth mode (disable any warnings at all)
	disable_warn() if !$cfg->enable_warn || !$cfg->verbose;

	# user has requested some help. or wants to read the manpage. fine.
	usage() if $cfg->help;

	return \$cfg;
}



# dryrun exit routine
# takes optional exit value
sub dryrun {
	my ( $num_args, $exit_val ) = @_;

	# assume all is well
	$exit_val = 0 unless defined $exit_val;
	my $msg  = '';
	my $type = 'INFO';

	# insert various tests that all is well here
	if ( $num_args > 1 ) {
		$msg
			= "detected possible unconsumed commandline arguments and no longer hungry\n";

		# if it looks like the user is trying to do anything else
		# warn and exit(1)
		$type = 'WARN';
		$exit_val++;
	}
	$msg .= sprintf
		'dryrun completed in %u seconds. run along now little technomancer',
		exec_time();

	write_log( { logfile => $cfg->log,
				 msg     => $msg,
				 type    => $type,
			   }
	);

	# I prefer to return the exit value to the exit routine at toplevel
	# it enforces that the script will exit no matter what if it is a dryrun
	return $exit_val;
}

# somehow redefine the say feature to shut up
sub disable_say { }

# somehow turn off warnings... $SIG{WARN} redefine maybe?
sub disable_warn { }

# do all tasks for this module on direct run
sub execute_tasks {
	say 'executing tasks...';
	server();
}
sub load_conf {
	my ($relative_path) = @_;

	$cfg = AppConfig->new( { CREATE => 1,
							 ERROR  => \&appconfig_error,
							 GLOBAL => { ARGCOUNT => ARGCOUNT_ONE,
										 DEFAULT  => "<undef>",
							 },
						   }
	);
	require 'Config/config.pl';

	# TODO (INV) using Config namespace could be dangerous
	Config::define_defaults( \$cfg );

# first pass at CLI args, mostly checking for config file setting (note - consumes @ARGV)
	$cfg->getopt();

# parse config file for those vivacious variables and their rock steady, dependable values
	$cfg->file( ( defined $relative_path ? "$relative_path/" : '' )
				. $cfg->config_file() );

	# second pass at CLI args, they take precedence over config file
	$cfg->getopt( \@CLI );

	return $cfg;
}

# handle any errors in AppConfig parsing - namely log them
sub appconfig_error {

	# TODO figure out how to make appconfig error log dynamic

	# hacky way to force always writing this log to top-level dir
	# despite the calling script's location
	#	my $top_log = ( __PACKAGE__ ne $package
	#					? $INC{'TQASched.pm'} =~ s!\w+\.pm!!gr
	#					: ''
	#	) . $cfg->log();
	#
	#	write_log( { logfile => $top_log,
	#				 type    => 'WARN',
	#				 msg     => join( "\t", @_ ),
	#			   }
	#	);
}

sub redirect_stderr {
	use IO::Handle;
	my ($error_log) = (@_);
	open my $err_fh, '>>', $error_log;
	STDERR->fdopen( $err_fh, 'a' )
		or warn "failed to pipe errors to logfile:$!\n";
}

# server to be run in another process
# hosts the report webmon
sub server {

	# fork and return process id for shutdown
	my $server_pid;
	unless ( $server_pid = fork ) {

		# let's allow the modules CLI args to transfer down
		exec( '/Server/server.pl', @CLI );
	}
	return $server_pid;
}


# daemon to be run in another process
# polls the AUH and DIS metadata SQL and updates TQASched db
# see server() for detailed daemonization comments
sub daemon {
	my $daemon_pid;
	unless ( $daemon_pid = fork ) {
		exec( './Daemon/daemon.pl', @CLI );
	}
	return $daemon_pid;
}


sub timestamp {
	my @now
		= $cfg->tz() =~ m/(?:GM[T]?|UT[C]?)/i
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
	my %usage      = $usage_href ? %{$usage_href} : ();

	pod2usage(
		{  -input    => 'Docs/usage.pod',
		   -msg      => $usage{msg},
		   -exitval  => $usage{exit_val},
		   -verbose  => $usage{verbosity} || $cfg->verbosity(),
		   -sections => $usage{sections},

		}
	);
}

