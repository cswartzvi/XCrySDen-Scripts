#! /usr/bin/perl -w

use File::Basename;
use Term::ReadLine;

print "\n\nCreate a TCL and XSf Script for a Defect System:\n\n";
print "\n";

#Main Read-in Loop
#----------------------------------------------------------------------------------------
while (1) {
   $prod_step= prompt(" Production Step");
   $step = prompt(" Value of iprint");

   $pos_dir = prompt(" Relative Pathname of the Position File Directory");
   $pos_file = check_dir_for_file($pos_dir, '*.pos');

   print"\n";
   $Onum = prompt(" Number of Oxygen Atoms");
   $Hnum = prompt(" Numbe of Hydorgen Atoms");
   $alat = prompt(" Lattice Constant(bohr)");
   print "\n";

   while (3) {
      $defect_mark = prompt(" Defects to be marked (O* index(s) will be read, answer \"n\" if there are no defects)? [y/n]");
      last if ($defect_mark eq 'y' || $defect_mark eq 'n');
      print("\n\n");
   }

   #If defects are marked (and it has defects) loop both the Single and PT index
   #Files (Assuming *99 and *98 respectively)
   #-------------------------------------------------------
   if ($defect_mark eq 'y') {

      $defect_dir_single = prompt( " Relative Pathname of the Singlar Defect file Directory(Assuming fort.99 or fort.199)");
      $defect_file_single = check_dir_for_file($defect_dir_single, '*99');
      print("\n");
      
      $defect_dir_trans = prompt( " Relative Pathname of the Proton Transfer Defect file Directory (Assuming fort.98 or fort.198)");
      $defect_file_trans = check_dir_for_file($defect_dir_trans, '*98');
      print("\n");
      
      #Loop Through the $defect_file_single file to see if the correct
      #configuration is present
      @temp = find_config($defect_file_single, $prod_step);

      if( $temp[0] != 0) {
         $defect_num = 1 ;
         $Ostar1 = $temp[0];
         print("  Ostar1 index: $Ostar1\n");
      }
      else {
         @temp = find_config($defect_file_trans, $prod_step);

         if( $temp[0] != 0 && $temp[1] != 0){
            $defect_num = 2;
            $Ostar1 = $temp[0];
            $Ostar2 = $temp[1]; 
            print("  Ostar1 index: $Ostar1\n");
            print("  Ostar2 index: $Ostar2\n");
         }
         else {
            print("  Defect Note Found! Defect Marking Disabled.\n");
            $defect_mark = 'n';
         }
      }


   }
   #-------------------------------------------------------

   #Value Check in, Repear if needed!
   print("\n\nSet Values:");
   print("\n Production Step:    $prod_step");
   print("\n iprint:             $step");
   print("\n Position File:      $pos_file");
   print("\n Numbe Oxygens:      $Onum");
   print("\n Number Hydrogens:   $Hnum");
   print("\n Lattice Constant:   $alat");
   if ($defect_mark eq 'y') { 
      print("\n Mark defects:       YES");
      print("\n Number of defects:  $defect_num");
      if ($defect_num == 1){
         print("\n Number of defects:  $defect_num");
         print("\n Ostar:              $Ostar1");
      }
      elsif ($defect_num == 2) {
         print("\n Ostar1:             $Ostar1");
         print("\n Ostar2:             $Ostar2");
      }
         
   }
   else {
      print("\n Mark defects:       NO");
      $defect_num = 0;
   }
   print("\n\n");
  
   while(2){
     $check=prompt("Are These Correct?[y/n]"); 
     chomp($check);
     last if ($check eq 'y' || $check eq 'n');
     print("\n\n");
   }

   last if ($check eq 'y');
   print("\n\n");
}
#----------------------------------------------------------------------------------------

print "\n";


#------------------------------------------------------------------------------
# Initial Stuff
#------------------------------------------------------------------------------

my $ao=0.52917720859;
my $Nat = $Onum + $Hnum;
$alat = $alat * $ao;

my $pos=($prod_step/$step-1)*$Nat + ($prod_step/$step-1) + 1;
my $xsf_out = './config'.$prod_step.'.xsf';

#------------------------------------------------------------------------------
# Create the XSF Files
#------------------------------------------------------------------------------
@xsf_lines = make_xsf_temp($alat, $Nat);

open INFILE, "<$pos_file" ;
@pos_lines = <INFILE>;
close INFILE;

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

select STDOUT;
close FNAME;
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# Create TCl Script
#------------------------------------------------------------------------------
@tcl_lines = make_tcl_temp(); 

$tcl_out =  './config'.$prod_step.'.tcl'; 
open FNAME, ">$tcl_out";
select FNAME;

#-------------------------------------------------------------------------------
#NO OH's Xcrysden Script
if ($defect_num ==  0){

   foreach $i ( 0 .. $#tcl_lines ) {
      if ($tcl_lines[$i] =~ /OSTAR1/){
         $tcl_lines[$i] = "  ";
         $tcl_lines[$i+1] = "  ";
      }
      elsif ($tcl_lines[$i] =~ /OSTAR2/){
         $tcl_lines[$i] = "  ";
         $tcl_lines[$i+1] = "  ";
      }
      elsif($tcl_lines[$i] =~ /OUTPUT/){
         $tcl_lines[$i] =~ s/OUTPUT/$xsf_out/;
      }
      print "$tcl_lines[$i]\n";
   }


   print STDOUT ("\n\n Creating .xsf file and .tcl script for configuration: $prod_step\n");
   print STDOUT ("    No Ostar\n\n");
}

#-------------------------------------------------------------------------------
# One OH xcrysden Script
elsif ($defect_num ==  1){

   foreach $i ( 0 .. $#tcl_lines ) {
      if ($tcl_lines[$i] =~ /OSTAR1/){
         $tcl_lines[$i] =~ s/OSTAR1/$Ostar1/;
      }
      elsif ($tcl_lines[$i] =~ /OSTAR2/){
         $tcl_lines[$i] = "  ";
         $tcl_lines[$i+1] = "  ";
      }
      elsif($tcl_lines[$i] =~ /OUTPUT/){
         $tcl_lines[$i] =~ s/OUTPUT/$xsf_out/;
      }
      print "$tcl_lines[$i]\n";
   }

   print STDOUT ("\n\n Creating .xsf file and .tcl script for configuration: $prod_step\n");
   print STDOUT ("    Ostar = $Ostar1\n\n");
}

#-------------------------------------------------------------------------------
#Two OH xcrysden Script
elsif ($defect_num  ==  2){

   foreach $i ( 0 .. $#tcl_lines ) {
      if ($tcl_lines[$i] =~ /OSTAR1/){
         $tcl_lines[$i] =~ s/OSTAR1/$Ostar1/;
      }
      elsif ($tcl_lines[$i] =~ /OSTAR2/){
         $tcl_lines[$i] =~ s/OSTAR2/$Ostar2/;
      }
      elsif($tcl_lines[$i] =~ /OUTPUT/){
         $tcl_lines[$i] =~ s/OUTPUT/$xsf_out/;
      }
      print "$tcl_lines[$i]\n";
   }

   print STDOUT ("\n\n Creating .xsf file and .tcl script for configuration: $prod_step\n");
   print STDOUT ("    Ostar1 = $Ostar1, Ostar2 = $Ostar2\n\n");
}
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

close FNAME;
select STDOUT;

#Launch XCRYSDEN
while (3) {
   $xcry = prompt("\n\n Launch XCRYSDEN? [y/n]");
   last if ($xcry eq 'y' || $xcry eq 'n');
   print ("\n\n");
}

if ($xcry eq 'y'){
   system("xcrysden --script $tcl_out &");
}


######################################################################################################################
# Subroutines
######################################################################################################################

#Takes User prompt and reads in variable
sub prompt {

   #print("@_:");

   my $Term = new Term::ReadLine 'Installer';

   my $val = $Term->readline("@_:");
   #my $val = <STDIN> ;
   chomp($val);

   return $val;
}


#takes a directory, loops through contents in fittign the second parameter's qual
#prompts user to select the file
sub check_dir_for_file{

   my ($dir, $ext) = @_;
   chomp($ext);

   if ($dir eq "") {
      $dir = './';
      print("\n  ----------------------------");
      print("\n  Using Current Directory\n");
   }
   else {
      if ( -d $dir){
         print("\n  ----------------------------");
         print("\n  Using Directory $dir\n");
      }
      else {
         print("\n\n Error: $dir is Not a directory!\n\n");
         exit 2;
      }
   }


   foreach my $file (glob($dir.'/'.$ext)){
      while(2){
         $base_file = basename("$file");
         $check = prompt("  Use File [y/n]-> $base_file");
         last if ($check eq 'y' || $check eq 'n');
         print("\n\n");
      }
      if ($check eq 'y'){
         $correct_file = $file;
         print("  ----------------------------\n");
         return $correct_file
      }
   }

   print("\n\n Error: No more Files of type $ext found in $dir!!\n\n");
   exit 1;


}

#Loop through a file until the config ($num) is found then return the defect
#indexs (could be one or two!!)
sub find_config {

   my ($file, $num) = @_;

   open INFILE, "<$file";
   my @file_lines = <INFILE>; 
   close INFILE;
   
   my @val = undef;

   my @array = (0,0);

   foreach my $i (0 .. $#file_lines) {

      @val = split /\s+\n?/, $file_lines[$i];
      #Test
      if($i == 1){
      }
      if ($val[1] == $num){
         $array[0] = $val[2];
         if (defined($val[3]) ){
              $array[1] = $val[3];
         } 
      }

   }

   return @array;
}

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

sub make_tcl_temp {

   my @array = undef;

   $array[0]  = "scripting::open --xsf OUTPUT";
   $array[1]  = "scripting::lighting On";
   $array[2]  = " ";
   $array[3]  = "scripting::displayMode3D BallStick";
   $array[4]  = "foreach item { atomic-labels crystal-cells unicolor-bonds perspective } {";
   $array[5]  = "scripting::display on \$item";
   $array[6]  = "}";
   $array[7]  = " ";
   $array[8]  = "scripting::zoom     +0.60";
   $array[9]  = "scripting::rotate x +60";
   $array[10] = "scripting::rotate y +20";
   $array[11] = "scripting::rotate z +10";
   $array[12] = " ";
   $array[13] = "scripting::atomicLabels::atomID OSTAR1 -label \"**OH**\" -brightcolor \#aaffaa";
   $array[14] = "wait 500";
   $array[15] = "scripting::atomicLabels::atomID OSTAR2 -label \"**OH**\" -brightcolor \#aaffaa";
   $array[16] = "wait 500";

   return @array;
}
   
