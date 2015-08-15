#!/usr/bin/perl
######################################################################
##        Copyright (c) 2014 Carsten Wulff Software, Norway
## ###################################################################
## Created       : wulff at 2014-11-21
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

use Data::Dumper;
use Getopt::Long;
use strict;
{ package Extract;

  use base "Object";

  sub initialize{
	my $self = shift;
	
	$self->addOption("outfile=s","outfile","-");
	$self->addOption("delimiter=s","delimiter",",");
  }


  sub parseLine{
	my $self = shift;
    return if m/Parameters:/;
    return if m/^\s*$/;
    return if m/^\s+output\s+value/;
    return if m/error/;
    return if m/wave/;

    if (m/Test:\s+(\S+)/) {
      $self->{current_test} = $1;
      return;
    }

    if (m/Corner\s+(\S+):/) {
      $self->{current_corner} = $1;
      return;
    }

    my ($key,$val) = m/\s+(\S+)\s+(\S+)/;

    next unless $key;

    if (!exists($self->{dataHash}->{$key})) {
      my @array;
      $self->{dataHash}->{$key} = \@array;
      $self->{max}->{$key} = 0;
    }

    my %datarow = ( file => $self->{current_file},
                    test => $self->{current_test},
                    corner => $self->{current_corner},
					date => $self->{date},
                    val => $val);


    push(@{$self->{data}->{$key}},\%datarow);
    $self->{max}->{$key} += 1;

    if ($self->{iMax} < $self->{max}->{$key}) {
      $self->{iMax} = $self->{max}->{$key};
    }
  }

  sub parseFile{
	my $self =shift;
    my $file = shift;

	$self->{current_file} = $file;
	$self->{current_test} = "";
	$self->{current_corner} = "";
	$self->{date} = "";
	my $start = 0;
    open(fi,"< $file") or die "Could not open $file";
    while (<fi>) {

      if (m/UTC\s+(\S+)\s+(\S+)/) {
#		print $1."\n";
		$self->{date} = $1." ".$2;
	  }

      if (m/^\# Process Id:\s+(\S+)/) {
        $self->{pid} = $1;
      }

      if ($start && ! m/\\o/) {
        $start = 0;
      }

      next unless m/\\o/;
      s/\\o//;

      if (m/^\s+Detailed Expression Summary:/) {
        $start = 1;
        next;
      }

      if ($start && m/^\s+Expression Summary:/) {
        $start = 0;
      }


      if ($start) {
         $self->parseLine($_);
      }

    }
    close(fi) or die "Could not close $file";

  }

  sub printCsv{
	my $self = shift;
	my $delimiter = $self->option("delimiter");
	my $outfile = shift;
    open(fo,">$outfile") or die "Could not open $outfile";
    my @keys = keys(%{$self->{dataHash}});
	return unless @keys;
    foreach my $key (@keys) {
      print fo $key."${delimiter}";
    }
    print fo "DATE${delimiter}CORNER${delimiter}TEST${delimiter}FILE\n";

    my $i = 0;

    for (my $i = 0; $i< $self->{iMax};$i +=1 ) {
      my $cTest;
      my $cCorner;
      my $cFile;
	  my $cdate;
      foreach my $key (@keys) {
        my @arr = @{$self->{data}->{$key}};
        next if scalar(@arr) < $i;
        my $row = $arr[$i];
        printf fo "%8e${delimiter}",$row->{val};
        $cTest = $row->{test};
        $cCorner = $row->{corner};
        $cFile = $row->{file};
		$cdate = $row->{date};
      }
      print fo "$cdate${delimiter}$cCorner${delimiter}$cTest${delimiter}\"$cFile\"\n";
    }
    close(fo) or die "Could not close $outfile";

  }

  sub runMe{
    my $self = shift;

    #- Read files from command line or from stdin
    my @files;
    if (scalar(@_) > 0) {
      @files = @_;
    } else {
      my $buffer;
      while (<>) {
        $buffer .= $_;
      }
      @files = split(/\s+/,$buffer);
    }

    if ( ! -d "results") {
      mkdir "results";
    }

    foreach my $file (@files) {
      my $outfile = $file;

      #- Clear data, write one dataset per file
	  $self->comment("Extracting $file");
      $self->{iMax} = 0;
      undef $self->{max};
      undef $self->{dataHash};
	  undef $self->{data};
      $outfile =~ s/^[^\/]+/results/;
      $outfile =~ s/\.ocn\.log/\.csv/;
      $self->parseFile($file);
      $self->printCsv($outfile);
#	        $self->printCsv("-");
    }

	return $self->{pid};

  }


}

1;



