#! perl -w

# constructs AppConfig options hash for all configs
# possible future configuration routines
# # # # # # # # # # # # # # # # # # # # # # # # # # #
# was becoming too unwieldy to edit within TQASched.pm
# should now be easier to add/remove/set/get default configs
#
# USAGE:
#	require 'config.pl';
#	TQASched::Config::define_defaults(\$cfg);

# INV: this works, but is it sane?
package Config;

# TRUTHINESS
1;

# one subroutine to define them all
# previously housed in TQASched.pm
sub define_defaults {
	my $cfg_ref = shift;

	my %config_vars = (

		#-------------------------------------------------------------------
		#  server configs
		#-------------------------------------------------------------------
		# script which the server... serves
		server_hosted_script => {
						DEFAULT => 'portal.pl',
						ALIAS => 'hosted_script|target_script|content_script',
		},

   # server auto-start, good to set in conf file once everything is running OK
		server_start => { DEFAULT => 1,
						  ARGS    => '!',
						  ALIAS   => 'start_server|s',
		},
		server_port => { DEFAULT => 8081,
						 ARGS    => '=i',
						 ALIAS   => 'host_port|port|p',
		},
		server_logfile => { DEFAULT => "server.log",
							ALIAS   => 'server_log',
		},

	   #-------------------------------------------------------------------
	   #   daemon configs
	   #-------------------------------------------------------------------
	   # daemon auto-start, good to set in conf file once everythign is running OK
		daemon_start => { DEFAULT => 0,
						  ARGS    => '!',
						  ALIAS   => 'start_daemon|d'
		},

		# periodicity of the daemon loop (seconds to sleep)
		daemon_update_frequency => { DEFAULT => 60,
									 ALIAS   => 'update_freq',
		},

		# daemon logfile path
		daemon_logfile => { DEFAULT => 'daemon.log',
							ALIAS   => 'daemon_log',
		},
		daemon_runonce => { DEFAULT => 0,
							ARGS    => '!',
							ALIAS   => 'runonce',
		},

		#-------------------------------------------------------------------
		#  portal (content gen script) configs
		#-------------------------------------------------------------------
		# portal script's logfile
		portal_logfile => {
			DEFAULT => 'portal.log',
			ALIAS   => 'portal_log',

		},

# path to css stylesheet file for portal gen, hosted statically and only by request!
# all statically hosted files are defined relative to the TQASched/Resources/ directory, where they enjoy living (for now, bwahahaha)
		portal_stylesheet => { DEFAULT => 'styles.css',
							   ALIAS   => 'styles|stylesheet',
		},

# path to jquery codebase (an image of it taken sometime in... Jan 2013) - not in use yet
		portal_jquery => { DEFAULT => 'jquery.js',
						   ALIAS   => 'jquery',
		},

	# path to user created javascript libraries and functions - not in use yet
		portal_user_js => { DEFAULT => 'js.js',
							ALIAS   => 'user_js',
		},

		#-------------------------------------------------------------------
		#  misc. config values
		#-------------------------------------------------------------------
		default_verbosity => { DEFAULT => 1,
							   ARGS    => ':i',
							   ALIAS   => 'verbosity|verbose|v',
		},
		# toggle logging
		default_enable_logging => { DEFAULT => 1,
									ARGS    => '!',
									ALIAS   => 'logging|logging_enabled|l',
		},
		default_log_tz => { DEFAULT => 'local',
							ALIAS   => 'tz|timezone',
		},

		# helpme / manpage from pod
		default_help => { DEFAULT => 0,
						  ARGS    => '!',
						  ALIAS   => 'help|version|usage|h'
		},
		default_config_file => { DEFAULT => "Config/settings.ini",
								 ALIAS   => "cfg_file|conf_file|config_file",
		},
		# toggle dryrun mode = non-destructive test of module load and all db connections
		default_dryrun => { DEFAULT => 0,
							ARGS    => '!',
							ALIAS   => 'dryrun|y',
		},
		default_logfile => { DEFAULT => 'log.txt',
							 ALIAS   => 'log',
		},
		default_enable_warn => { DEFAULT => 1,
								 ALIAS   => 'enable_warn',
		},
	);
	${$cfg_ref}->define( $_ => \%{ $config_vars{$_} } ) for keys %config_vars;

}
