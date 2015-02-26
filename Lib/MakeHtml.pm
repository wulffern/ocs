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


use Getopt::Long;

{ package MakeHtml;
  use base 'Object';
  use Data::Dumper;

  sub initialize{
    my $self = shift;

	$self->addOption("outfile=s","outfile","");
    $self->addOption("param=s","param",".*");
	$self->addOption("fileregex=s","fileregex","");

  }

  sub parse{
    my $self = shift;
    my $file = shift;
    my $name = shift;

    my @lines;
    open(fi,"< $file") or die "Could not open $file";
    my $buffer .= "";
    my $first = 1;
    my @header;
    while (<fi>) {
      #   print $_."\n";

      if ($first) {
        @header = split(/,/);
        chomp(@header);
        $first =0;
      } else {
        @values = split(/,/);
        my $i = 0;
        foreach my $key (@header) {
		  $key =~ s/\s*//ig;
          if (!exists($self->{data}->{$name}->{$key})) {
            my @array;
            $self->{data}->{$name}->{$key} = \@array;
          }
          push(@{$self->{data}->{$name}->{$key}},$values[$i]);
          $i += 1;
        }
      }

    }
    close(fi) or die "Could not close $file";


  }

  sub calc{
    my $self = shift;
    my $arr = shift;

    my $min = 1e32;
    my $max = -1e32;
    my $sum = 0;
    my $typ = 0;
    my $stdev;



    my $count = 0;
    foreach my $v (@{$arr}) {
      $min = $v if $min > $v;
      $max = $v if $max < $v;
      $count += 1;
      $sum += $v;
    }

    return unless $count;
    $typ = $sum/$count;

    my $square = 0;
    foreach my $v (@{$arr}) {
      $square += ($v - $typ)**2;
    }

    $stdev = sqrt($square/$count);

	$min = $self->toEng($min); 
	$max = $self->toEng($max); 
	$typ = $self->toEng($typ); 
	$stdev = $self->toEng($stdev); 

	if($min == $max && $min == $typ){
	  $min = "";
	  $max = "";
	  $stdev = "";
	}

    return ($min,$typ,$max,$stdev);
  }

  sub calcRow{
    my $self = shift;
    my $hash = shift;
    my $name = shift;

    my $regex = $self->option("param");


    my @keys = sort( keys(%{$hash}));
	my $date = "";
    foreach my $key (@keys) {

      $key =~ s/\s*//ig;
	  
	  if($key =~ m/^DATE$/){
		my @dateval = @{$hash->{$key}};
		$date = $dateval[0];
	  }

	  next if $key =~ m/^CORNER$/;
	  next if $key =~ m/^FILE$/;
	  next if $key =~ m/^TEST$/;
	  next if $key =~ m/^DATE$/;
      next unless $key;
      if ($key =~ m/$regex/) {
        $str .= "<tr> $td $key $td";
        my @values = $self->calc($hash->{$key});
		push(@values,$date);
        $self->{table}->{$key}->{$name} = \@values;
      }
    }
  }

  sub toHtml{
    my $self = shift;
	my $header = shift;

	$header =~ s/\.|_/ /ig;

    my $str  = "<html>";
    $str = "<style> ". $self->readLibFile("styles.css")."</style>";

    $str .= "<body><table cellpadding=3 cellspacing=0 class=main_table >";
	my $date = `date`;
	chomp($date);
	$str .= "<tr class=header> <th colspan=7> $header (".$ENV{USER}." $date)";
    $str .= "<tr class=header> <th> Name <th> Corner <th> Min <th> Typical <th> Max <th> Sigma <th> Date\n";
    my $count = 0;
	my @params = sort(keys(%{$self->{table}}));
    foreach my $param (@params) {

	  #- Sort by date
      my @keys = sort{ $self->{table}->{$param}->{$b}->[4] cmp $self->{table}->{$param}->{$a}->[4] } (keys(%{$self->{table}->{$param}}));
	  $str .= "<tr><td colspan=7>\n";
      $str .= " <tr ><td  rowspan=".(scalar(@keys)+1)." style='width:200;'> $param";

      foreach my $key (@keys) {
        my $class = "backL";
        if ($count % 2 == 0) {
          $class = "backD";
        }

        my $td = "<td class=\"${class}\" style=\"text-align:center;\" >";
        my @values = @{$self->{table}->{$param}->{$key}};
        $str .= "<tr>  <td class=\"${class}\" style='width:200;' > $key $td". join(" <br> $td  ",@values)."\n";
      $count +=1;
      }

    }
    $str .= "</table></body></html>";

    return $str;

  }

  sub runMe{
    my $self = shift;

	my $fregex = $self->option("fileregex");
    foreach my $file (@_) {
	  next if $file =~ m/debug/ig;

	  $self->comment("Converting $file\n");
      my ($name) = $file =~m/([^\/]+\.\S+)\..*/ig;
	  $name =~ s/$fregex//ig;
	  $name =~ s/\.|_/ /ig;
      $self->parse($file,$name);
    }

    my @keys = sort(keys(%{$self->{data}}));
    foreach my $key (@keys) {
      $self->calcRow($self->{data}->{$key},$key);
    }

    my $str =  $self->toHtml($fregex);
	$self->writeFile($self->option("outfile"),$str);



  }

}

1;
