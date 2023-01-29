#!/usr/bin/perl
use strict;
#
# Script to create a bootable OS.IMG image for Malaysian variety of Psion Netbook
# Copyright (C) 2003-2004 Klaasjan van Druten 
# 
# based on:
# proglue.pl (part of proboot, v0.2.2)
# 	Script to create a bootable sys$rom.bin image for Psion 5mx Pro
# 	Copyright 2002 Tony Lindgren 
#

my $version = "Bookboot v 0.20\n";  # max 31 characters!
my $verbose = 0;  # 0 for silent operation, 1 for some more explanation

# these should match with bookboot.S
my $cpy_pars = 256;
my $reg_pars = 436;
my $welcome = 480;


my $memsize = 32; # memory size in MB; possible values: 32, 48 and 64

# size of header/wrapper used by the Netbook boot loader 
my $wrappersize = 0x0100;

my $loadadr = 0xc8000000;
my $kernelpos = 0x08000;
my $taglistpos = 0x02000;
my $taglistdest = 0xc01e8000;
my $initrdspacer=0x10000;
		
my $kernel = "zImage";
my $initrd = "initrd.gz";
my $image = "os.img";
my $bootcode = "bookboot.bin";
my $cmdline = "console=ttySA0 video=sa1100 root=/dev/ram0  rw";

my $kernelsize = -s $kernel;
my $initrdsize = -s $initrd;
my $cmdlinesize = length($cmdline) +1;
if ($cmdlinesize % 4) {
	$cmdlinesize = $cmdlinesize + 4 - ($cmdlinesize % 4);
}
my $var;

my $initrdpos= $kernelpos+$kernelsize+$initrdspacer;
$initrdpos=  $initrdpos - ( $initrdpos % 4096 ) + 4096;

my $sloppysize= $wrappersize+$initrdpos+$initrdsize;
$sloppysize=  $sloppysize - ( $sloppysize % 4096 ) + 4096;

verbprint($version);
verbprint("Creating image file $image\n");
pad_file($image, $wrappersize+$kernelpos, 1);

verbprint("Injecting key\n");
my ($keypos,$key) = malaykey();
inject_to_file($image,$key, $keypos);


if ($kernelsize > 0){
	verbprint("Appending kernel file $kernel\n");
	concat_files($image, $kernel);
}

if ($initrdsize > 0){
	verbprint("Appending initrd file $initrd\n");
	pad_file($image, $initrdpos + $wrappersize - ( -s $image));
	concat_files($image, $initrd);
	pad_file($image, $sloppysize  - ( -s $image));
}

verbprint("Injecting boot code file $bootcode\n");
$var = `cat $bootcode`;
inject_to_file($image,  $var, $wrappersize);
$var =  pack('L',$loadadr+$taglistpos); # taglist start
$var .= pack('L',$loadadr+$taglistpos+ 0x2000); # taglist end
$var .= pack('L',$taglistdest);	#   taglist destination
inject_to_file($image, $var, $wrappersize+$cpy_pars);


$var = pack('L',0x0);   	# r0 = 0
$var .= pack('L',0x40);		# r1 = arch_psion_series7
$var .= pack('L',$taglistdest);	# r2 = taglist position, cf. arlo
$var .= pack('L',0x0);   	# r3-r6 
$var .= pack('L',0x0);   	# r3-r6 
$var .= pack('L',0x0);   	# r3-r6 
$var .= pack('L',0x0);   	# r3-r6 
$var .= pack('L',$loadadr+$kernelpos);   	# jump to kernel
inject_to_file($image, $var, $wrappersize+$reg_pars);
inject_to_file($image, $version, $wrappersize+$welcome);


verbprint("Injecting file size info\n");
inject_to_file($image, pack('L',$sloppysize), 24);
inject_to_file($image, pack('L',$wrappersize), 28);
inject_to_file($image, pack('L', $sloppysize), $wrappersize + 0x90);

verbprint("Injecting linux taglist\n");
my $taglist= build_taglist();
inject_to_file($image, $taglist, $wrappersize+$taglistpos);

verbprint("Done.\n");

# subroutines

sub malaykey(){
	my $keypos= 0x41d4;
	my $key='';
	$key .= pack('L',0xf07c2691);
	$key .= pack('L',0x3157eab3);
	$key .= pack('L',0xd04e82df);
	$key .= pack('L',0xf8010000);
	return ($keypos,$key);
}	
# 
sub build_taglist(){
	my $taglist;
	$taglist  = pack('L', 0x02);        # tag size
	$taglist .= pack('L', 0x54410001);  # ATAG_CORE

	$taglist .= atag_mem(0xc0000000);
	$taglist .= atag_mem(0xc8000000);
	if ($memsize > 32){ $taglist .= atag_mem(0xd0000000) };
	if ($memsize > 48){ $taglist .= atag_mem(0xd8000000) };

	$taglist .= pack('L', $cmdlinesize /4 +2);  # tag size
	$taglist .= pack('L',0x54410009);  	  # ATAG_CMDLINE
	$taglist .= pack("Z$cmdlinesize",$cmdline);

	if ( $initrdsize > 0) {
		$taglist .= pack('L', 0x04);  # tag size
		$taglist .= pack('L', 0x54420005);  # ATAG_INITRD2
		$taglist .= pack('L', $initrdpos+$loadadr);  # start
		$taglist .= pack('L', $initrdsize);  # size
	} 

	$taglist .= pack('L',0x0);  # tag size
	$taglist .= pack('L',0x0);  # ATAG_NONE

	return $taglist;
}

sub atag_mem(){
	my ($loc) = @_;
	my $tag;
	$tag  = pack('L', 0x04);        # tag size
	$tag .= pack('L', 0x54410002);  # ATAG_MEM
	$tag .= pack('L', 0x01000000);  #  16MB block
	$tag .= pack('L', $loc);        # memstart
	return $tag;
}

sub inject_to_file(){
	my ($file,$var,$seek) = @_;
	open(OUT, "+<$file") or die "can't update $file: $!";
	seek(OUT, $seek, 0);
	print OUT $var;
	close OUT;
	verbprint("\tinjected ".length($var)." bytes in $file at location $seek\n");
}

sub append_to_file(){
	my ($file,$var) = @_;
	open(OUT, ">> $file") || die "can't append to $file: $!";
	print OUT $var;
	close OUT;
	verbprint("\tappended ".length($var)." bytes to $file\n");
}


sub concat_files() {
	my($file1, $file2) = @_;
	open OUT, ">>$file1"
		or die "ERROR: Cannot open file ".$file1;
	open IN, "<$file2"
		or die "ERROR: Cannot open file ".$file2;
	while (<IN>) {
		print OUT;
	}
	close (IN);
	close (OUT);
	verbprint("\tappended $file2 to $file1\n");
}

sub pad_file() {
	my($file, $padsize, $overwrite) = @_;
	if ($overwrite gt 0) {
		open OUT, ">$file" or die "ERROR: Cannot open file ".$file;
		verbprint("\tcreating file $file with $padsize bytes\n");
	} else {
		open OUT, ">>$file"  or die "ERROR: Cannot open file ".$file;
		verbprint("\tpadding file $file with $padsize bytes\n");
	}
	for (my $i=0; $i < $padsize; $i++) {
		print OUT "\0";
	}
	close (OUT);
	verbprint("\tsize of $file now ".(-s $file)." bytes\n");
}

sub verbprint() {
        if ($verbose) { print(@_) };
}

