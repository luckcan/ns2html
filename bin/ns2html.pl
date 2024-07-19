#!/usr/bin/perl
##########################################################################
#            NS2HTML - The Netscreen to HTML file converter              #
##########################################################################
#   Copyright (C) by                                                     #
#     - 2007: Rodrigo Pace de Barros <rodrigo.pace.barros@gmail.com>     #
#                                                                        #
#   This program is free software; you can redistribute it and/or modify #
#   it under the terms of the GNU General Public License as published by #
#   the Free Software Foundation; either version 2 of the License, or    #
#   (at your option) any later version.                                  #
#                                                                        #
##########################################################################
#
# Script: ns2html.pl
#
# Converts the netscreen firewall cfg file to an HTML based rulebase
#
# Importing Modules
use Getopt::Std;
getopts('p:f:h');  # -h: help; -f: rulebase file

# Importing local Perl subs
require "RuleCreator.pl";
require "AddrCreator.pl";
require "SvcCreator.pl";
require "ReadConf.pl";

# Local Vars
my @SRC_ADDRESSES = [];
my @DST_ADDRESSES = [];
my @SRC_ZONE = [];
my @DST_ZONE = [];
my @POLICY = [];
my @SERVICE = [];
my @ADDRESS = [];
my @GRP_ADDR = [];
my @TEMP = [];
my $oldh = $~;
my $hostname = "";
my $vsys_name = "";
my $POL_CONTROL = 0;
my $Line = "";
my $conf_file = $opt_f;
my $soma = 0;
my $Next_Rule = "";
my $Actual_Rule = "";
my $publish_dir = "";
my $number_of_policies = "";
my $ACTION = "";
my $USENAT = "";
my $USEAUTH = "";
my $USELOG = "";
my $USEFILTER = "";
my $DISABLE = "";
my $ANTI_VIRUS = "";
my @SRC_ADDRESSES = ();
my @DST_ADDRESSES = ();
my @SERVICES = ();


if ($conf_file){
   open CFG,"<$conf_file"  or die "Could not open $conf_file file: $!\n";

   # Getting the number of policies from rulebase file
   $number_of_policies = `cat $conf_file | sed -e '/^set policy/!d' -e '/from/!d' | wc -l`;
   chomp $number_of_policies;
}else{
   &usage;
}

if ($opt_h){
   &usage;
}

# Overriding PUBLISH variable from ../etc/ns2html.cfg file
if ($opt_p){
   $publish_dir = $opt_p;
}

# Working with the Netscreen config file
while (<CFG>){
   chomp;

   # Defining the device's infos
   if ($_ =~ /set hostname/ && $hostname == ""){ 
      @TEMP = split(/ /,$_); 
      $hostname = $TEMP[2];
   }# if

   if ($_ =~ /set vsys[^-]/ && $hostname == ""){
      @TEMP = split(/ /,$_);
      $vsys_name = $TEMP[2];
   }

   # Generating the results
   if ($POL_CONTROL > 0 && $_ =~ m/^exit$/){
      &insert_pol();
      $POL_CONTROL--;
      $number_of_policies--;
      goto DOWN;
   }
   if ($POL_CONTROL > 0 && $number_of_policies >= 0 && $_ =~ m/set policy id/ && $_ =~ m/from/){
      &insert_pol();
      $POL_CONTROL--;
      $number_of_policies--;
   }

   DOWN:

   # Defining the policies
   if ($_ =~ /set policy id/ && $_ =~ /from/){

      if ($_ =~ /Dial-Up VPN/){
         $_ =~ s/Dial-Up VPN/Dial-Up-VPN/;
      }# if
      if ($_ =~ /tunnel vpn/){
         $_ =~ s/tunnel vpn/tunnel-vpn/;
      }# if

      # Splitting the line
      @POLICY = &proc_line($_);

      # Just a control variable...
      $POL_CONTROL++;

      # Cleanning the variables
      $ACTION = "";
      $USENAT = "";
      $USEAUTH = "";
      $USELOG = "";
      $USEFILTER = "";
      $DISABLE = "";
      $ANTI_VIRUS = "";
      @SRC_ADDRESSES = ();
      @DST_ADDRESSES = ();
      @SERVICES = ();

      if ($_ =~ /set policy id/ && $_ =~ /name/){
         $NAME = 2;
      }else{
         $NAME = 0;
      }# if

      $POLICY[5+$NAME] =~ s/"//g;
      $POLICY[7+$NAME] =~ s/"//g;
      $src_zone = $POLICY[5+$NAME];
      $dst_zone = $POLICY[7+$NAME];

      # Rebuild the policy hash
      $id = $POLICY[3];
      $POLICY[9+$NAME] =~ s/"//g; # destination address(es)
      $POLICY[10+$NAME] =~ s/"//g; # service
      $POLICY[11+$NAME] =~ s/"//g; # option

      push @SRC_ADDRESSES,$POLICY[8+$NAME];
      push @DST_ADDRESSES,$POLICY[9+$NAME];
      push @SERVICES,$POLICY[10+$NAME];

      @POLICY = ();
      # Defining the actions (permit, deny, auth, nat hide)
      if ($_ =~ m/permit/i){ $ACTION = "<IMG SRC=images/allow.gif alt=Permit>";}
      if ($_ =~ m/tunnel-vpn/i){ $ACTION = "<IMG SRC=images/allow.gif alt=VPNAuth>";}
      if ($_ =~ m/deny/i){ $ACTION = "<IMG SRC=images/deny.gif alt=Drop>";}
      if ($_ =~ m/nat src dip-id/i){ $USENAT = "<IMG SRC=images/allow_blue.gif alt=DIP>";}
      if ($_ =~ m/auth server/i){ $USEAUTH = "<IMG SRC=images/user.gif alt=UserAuth>";}
      if ($_ =~ m/log/i){ $USELOG = "<IMG SRC=images/log.gif alt=Log>";}
      if ($_ =~ m/url-filter/i){ $USEFILTER = "<IMG SRC=images/url_filter.gif alt=Filter>";}
      if (! $USELOG && ! $USEAUTH && ! $USEFILTER && ! $ANTI_VIRUS) { $USELOG = ""; $USEAUTH = ""; $USEFILTER = ""; $ANTI_VIRUS = ""; }

   }else{
      @POLICY = split(/ /,$_);
      $POLICY[2] =~ s/"//g;
      chomp $POLICY[2];

      if ($_ =~ /set src-address/){ 
         push @SRC_ADDRESSES,$POLICY[2];
      }# if
      if ($_ =~ /set dst-address/){ 
         push @DST_ADDRESSES,$POLICY[2];
       }# if
      if ($_ =~ /set service/){ 
         push @SERVICES,$POLICY[2];
      }# if
      if ($_ =~ "set policy" && $_ =~ "av"){
         $ANTI_VIRUS = "1";
      }# if
      if ($_ =~ "set policy" && $_ =~ "disable"){
         $DISABLE = "1";
      }# if
   }# if

   # Defining the services
   if ($_ =~ /set service/ && $_ =~ /protocol/){
      @SERVICE = split(/ /,$_);
      $SERVICE[2] =~ s/"//g; # Removing the "

      my $nome_svc = $SERVICE[2];
      my $proto = $SERVICE[4];
      my $src_port = $SERVICE[6];
      my $dst_port = $SERVICE[8];

      # Opening a temporary file
      open HANDLER,">> ../tmp/services.tmp" or die "Could not open ../tmp/services.tmp file: $!\n";

      # Inserting the new data into the table SERVICES
      $TMP_SERVICES = "$nome_svc;;;$proto;;;$src_port;;;$dst_port\n";

      # Writing to the temp file
      print HANDLER $TMP_SERVICES;
      close(HANDLER);
   }# if

   # Defining the addresses
   if ($_ =~ /set address/ || $_ =~ /set interface/){
      @ADDRESS = split(/ /,$_);
      $ADDRESS[2] =~ s/"//g; # Removing the "
      $ADDRESS[3] =~ s/"//g; # Removing the "
      $ADDRESS[10] =~ s/"//g; # Removing the "

      # Capturing the addresses
      if ($_ =~ /set address/){
         my $zone = $ADDRESS[2];
         my $address = $ADDRESS[3];
         my $ip = $ADDRESS[4];
         my $mask = $ADDRESS[5];

         # Creating the line to be writted into the tmp file 
         $TMP_ADDR = "$address;;;$zone;;;$ip;;;$mask\n";
      }# if

      if ($_ =~ /set interface/ && $_ =~ /mip/){
         $address = "MIP(".$ADDRESS[4].")";
         $zone = "Global";
         $ip = $ADDRESS[6]."/32";
         chop($ADDRESS[6]);
         $mask = $ADDRESS[8];

         # Creating the line to be writted into the tmp file
         $TMP_ADDR = "$address;;;$zone;;;$ip;;;$mask\n";
      }# if

      # Opening a temporary file
      open HANDLER,">> ../tmp/address.tmp" or die "Could not open ../tmp/address.tmp file: $!\n";
 
      # Writing to the temp file
      print HANDLER $TMP_ADDR if ($TMP_ADDR);
      close(HANDLER);

   }# if

   # Defining the addresses groups
   if ($_ =~ /set group address/){
      chop($_);
      @GRP_ADDR = split(/ /,$_);
      $GRP_ADDR[3] =~ s/"//g; # Removing the "
      $GRP_ADDR[4] =~ s/"//g; # Removing the "
      $GRP_ADDR[6] =~ s/"//g; # Removing the "

      my $zone_grp = $GRP_ADDR[3]; 
      my $nome_grp = $GRP_ADDR[4]; 
      my $membro = $GRP_ADDR[6]; 
      if (! $membro){ $membro = "null"; }

      if ($membro){

         # Opening a temporary file
         open HANDLER,">> ../tmp/address-grp.tmp" or die "Could not open ../tmp/address-grp.tmp file: $!\n";

         # Creating the line to be writted into the tmp file
         $TMP_ADDRGRP = "$nome_grp;;;$membro;;;$zone_grp\n";

         # Writing to the temp file
         print HANDLER $TMP_ADDRGRP;
         #close($handle);
      }# if
   }# if

   # Defining the service groups
   if ($_ =~ /set group service/){
      @GRP_SVC = split(/ /,$_);
      $GRP_SVC[3] =~ s/"//g; # Removing the "
      $GRP_SVC[5] =~ s/"//g; # Removing the "

      $nome_grp = $GRP_SVC[3];
      $membro = $GRP_SVC[5];

      if ($membro){

         # Opening a temporary file
         open HANDLER,">> ../tmp/service-grp.tmp" or die "Could not open ../tmp/service-grp.tmp file: $!\n";

         # Creating the line to be writted into the tmp file
         $TMP_SVCGRP = "$nome_grp;;;$membro\n";

         # Writing to the temp file
         print HANDLER $TMP_SVCGRP;
         close(HANDLER);
      }# if
   }# if
}# while
# Closing the netscreen config file
close(CFG);

# Defining hostname
$hostname =~ s/\r//g;
$vsys_name =~ s/\r//g;
$hostname =~ s/"//g;
$vsys_name =~ s/"//g;
$hostname =~ s/[\(]/__/g;  #
$vsys_name =~ s/[\(]/__/g; # Wrapping special characters
$hostname =~ s/[\)]/__/g;  #
$vsys_name =~ s/[\)]/__/g; #

# If there is NO hostname AND NO vsys_name on rulebase
if (! $hostname && ! $vsys_name){
   my $DAY = `date +%d`; chomp($DAY);
   my $MONTH = `date +%m`; chomp($MONTH);
   my $YEAR = `date +%Y`; chomp($YEAR);
   my $HOUR = `date +%H`; chomp($HOUR);
   my $MIN = `date +%M`; chomp($MIN);
   my $SEG = `date +%s`; chomp($SEG);
   $hostname = "NoHostname_$DAY$MONTH$YEAR-$HOUR$MIN$SEG";
}

# If there are no hostname, use vsys_name instead
if (! $hostname) { $hostname = $vsys_name; }

# Reading variable from n2html.cfg
$publish_dir = &ReadConf("PUBLISH") if (! $publish_dir);
chomp($publish_dir);

# Creating the directories needed
system("mkdir -p $publish_dir/$hostname");
system("cp -pr ../html/images $publish_dir/$hostname/");
&RuleCreator($hostname,$publish_dir);
&AddrCreator($hostname,$publish_dir);
&SvcCreator($hostname,$publish_dir);
system("rm -rf ../tmp/*.tmp");

########
# SUBs #
########

# Sub for insert the policies into the mysql database
sub insert_pol(){

   # Opening a temporary file
   open HANDLER,">> ../tmp/rules.tmp" or die "Could not open ../tmp/rules.tmp file: $!\n";

   $id_antes = $id;
   $src_addr = join(" ",@SRC_ADDRESSES);
   $dst_addr = join(" ",@DST_ADDRESSES);
   $services = join(" ",@SERVICES);

   if ($USEAUTH =~ m/^$/){ $auth = 0;}else{ $auth = 1;}
   if ($USELOG =~ m/^$/){ $log = 0;}else{ $log = 1;}
   if ($COUNT =~ m/^$/){ $count = 0;}else{ $count = 1;}
   if ($USEFILTER =~ m/^$/){ $filter = 0;}else{ $filter = 1;}
   if ($ANTI_VIRUS =~ m/^$/){ $av = 0;}else{ $av = 1;}
   if ($DISABLE =~ m/^$/){ $status = 0;}else{ $status = 1;}

   # Inserting the new data into the RULES table
   $TMP_RULES = "$id_antes;;;$src_zone;;;$dst_zone;;;$src_addr;;;$dst_addr;;;$services;;;$ACTION;;;$USENAT;;;$auth;;;$log;;;$count;;;$filter;;;$av;;;$status\n";

   # Writing to the temp file
   print HANDLER $TMP_RULES;
   close(HANDLER);
}

# Sub usage()
sub usage(){
   print STDOUT "Usage:\n";
   print STDOUT "perl ns2html.pl -h -f <rulebase>\n";
   print STDOUT "\n";
   print STDOUT "   -h: Display this help.\n";
   print STDOUT "   -f: Input rulebase file.\n";
   print STDOUT "   -p: Input your publish directory path.\n";
   exit(0);
}

# Sub proc_line
sub proc_line(){
   my $line_to_process = shift;
   my @LINE_ARRAY = split(/ /,$line_to_process);
   my $multispaced = 0;
   my @POL_ARRAY = ();

   foreach $item (@LINE_ARRAY){
      chomp($item);

      if ($item =~ m/^$/){goto GOTOEND;}
      if ($item =~ /^[^"]/ && $item =~ /[^"]$/ && $multispaced == 0){
         push @POL_ARRAY,$item;
         goto GOTOEND;
      }
      if ($item =~ /^"/ && $item =~ /"$/){
         push @POL_ARRAY,$item;
         goto GOTOEND;
      }
      if ($item =~ /^"/ && $multispaced == 0){
         $multispaced = 1;
         $pre_item = $item;
         goto GOTOEND;
      }#else{
      if ($multispaced == 1 && $item =~ /^[^"]/ && $item =~ /[^"]$/){
         $pre_item = $pre_item."_".$item;
         goto GOTOEND;
      }
      if ($item =~ /"$/ && $multispaced == 1){
         $multispaced = 0;
         $pre_item = $pre_item."_".$item;
         push @POL_ARRAY,$pre_item;
         goto GOTOEND;
      }
      GOTOEND:
   }# foreach

   @LINE_ARRAY = ();
   return(@POL_ARRAY);
}# sub proc_line

