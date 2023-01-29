# cfg.pl
# configuration file for bookboot
# this is read by the perl script bookglue.pl
# 
# change the variables below to your liking
# 


# linux kernel commandline

$cmdline = 'video=sa1100 root=/dev/ram0  rw';


# 0 for silent operation, 1 for some more explanation

$verbose = 0;  


# possible values: "auto", "set", "none"
# "auto"  : do memory detection at boot time
# "set"   : set memory config in taglist according to 
# 	     $memsize
# "none"  : none of the above, i.e. no  explicit memory 
# 	    configuration

$memdetect = "auto"; 


# memory size in MB; possible values: 32, 48 and 64
# only relevant if $memdetect equals "set"

$memsize = 32; 


# filenames to be used
# NB: changing these is ok, but 'make' may be confused;
# you may need to run bookglue.pl manually 
$kernel = "zImage";
$initrd = "initrd.gz";
$image = "os.img";

