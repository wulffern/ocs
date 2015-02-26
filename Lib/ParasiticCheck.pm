#!/usr/bin/perl
######################################################################
##        Copyright (c) 2014 Carsten Wulff Software, Norway 
## ###################################################################
## Created       : wulff at 2014-12-3
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

{ package ParasiticCheck;
  use base 'Object';
  use Data::Dumper;

  sub parse{
	my $self = shift;
	my $file = shift;
	my $linematch = shift;
	my $filter = shift;

	my @lines;
	open(fi,"< $file") or die "Could not open $file";
	my $buffer .= "";
	while(<fi>){

	  s/\n//ig;
	  s/^\s*//ig;

	  #- If line matches \ at the end I should accumulate lines, and not parse them
	  if(m/\\\s*$/){
		$skip_line = 1;
	  }

	  #- Remove ending \
	  s/\\\s*$//ig;
	  $buffer .= $_;
	  if($skip_line){
		$skip_line = 0;
		next;
	  }

	  #- Try to match filter
	  if($buffer =~ m/$linematch/){
		if($buffer =~ m/$filter/){
		  push(@lines,$buffer);
		}
	  }
	  $buffer = "";
	}
	close(fi) or die "Could not close $file";
	
	return @lines;
  }

  sub getCaps{
	my $self = shift;
	my $filter = shift;
	my %cap;
	foreach(@_){
	 my ($name,$n1,$n2,$c) = m/(\S+)\s+\((\S+)\s+(\S+)\).*c=([0-9e\-+.]+)/ig;

	 my $tmp;
	 if($n2 =~ m/$filter/){
	   $tmp = $n2;
	   $n2 = $n1;
	   $n1 = $tmp;
	 }
	 if(exists(	 $cap{$n1}{$n2})){
	   	 $cap{$n1}{$n2} += $c;
	 }else{
	   $cap{$n1}{$n2} = $c;
	 }

	 $cap{$n1}{total_cap} += $c;
	}
	return \%cap;
  }

  sub run{
	my $self = shift;
	my $file = shift;
	my $filter = shift;
	my @lines = $self->parse($file,"capacitor",$filter);
	my $cap = $self->getCaps($filter,@lines);
	foreach my $key(keys(%{$cap})){
	  print $key ." => ".$cap->{$key}->{total_cap}."\n";
	}
  }

}

1;
