#!/usr/bin/perl
######################################################################
##        Copyright (c) 2014 Carsten Wulff Software, Norway
## ###################################################################
## Created       : wulff at 2014-11-14
## ###################################################################
## Licensed under the Apache License, Version 2.0 (the "License")
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
######################################################################

{ package CopySimDir;

  use Term::ANSIColor;
  use base "Object";
  use strict;
  use Cwd 'abs_path';

  sub initialize{
	my $self = shift;

    my $help = <<"EOF";

EOF
	$self->{help} = $help;

	$self->addOption("force","force","");

  }
  
  sub runMe{
	my $self = shift;
	my $src = shift;
	my $dest = shift;

	die "Could not find directory '$src' " unless -d $src;

	my @files;

	opendir(my $fh, "$src") or die "Could not open directory '$src'";
	while(my $d  = readdir($fh)){

	  next if $d =~ m/^(\.|#|~)/ig;

	  push(@files,$d) if $d =~ m/\.ocn/;
	  push(@files,$d) if $d =~ m/Makefile/;
	}
	closedir($fh) or die "Could not close directory '$src'";

	die "Destination '$dest' already exists! use --force to override" if( -d $dest && !$self->option("force"));

	mkdir $dest unless -d $dest;
	
	foreach my $f(@files){
	  print $f."\n";
	  system(" cp ${src}/$f ${dest}/");
	}
	


	
	
  }
}

1;
