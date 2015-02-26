######################################################################
##        Copyright (c) 2014 Carsten Wulff Software, Norway
## ###################################################################
## Created       : wulff at 2014-12-4
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
{ package Object;

  use Getopt::Long;
  use Data::Dumper;
  use POSIX;

  sub new {
    my $type = shift;
    my $class = ref $type || $type;
    my $self = {};
    bless $self,$class;
    $self->initialize(@_);

    $self->addOption("verbose+","verbose",0);

    Getopt::Long::Configure('pass_through');
    GetOptions (%{$self->{getopt}})    or die("Error in command line arguments\n");


    return $self;
  }

  sub toEng{
    my $self = shift;
    my $val = shift;
    my %eng = (
               -24 => "y",
               -21 => "z",
               -18 => "a",
               -15 => "f",
               -12 => "p",
               -9 => "n",
               -6 => "u",
               -3 => "m",
               0 => "",
               3 => "k",
               6 => "M",
               9 => "G",
               12 => "T",
               15 => "P",
               18 => "E",
              );

    my $log = 0;
    $log = floor(log(abs($val))/log(10)/3)*3 if ($val != 0);

    if (exists($eng{$log})) {
      $val = $val/10**$log;

      $val = sprintf("%.3f".$eng{$log},$val);
    }
    # print $val."\n";

    return $val;

  }

  sub initialize{

  }

  sub readLibFile{
    my $self = shift;
    my $file = shift;

    my $f = "$FindBin::Bin/Lib/$file";
    return "" unless -f $f;
    return $self->readFile($f);
  }

  sub readFile{
    my $self = shift;
    my $f = shift;
    open(fi,"<$f") or die "Could not open $f";
    my $buffer = "";
    while (<fi>) {
      $buffer .=$_;
    }
    close(fi) or die "Could not close $f";
    return $buffer;
  }


  sub writeFile{
    my $self = shift;
    my $f = shift;
    my $str = shift;
    open(fi,">$f") or die "Could not open $f";
    print fi $str;
    close(fi) or die "Could not close $f";
  }

  sub addOption{
    my ($self,$getopt,$name,$default) =@_;
    my $var = $default;
    $self->{getopt}->{$getopt} = \$var;
    $self->{options}->{$name} = \$var;
  }

  sub option{
    my ($self,$name,$val) = @_;

    if (exists($self->{options}->{$name})) {
      if (defined($val)) {
        $self->{options}->{$name} = \$val;
      }

      my $v = $self->{options}->{$name};
      if (defined($v)) {
        return ${$v};
      }
    } else {
      die "Option $name is unknown \n";
    }
  }

  sub run{
    my $self = shift;
    my @args = @_;


    $self->runMe(@_);

  }


  sub comment{
    my $self = shift;
    my $str = shift;
    if ($self->option("verbose") > 0) {
      print  $str."\n";
    }
  }



}
1;
