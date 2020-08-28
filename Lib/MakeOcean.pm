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

{ package MakeOcean;

  use base "Object";
  use strict;
  use Cwd 'abs_path';
  use Cwd;
  use Time::Piece; 

  sub initialize{
    my $self = shift;

    my $help = <<"EOF";

EOF
    $self->addOption("define=s","define","");
    $self->addOption("outfile=s","outfile","");
    $self->addOption("corners=s","corners","typical");
    $self->addOption("config=s","config","");
    $self->addOption("cdsdir=s","cdsdir","../../work/".$ENV{USER});
    $self->addOption("run","run",0);

  }

  sub makeOptionString{
    my $self = shift;

    my @definesArray = split(/\s+/,$self->option("define"));
    foreach my $def (@definesArray) {
      $self->{defines}->{$def} = 1;
    }

    #- Create the corner name_
    my $crn = "";
    my $view = $self->option("config");
    if ($view) {
      $crn .= $view."_";
    }

    if (scalar(@definesArray)) {
      $crn .= join("_",@definesArray)."_";
    }

    my @crns = split(/\s+/,$self->option("corners"));

    foreach my $corner (@crns) {
      $self->{corners}->{$corner} = 1;
      $crn .= "$corner";
    }

    return $crn;
  }


  sub runMe{
    my $self = shift;
    my $tb = shift;
    my $dir = "output_".$tb;

    if ( ! -d $dir) {
      mkdir $dir;
    }


    my $crn = $self->makeOptionString;

    #- Read corner files and create corners setup
    my $cornerfile = $self->readCornerFile("../corners.ocn");
    $cornerfile .= $self->readCornerFile("corners.ocn");

    #- Read parameter files
    $self->readParamFile("../ocean.par");
    $self->readParamFile("ocean.par");

    my $cornersetup = "";
    foreach my $c (keys(%{$self->{cornerLookup}})) {
      unless (exists $self->{corners}->{$c}) {
        $cornersetup .= $self->{cornerLookup}->{$c}."\n";
      }
    }

    #- Read test file
    my $test;
    my $isIfdef = 0;
    my $isElse = 0;
    my $buffer = "";
    my $nameIfdef = "";
    open(fi,"<${tb}.ocn") or die "Could not open $tb";
    while (<fi>) {

      if (m/^#ifdef\s+(\S+)\s*$/) {
        $nameIfdef = $1;
        $isIfdef = 1;
        $buffer = "";
        next;
      }

      if ($isIfdef && !$isElse && m/^#else/) {
        if (exists($self->{defines}->{$nameIfdef})) {
          $test .= ";; Define $nameIfdef\n";
          $test .= $buffer;
          $isIfdef = 1;
        } else {
          $isIfdef = 0;
        }
        $isElse = 1;
        $buffer = "";
        next;
      }

      if (($isIfdef || $isElse) && m/^#endif/) {
        if (!$isIfdef && $isElse) {
          $test .= $buffer;
        } elsif ($isIfdef && !$isElse) {
          if (exists($self->{defines}->{$nameIfdef})) {
            $test .= ";; Define $nameIfdef\n";
            $test .= $buffer;
            $buffer = "";
          }
        }
        $isIfdef = 0;
        $isElse = 0;
        next;
      }

      my $str = "";
      my $skipcurrent = 0;

      if (m/^#include\s+(\S+)/) {
        my $incName = $1;
        if ($incName eq "CORNERS") {
          $str .= $cornerfile;
        } elsif ($incName eq "CORNERSETUP") {
          $str.= $cornersetup;
        } elsif (exists($self->{include}->{$incName})) {
          $str .= $self->{include}->{$incName};
        } else {
          $self->comment("#ERROR: Could not find parameter '$incName'");
	  exit;
        }
        $skipcurrent = 1;
      }


      if (m/^#expr\s+(\S+)\s*(=|\s)\s*(.*)/) {
        my $name = $1;
        my $val = $3;
        $self->{expressions}->{$name} = $val;
        $val =~ s/"/\\"/ig;
        $str .= "ocnxlOutputExpr( \"$val\" ?name \"$name\" ?plot t ?save t)\n";
        $skipcurrent = 1;
      }

      if (m/^#sig\s+(.*)/) {
        my $name = $1;
        $str .= "ocnxlOutputSignal( \"$name\" ?save t)\n";
        $skipcurrent = 1;
      }

      if (m/^#term\s+(.*)/) {
        my $name = $1;
        $str .= "ocnxlOutputTerminal( \"$name\" ?save t)\n";
        $skipcurrent = 1;
      }

      my $view = $self->option("config");
      if (m/^ocnxlTargetCellView\(/) {
        s/adexl/ocean_$crn/;

	#- Add SKILL variables
	$str .=  "simulation_name = \"${tb}_${crn}\"\n";
	$str .= "simulation_path = \"".cwd()."\"\n";
      }

      if ($view && m/^design\(/) {
        s/config/config_$view/;
      }

      $str .= $_ unless($skipcurrent);

      if ($isIfdef || $isElse) {
        $buffer .= $str;
        next;
      } else {
        $test .=  $str;
      }
    }


    my $outfile = $self->option("outfile");

	my $t = localtime;
	my $date = $t->ymd("-")."_".$t->hms("-");
    my $filename = $tb.".${crn}.ocn";
    $outfile = $dir."/".$filename unless ($outfile);

    open(fo,">$outfile") or die "Could not open $outfile";
    print fo ";; ".$ENV{USER}." ";
    print fo `date `."\n";
    print fo $test;
    print fo "exit()\n";
    close(fo) or die "Could not close $outfile\n";

    my $run  = $self->option("run");
    my $cdsdir  = $self->option("cdsdir");

    if ($run && $cdsdir) {
      my $path = abs_path($outfile);
      my $log = $path.".${date}.log";

      my $cmd = "cd $cdsdir; ocean -replay $path -log $log";
      if ($self->option("verbose") == 0) {
        $cmd .= " -nograph";
      }

      system($cmd);

      my $pid = $self->parseLog($log);
      my $extract = new Extract();
      $extract->run($log);

    }

  }




  sub readParamFile{
    my $self = shift;
    my $file = shift;
    return "" unless -f $file;
    open(fi,"< $file") or die "Could not open $file";
    my $isSection = 0;
    my $nameSection = "";
    my $buffer;
    while (<fi>) {
      if (m/^\s*#start\s+(\S+)/) {
        $nameSection = $1;
        $isSection = 1;
        $buffer = "";
      }

      if (m/^\s*#end/) {
#	print $buffer."\n";
        $self->{include}->{$nameSection} = $buffer;
        $isSection = 0;
      }

      next if m/^\s*#/;
      next if m/^\s\*/;

      $buffer .= $_ if $isSection;

    }
    close(fi);
  }




  sub readCornerFile{
    my $self = shift;
    my $file = shift;
    return "" unless -f $file;
    open(fi,"< $file");
    my $corners = ";";
    while (<fi>) {
      if (m/ocnxlCorner\(\s+\"(\S+)\"/) {
        my $name = $1;
        $self->{cornerLookup}->{$name} = "ocnxlDisableCorner(\"$name\")\n";
      }
      $corners .= $_;
    }
    close(fi);
    return $corners;
  }


  sub parseLog{
    my $self = shift;
    my $file = shift;
    my $start = 0;
    my $pid = 0;

    open(fi,"< $file") or die "Could not open $file";
    while (<fi>) {

      if (m/^\# Process Id:\s+(\S+)/) {
        $pid = 1;
      }

      if (m/\\e|\\o\s+ERROR/i) {
        print $_;
      }

      if ($start && ! m/\\o/) {
        $start = 0;
      }

      next unless m/\\o/;
      s/\\o//;

      if (m/^\s+Expression Summary:/) {
        $start = 1;
        next;
      }

      if ($start) {
        print $_;
      }

    }
    close(fi) or die "Could not close $file";
    return $pid;
  }


}

1;
