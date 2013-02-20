#! /usr/bin/perl -w
use strict;
use warnings;
###################################################################################
#
#
#
#
#
###################################################################################


#**********************************************************************************
#Input Values
#**********************************************************************************

#Starting and Stopping steps
my $stepstart =  201400;
my $stepstop  =  202500;

#Number of atoms
my $nO   = 64;
my $nH   = 127;

#Shift the Cell in BOHR!
my @shift;
$shift[1] = 6.0;
$shift[2] = -16.0;
$shift[3] = -13.0;

#lattice Coordinates in BOHR!
my @x;
$x[1] = 23.517000;
$x[2] =  0.000000; 
$x[3] =  0.000000;

my @y;
$y[1] =  0.000000;
$y[2] = 23.517000;
$y[3] =  0.000000;

my @z;
$z[1] =  0.000000;
$z[2] =  0.000000;
$z[3] = 23.517000;

#**********************************************************************************
#**********************************************************************************

if ( $#ARGV != 0 ) { 
   print (" \n  ERROR: Position file name needed as command line arugment! \n\n") ;
   exit 1;
}

my $ao=0.52917720859;
my $filename = $ARGV[0];                                                                            
my $nat = $nO + $nH;
my $ncount=1;
my $natom=1;
my $readstep=0;
my $tempfile = `mktemp temp.XXXXXX`;

open INFILE, "<", "$filename" or die " ERROR: Can't Open $filename!!";
open OUTFILE, ">", "$tempfile" or die " ERROR: Can't Open $tempfile!!";

while (<INFILE>) {                                                                                  

   my @temp = split /\s+\n?/, $_;  

   if ( not defined $temp[3]){ 

      $readstep = $temp[1];
      $natom = 1;

      #Exit if the after step stop
      if ($readstep > $stepstop) {
         print "\n\n  ANIMSTEPS $ncount \n\n";
         exit 0;    
      }

      #Print the Header
      if ( $readstep >= $stepstart){

         print_header(\@temp, $readstep, $ncount, $nat, \@x, \@y, \@z);
         $ncount += 1;

      }

   }
   elsif ($readstep >= $stepstart) {

      #Print Atoms
      print_atoms(\@temp, $readstep, $natom, $nO, $nH);

      $natom += 1;

   }

}

print "\n\n  ANIMSTEPS $ncount \n\n";

##################################################################################
# Subroutines
##################################################################################

sub print_header{

   my ($line_ref, $readstep, $ncount, $nat, $xref, $yref, $zref) = @_;
   my @line = @$line_ref;
   my @x = @$xref;
   my @y = @$yref;
   my @z = @$zref;


   printf (" CRYSTAL \n");
   printf (" PRIMVEC    $ncount \n");
   printf (" %15.10f %15.10f %15.10f \n", $ao*$x[1], $ao*$x[2], $ao*$x[3] );
   printf (" %15.10f %15.10f %15.10f \n", $ao*$y[1], $ao*$y[2], $ao*$y[3] );
   printf (" %15.10f %15.10f %15.10f \n", $ao*$z[1], $ao*$z[2], $ao*$z[3] );
   printf (" PRIMCOORD  $ncount \n");
   printf ("       $nat     1 \n");

}


sub print_atoms{

   my ($line_ref, $readstep, $natom, $nO, $nH) = @_;
   my @line = @$line_ref;

   #Shift the coordinates
   $line[1] += $shift[1];
   $line[2] += $shift[2];
   $line[3] += $shift[3];

   #Perdioc Conditions
   $line[1] = $line[1] - nint($line[1]/$x[1])*$x[1];
   $line[2] = $line[2] - nint($line[2]/$y[2])*$y[2];
   $line[3] = $line[3] - nint($line[3]/$z[3])*$z[3];


   if ( $natom <= $nO) {
      printf ("O %13.8f  %13.8f  %13.8f \n", $line[1]*$ao, $line[2]*$ao, $line[3]*$ao);
   }
   else {
      printf ("H %13.8f  %13.8f  %13.8f \n", $line[1]*$ao, $line[2]*$ao, $line[3]*$ao);
   }
}


sub nint {  
   my $x = $_[0]; 
   my $n = int($x);
   if ( $x > 0 ) {    
      if ( $x-$n > 0.5) {      
         return $n+1;
      }
      else{      
         return $n;
      }
   }
   else {    
      if ( $n-$x > 0.5) {      
         return $n-1;
      }
      else {      
         return $n;
      }
   }
}
