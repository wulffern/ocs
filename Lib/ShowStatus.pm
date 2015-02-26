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

{ package ShowStatus;

  use Term::ANSIColor;
  use base "Object";
  use strict;
  use Cwd 'abs_path';

  sub initialize{
	my $self = shift;

    my $help = <<"EOF";

EOF
	$self->{help} = $help;

    $self->addOption("number=i","number","10");
	$self->addOption("path","path","");

  }
  
  sub runMe{
	my $self = shift;
	if(scalar(@_) > 1){
	  foreach my $log(@_){
		$self->printLog($log);
	  }
	}else{
	  my $log = shift;
	  if($log =~ m/\.log/ig){
		$self->printLog($log);
	  }else{
		my $number = $self->option("number");
		my @logs = `ls -1t $log |egrep '\.log'|grep -v cdslck | head -n $number`;
		foreach my $l(@logs){
		  $self->printLog($log."/".$l);
		}
	  }
	 
	}
	
  }

  sub printLog{
	my $self = shift;
	my $log = shift;
	chomp $log;
	my $path;
	my $library;
	my $cell;
	my $view;
	open(fi,"<$log") or die "Could not open $log";
	while(<fi>){

	  if(m/ocnxlProjectDir\(\s*"([^"]+)"\s*\)/ig){
		$path = $1;
	  }
	  if(m/ocnxlTargetCellView\(\s*"([^"]+)"\s+"([^"]+)"\s+"([^"]+)"\s*\)/ig){
		$library = $1;
		$cell = $2;
		$view = $3;
	  }
	}
	close(fi) or die "Could not close $log";

	my $simdir = $path."/".$library."/".$cell."/".$view."/results/data/";
	return unless -d $simdir;
	my ($oceandir) = `ls -1t ${simdir} |sort -rn | head -n 1`;
	chomp($oceandir);
	
	my $results = $simdir.$oceandir;

	return unless -d $results;
	my @files = `find $results -name "spectre.out"`;

	foreach my $file(@files){
	  if($self->option("path")){
		print $file."\n";
		next;
	  }
	  my $line = `tail -n 1 $file`;

	  system("cat $file") if $self->option("verbose");
	  
	  next if $file =~ m/psf\/.*\/psf/ig;
	  my ($count) = $file =~ m/Ocean\.\d+\/(\d+)/ig;
	  my $str = "";
	  if($line =~ m/\(([^\)]+)\),/ig){
		$str = color("red")."".$1."".color("reset");
	  }elsif($line =~ m/completes/){
		$str =  color("green")."  OK  ".color("reset")
	  }else{
		$str =  color("yellow")." INIT ".color("reset")
	  }
	  printf "%-60s %-10s  [ %8s ]\n",$log,$count,$str;

	}


  }

}

1;
