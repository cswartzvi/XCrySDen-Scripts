#! /usr/bin/perl -w


$prod_step=$ARGV[0];
$step = 10.0;
$pos_file= '../Hbonds/OH-2/testing/h2o-64.pos';
$Onum = 64;
$Hnum = 127;
$alat ='12.444660000';


#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

$Nat = $Onum + $Hnum;
$pos=($prod_step/$step-1)*$Nat + ($prod_step/$step-1) + 1;
$xsf_out = './config'.$prod_step.'.xsf';
$ao=0.52917720859;

open INFILE, "<$pos_file" ;
@pos_lines = <INFILE>;
close INFILE;

@xsf_lines = make_xsf_temp($alat, $Nat);

open FNAME, ">$xsf_out";
select FNAME;

$na =1;
foreach $i (0 .. $#xsf_lines) {

   if ($xsf_lines[$i] =~ /POS/){
      foreach $j (0 .. ($Nat - 1) ){

         if($na <= $Onum) {
            @val = split /\s+\n?/, $pos_lines[$pos + $j];
               printf( "O %12.6f %12.6f %12.6f \n", $ao*$val[1], $ao*$val[2], $ao*$val[3]);
         }
         else {
            @val = split /\s+\n?/, $pos_lines[$pos + $j];
            printf( "H %12.6f %12.6f %12.6f \n", $ao*$val[1], $ao*$val[2], $ao*$val[3]);
         }
         $na += 1;
      }
   }
   elsif ($xsf_lines[$i] =~ /NUM/){
      $xsf_lines[$i] =~ s/NUM/$Nat/;
      print "$xsf_lines[$i] \n";
   }
   else
   {
      print "$xsf_lines[$i]\n";
   }
}

select STDIN;
close FNAME;


sub make_xsf_temp {

   my ($length, $total) = @_;
   my @array = undef;

   $array[0] = " CRYSTAL";
   $array[1] = " PRIMVEC";
   $array[2] = " $length    0.000000000    0.000000000";
   $array[3] = " 0.000000000    $length    0.000000000";
   $array[4] = " 0.000000000   0.000000000    $length";
   $array[5] = "  PRIMCOORD";
   $array[6] = "         $total           1";
   $array[7] = "POS";

   return @array;

}
