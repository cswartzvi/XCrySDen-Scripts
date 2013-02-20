#! /bin/bash
######################################################################
#
# This script will loop through all the relevent KS file using config_start
# and config_last and create a tcl script that will then be run with 
# XCRYSDEN. The tcl script will then loop through all the KS files and then
# create a .avi files.  
#
#
# Please Note: a saved XCRYSDEN state file (x_save_orig) must be produced
# but will NOT be alter.
#
# Each KS Orbital should be saved in a directory according to 
# it's configuration number (called *configXXXXX*). More then one 
# KS Orbital per directory is OK, each KS file must be labeled 
# KS_XXX.xsf.
#
######################################################################


#-----------------------------------------------------------
# Inputs
#-----------------------------------------------------------
config_start=100500
config_last=100790
num=256
iprint=10

#XCRYSDEN save stated
x_save_orig=save.xcrysden
#-----------------------------------------------------------

#make temp copy of the x_save_orig
if [ ! -e $x_save_orig ]; then
   echo " ERROR: the XCRYSDEN save file, $x_save_orig, does NOT Exist!"
   exit 7
fi
x_save=`mktemp temp.XXXXX`
cp $x_save_orig $x_save

#Script that will be generated
exe_script=exec_xcrysden_script.tcl

frames=frames
if [ ! -d $frames ]; then
   mkdir $frames
fi

#sed -i 's/\$/\\$/' $x_save
sed -i '/BEGIN: XSF structure data/,/END: XSF structure data/ { /BEGIN: XSF structure data/!d }' $x_save
sed -i 's/# BEGIN: XSF structure data/::scripting::open --xsf $files($n)/g' $x_save
sed -i 's/array set xcMisc/#array set xcMisc/g' $x_save

#Create the opening header
cat > $exe_script <<EOF
#!/usr/bin/tclsh
global env
set dir [file join "."] 

EOF

num_raw=0
config=$config_start
while (($config <= $config_last)) 
do 

   num_raw=$((num_raw + 1))

   #Check to be sure that the directoies exist!
   if [ ! -d ./config$config ]; then
      echo " ERROR: ./config$config Does Not Exist. Please Check Input!!"
      exit
   fi

   #Check to be sure that the file exists
   if [ ! -e ./config$config/KS_$num.xsf ]; then
      echo " ERROR: ./config$config/KS_$num.xsf Does Not Exist. Please check KS Files!!"   
   fi

   echo "set files($num_raw) [file join \$dir config$config KS_$num.xsf]" >> $exe_script

   config=$(($config + $iprint))
done
echo " " >> $exe_script
echo "set end $num_raw" >> $exe_script
echo " " >> $exe_script

cat >> $exe_script <<EOF
scripting::makeMovie::init \\
        -movieformat avi   \\
        -dir         pwd   \\
        -frameformat ppm   \\
        -firstframe  5     \\
        -lastframe   5     \\
        -delay       70

scripting::makeMovie::begin


set n 1
while {1} {
EOF

cat $x_save >> $exe_script

cat >> $exe_script <<EOF
# now print the MO
update
scripting::makeMovie::makeFrame


#Go to the next loop
set n [expr "\$n + 1"]
if { \$n > \$end} {break}
}
scripting::makeMovie::end
EOF

xcrysden -s $exe_script
/bin/rm $x_save
