# Sumavi Inc (C) 2010
#####################################################
# imgport will export and import xCAT stateless, statelite, and diskful templates.
# This will make it so that you can easily share your images with others.
# All your images are belong to us!
package xCAT_plugin::imgport;
use strict;
use warnings;
use xCAT::Table;
use xCAT::Schema;
use Data::Dumper;
use XML::Simple;
use xCAT::NodeRange qw/noderange abbreviate_noderange/;
use xCAT::Utils;
use POSIX qw/strftime/;
use Getopt::Long;
use File::Temp;
use File::Copy;
use File::Path;
use Cwd;
my $requestcommand;

1;

#some quick aliases to table/value
my %shortnames = (
                  groups => [qw(nodelist groups)],
                  tags   => [qw(nodelist groups)],
                  mgt    => [qw(nodehm mgt)],
                  #switch => [qw(switch switch)],
                  );

#####################################################
# Return list of commands handled by this plugin
#####################################################
sub handled_commands
{
	return {
		imgexport	=> "imgport",
		imgimport	=> "imgport",
	};
}

#####################################################
# Process the command
#####################################################
sub process_request
{
	#use Getopt::Long;
	Getopt::Long::Configure("bundling");
	#Getopt::Long::Configure("pass_through");
	Getopt::Long::Configure("no_pass_through");

	my $request  = shift;
	my $callback = shift;
	$requestcommand = shift;
	my $command  = $request->{command}->[0];
	my $args     = $request->{arg};

	if ($command eq "imgexport"){
		return xexport($request, $callback);
	}elsif ($command eq "imgimport"){
		return ximport($request, $callback);
	}else{
		print "Error: $command not found in export\n";
		$callback->({error=>["Error: $command not found in this module."],errorcode=>[1]});
		#return (1, "$command not found in sumavinode");
	}
}


# return sthe mount point to the requesting node.
sub xexport { 
	my $request = shift;
	my $callback = shift;
	my %rsp;	# response
	my $help;
	my @extra;

	my $xusage = sub {
		my $ec = shift;
		push@{ $rsp{data} }, "imgexport: Creates a tarball of an existing xCAT image";
		push@{ $rsp{data} }, "Usage: imgexport <image name> [directory] [[--extra <file:dir> ] ... ]";
		if($ec){ $rsp{errorcode} = $ec; }
		$callback->(\%rsp);
	};
	unless(defined($request->{arg})){ $xusage->(1); return; }
	@ARGV = @{ $request->{arg}};
	if($#ARGV eq -1){
		$xusage->(1);
		return;
	}

	GetOptions(
		'h|?|help' => \$help,
		'extra=s' => \@extra
	);

	if($help){
		$xusage->(0);
		return;
	}
	
	# ok, we're done with all that.  Now lets actually start doing some work.
	my $img_name = shift @ARGV;	
	my $dest = shift @ARGV;

	$callback->( {data => ["Exporting $img_name..."]});
	# check if all files are in place
	my $attrs = get_image_info($img_name, $callback, @extra);
	#print Dumper($attrs);

	unless($attrs){
		return 1;
	}	

	# make manifest and tar it up.
	make_bundle($img_name, $dest, $attrs, $callback);
	
}

# verify the image and return the values
sub get_image_info {
	my $imagename = shift;
	my $callback = shift;
	my @extra = @_;
	my $errors = 0;
	
	my $ostab = new xCAT::Table('osimage', -create=>1);
	unless($ostab){
		$callback->(
			{error => ["Unable to open table 'osimage' What's going on here dude?"],errorcode=>1}
		);
		return 0;
	}
	
	(my $attrs) = $ostab->getAttribs({imagename => $imagename}, 'profile', 'provmethod', 'osvers', 'osarch' );
	if (!$attrs) {
		$callback->({error=>["Cannot find image \'$imagename\' from the osimage table."],errorcode=>[1]});
		return 0;
	}

	unless($attrs->{provmethod}){
		$callback->({error=>["The 'provmethod' field is not set for \'$imagename\' in the osimage table."],errorcode=>[1]});
		$errors++;
	}

	unless($attrs->{profile}){
		$callback->({error=>["The 'profile' field is not set for \'$imagename\' in the osimage table."],errorcode=>[1]});
		$errors++;
	}

	unless($attrs->{osvers}){
		$callback->({error=>["The 'osvers' field is not set for \'$imagename\' in the osimage table."],errorcode=>[1]});
		$errors++;
	}

	unless($attrs->{osarch}){
		$callback->({error=>["The 'osarch' field is not set for \'$imagename\' in the osimage table."],errorcode=>[1]});
		$errors++;
	}

	unless($attrs->{provmethod} =~ /install|netboot|statelite/){
		$callback->({error=>["Exporting images with 'provemethod' " . $attrs->{provmethod} . " is not supported. Hint: install, netboot, or statelite"],errorcode=>[1]});
		$errors++;
	}

	if($errors){
		return 0;
	}

	$attrs = get_files($imagename, $callback, $attrs);
	if($#extra > -1){
		my $ex = get_extra($callback, @extra);
		if($ex){ 
			$attrs->{extra} = $ex;
		}
	}

	# if we get nothing back, then we couldn't find the files.  How sad, return nuthin'
	return $attrs;	

}


# returns a hash of files
# extra {
#	  file => dir
#   file => dir
# }

sub get_extra {
	my $callback = shift;
	my @extra = @_;
	my $extra;

	# make sure that the extra is formatted correctly:
	foreach my $e (@extra){
		unless($e =~ /:/){
			$callback->({error=>["Extra argument $e is not formatted correctly and will be ignored.  Hint: </my/file/dir/file:to_install_dir>"],errorcode=>[1]});
			next;
		}
		my ($file , $to_dir) = split(/:/, $e);
		unless( -r $file){
			$callback->({error=>["Can not find Extra file $file.  Argument will be ignored"],errorcode=>[1]});
			next;
		}
		#print "$file => $to_dir";
		push @{ $extra}, { 'src' => $file, 'dest' => $to_dir };
	}	
	return $extra;
}



# well we check to make sure the files exist and then we return them.
sub get_files{
	my $imagename = shift;
	my $errors = 0;
	my $callback = shift;
	my $attrs = shift;  # we'll hopefully get a reference to it and modify this variable.
	my @arr;	 # array of directory search paths
	my $template = '';

	# todo is XCATROOT not going to be /opt/xcat/  in normal situations?  We'll always
	# assume it is for now
	my $xcatroot = "/opt/xcat";

	# get the install root
	my $installroot = xCAT::Utils->getInstallDir();
	unless($installroot){
		$installroot = '/install';
	}

	my $provmethod = $attrs->{provmethod};

	# here's the case for the install.  All we need at first is the 
	# template.  That should do it.
	if($provmethod =~ /install/){
		# we need to get the template for this one!
		@arr = ("$installroot/custom/install", "$xcatroot/share/xcat/install");
		my $template = look_for_file('tmpl', $attrs, @arr);
		unless($template){
			$callback->({error=>["Couldn't find install template for $imagename"],errorcode=>[1]});
			$errors++;
		}else{
			$callback->( {data => ["$template"]});
			$attrs->{template} = $template;
		}
		$attrs->{media} = "required";
	}


	# for stateless I need to save the 
	# ramdisk
	# the kernel
	# the rootimg.gz
	if($provmethod =~ /netboot/){
		@arr = ("$installroot/netboot");

		# look for ramdisk
		my $ramdisk = look_for_file('initrd.gz', $attrs, @arr);
		unless($ramdisk){
			$callback->({error=>["Couldn't find ramdisk (initrd.gz) for  $imagename"],errorcode=>[1]});
			$errors++;
		}else{
			$callback->( {data => ["$ramdisk"]});
			$attrs->{ramdisk} = $ramdisk;
		}

		# look for kernel
		my $kernel = look_for_file('kernel', $attrs, @arr);
		unless($kernel){
			$callback->({error=>["Couldn't find kernel (kernel) for  $imagename"],errorcode=>[1]});
			$errors++;
		}else{
			$callback->( {data => ["$kernel"]});
			$attrs->{kernel} = $kernel;
		}

		# look for rootimg.gz
		my $rootimg = look_for_file('rootimg.gz', $attrs, @arr);
		unless($rootimg){
			$callback->({error=>["Couldn't find rootimg (rootimg.gz) for  $imagename"],errorcode=>[1]});
			$errors++;
		}else{
			$callback->( {data => ["$rootimg"]});
			$attrs->{rootimg} = $rootimg;
		}
	}


		

	if($errors){
		$attrs = 0;
	}
	return $attrs;
}


# argument:
# type of file:  This is usually the suffix of the file, or the file name.
# attributes:  These are the paramaters you got from the osimage table in a hash.
# @dirs:  Some search paths where we'll start looking for them.
# then we just return a string of the full path to where the file is.
# mostly because we just ooze awesomeness.
sub look_for_file {
	my $file = shift;
	my $attrs = shift;
	my @dirs = @_;
	my $r_file = '';
	
	my $profile = $attrs->{profile};
	my $arch = $attrs->{osarch};
	my $distname = $attrs->{osvers};
	my $dd = $distname; # dd is distro directory, or disco dave, whichever you prefer.


	# go through the directories and look for the file.  We hopefully will find it...
	foreach my $d (@dirs){
			# widdle down rhel5.4, rhel5., rhel5, rhel, rhe, rh, r, 
			until(-r "$d/$dd" or not $dd){
				chop($dd);	
			}
			if($distname && $file eq 'tmpl'){		
				# now look for the file name: foo.rhel5.x86_64.tmpl
				(-r "$d/$dd/$profile.$distname.$arch.tmpl") && (return "$d/$dd/$profile.$distname.$arch.tmpl");
				
				# now look for the file name: foo.rhel5.tmpl
				(-r "$d/$dd/$profile.$distname.tmpl") && (return "$d/$dd/$profile.$distname.tmpl");

				# now look for the file name: foo.x86_64.tmpl
				(-r "$d/$dd/$profile.$arch.tmpl") && (return "$d/$dd/$profile.$arch.tmpl");

				# finally, look for the file name: foo.tmpl
				(-r "$d/$dd/$profile.tmpl") && (return "$d/$dd/$profile.tmpl");
			}else{
				# this may find the ramdisk: /install/netboot/
				(-r "$d/$dd/$arch/$profile/$file") && (return "$d/$dd/$arch/$profile/$file");
			}
	}

	# I got nothing man.  Can't find it.  Sorry 'bout that.
	# returning nothing:
	return '';
}


# here's where we make the tarball
sub make_bundle {
	my $imagename = shift;
	my $dest = shift;
	my $attribs = shift;
	my $callback = shift;

	# tar ball is made in local working directory.  Sometimes doing this in /tmp 
	# is bad.  In the case of my development machine, the / filesystem was nearly full.
	# so doing it in cwd is easy and predictable.
	my $dir = getcwd;
	my $ttpath = mkdtemp("$dir/export.$$.XXXXXX");
	my $tpath = "$ttpath/$imagename";
	mkdir("$tpath");
	chmod 0755,$tpath;

	# make manifest.xml file.  So easy!  This is why we like XML.  I didn't like
	# the idea at first though.
	my $xml = new XML::Simple(RootName =>'xcatimage');	
	open(FILE,">$tpath/manifest.xml") or die "Could not open $tpath/manifest.xml";
	print FILE  $xml->XMLout($attribs, noattr => 1, xmldecl => '<?xml version="1.0">');
	#print $xml->XMLout($attribs, noattr => 1, xmldecl => '<?xml version="1.0">');
	close(FILE);


	# these are the only files we copy in.  (unless you have extras)
	for my $a ("kernel", "template", "ramdisk", "rootimg"){
		if($attribs->{$a}){
			copy($attribs->{$a}, $tpath);
		}
	}


	# extra files get copied in the extra directory.
	if($attribs->{extra}){
		mkdir("$tpath/extra");
		chmod 0755,"$tpath/extra";
		foreach(@{ $attribs->{extra} }){
			copy($_->{src}, "$tpath/extra");
		}
	}

	# now get right below all this stuff and tar it up.
	chdir($ttpath);
	unless($dest){ 
		$dest = "$dir/$imagename.tgz";
	}

	# if no absolute path specified put it in the cwd
	unless($dest =~ /^\//){
		$dest = "$dir/$dest";			
	}

	$callback->( {data => ["Compressing $imagename bundle.  Please be patient."]});
	my $rc = system("tar czvf $dest . ");	
	if($rc) {
		$callback->({error=>["Failed to compress archive!  (Maybe there was no space left?)"],errorcode=>[1]});
		return;
	}
	chdir($dir);	
	$rc = system("rm -rf $ttpath");
	if ($rc) {
		$callback->({error=>["Failed to clean up temp space $ttpath"],errorcode=>[1]});
		return;
	}	
}
