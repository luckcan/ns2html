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
# Script: AddrCreator.pl
#         is a part of NS2HTML
#
# Read data from .txt temporary files and create the HTML file
#
require "ReadConf.pl";
sub AddrCreator(){

   # Receiving the hostname from ns2html.pl
   my $hostname = shift;
   $hostname =~ s/"//g;

   # Receiving the publish_dir variable from ns2html.pl
   my $publish_dir = shift;
   $publish_dir =~ s/"//g;

   # Date vars
   my $DIA = `date +%d`; chomp $DIA;
   my $MES = `date +%m`;chomp $MES;
   my $ANO = `date +%Y`;chomp $ANO;
   my $HORA = `date +%H`;chomp $HORA;
   my $MIN = `date +%M`;chomp $MIN;
   my $SEG = `date +%S`;chomp $SEG;

   # Reading variable from n2html.cfg
   $publish_dir = &ReadConf("PUBLISH") if (! $publish_dir);
   chomp($publish_dir);

   open HTML,"> $publish_dir/$hostname/$hostname-addr.$ANO$MES$DIA.html" or die "Could not open $publish_dir/$hostname/$hostname-addr.$ANO$MES$DIA.html: $!\n";
   open HANDLER,"../tmp/address.tmp" or die "Could not open ../tmp/address.tmp. $!\n";

   # Generating the html
   print HTML <<EOF;
   <HTML>
      <HEADER>
	 <TITLE>NS2HTML - Netscreen Config Parser </TITLE>
       <style type="text/css">
     <!--
       BODY
     {
     }

     BODY, P, DIV, TD, TH, TR, FORM, OL, UL, LI, INPUT, TEXTAREA, SELECT, A
     {
       font-family: Verdana, Tahoma, Arial, Helvetica, sans-serif;
       font-size: 9px;
       margin: 0;
       padding: 0;
     }

     -->
   </style>

   <BODY BGCOLOR=WHITE>
      <FONT SIZE=6 FACE=TIMES><B>Addresses for $hostname</B></FONT><BR>
      <FONT SIZE=5 FACE=TIMES> <B>Creation:</B> $DIA/$MES/$ANO at $HORA:$MIN:$SEG h</FONT><P>
      <HR>
      <BR>
      <TABLE BORDER=1>
	 <TR>
	    <TD ALIGN=MIDDLE WIDTH=200 BGCOLOR=#99CCFF><B>Name</B></TD>
	    <TD ALIGN=MIDDLE WIDTH=100 BGCOLOR=#99CCFF><B>Zone</B></TD>
	    <TD ALIGN=MIDDLE WIDTH=100 BGCOLOR=#99CCFF><B>IP</B></TD>
	    <TD ALIGN=MIDDLE WIDTH=100 BGCOLOR=#99CCFF><B>Mask</B></TD>
	 </TR>
EOF

      while (<HANDLER>){

	 # Slicing the lines
	 chomp;
	 @ADDR_ARRAY = split(/;;;/,$_);

	 # Gathering info from the table RULES
	 my $nome = $ADDR_ARRAY[0];
	 my $zone = $ADDR_ARRAY[1];
	 my $ip = $ADDR_ARRAY[2];
	 my $mask = $ADDR_ARRAY[3];

	 if ($mask == "" ){ $mask = "--"; }

	 print HTML <<EOF;
      <TR>
	 <TD ALIGN=MIDDLE WIDTH=200 BGCOLOR=#F4F4F4>$nome</TD>
	 <TD ALIGN=MIDDLE WIDTH=200 BGCOLOR=#F4F4F4>$zone</TD>
	 <TD ALIGN=MIDDLE WIDTH=200 BGCOLOR=#F4F4F4>$ip</TD>
	 <TD ALIGN=MIDDLE WIDTH=200 BGCOLOR=#F4F4F4>$mask</TD>
      </TR>
EOF
   }# while
   close(HANDLER);

   #
   # Groups
   #
   print HTML <<EOF;
   </TABLE>
   <BR><BR><BR>

   <FONT SIZE=6 FACE=TIMES><B>Address Groups for $hostname</B></FONT><BR>
   <FONT SIZE=5 FACE=TIMES> <B>Creation:</B> $DIA/$MES/$ANO at $HORA:$MIN:$SEG h</FONT><P>
   <HR>
   <BR>

   <TABLE BORDER=1>
   <TR>
      <TD ALIGN=MIDDLE WIDTH=200 BGCOLOR=#99CCFF><B>Group Name</B></TD>
      <TD ALIGN=MIDDLE WIDTH=200 BGCOLOR=#99CCFF><B>Group Zone</B></TD>
      <TD ALIGN=MIDDLE WIDTH=500 BGCOLOR=#99CCFF><B>Group Members</B></TD>
   </TR>
EOF

   # Selecting the new data into the ADDR_GRP table
   # grupo, membro, zone
   $command = "cat ../tmp/address-grp.tmp | awk -F';;;' '{print \$1\";;;\"\$3}' | uniq";
   open CAT,"$command |" or die "Could not open ../tmp/address-grp.tmp. $!\n";

   while (<CAT>) {

      # Slicing the lines
      chomp;
      @CAT_ARRAY = split(/;;;/,$_);

      my $nome_grp = $CAT_ARRAY[0];
      my $zone = $CAT_ARRAY[1];

      print HTML <<EOF;
      <TR>
	 <TD ALIGN=MIDDLE WIDTH=200 BGCOLOR=#F4F4F4>$nome_grp</TD>
	 <TD ALIGN=MIDDLE WIDTH=200 BGCOLOR=#F4F4F4>$zone</TD>
	 <TD ALIGN=MIDDLE WIDTH=200 BGCOLOR=#F4F4F4>
EOF

      # Selecting the new data into the ADDR_GRP table
      open HANDLER," ../tmp/address-grp.tmp" or die "Could not open ../tmp/address-grp.tmp. $!\n";

      while (<HANDLER>) {

	 # Slicing the lines
	 chomp;
	 @ADDRGRP_ARRAY = split(/;;;/,$_);

	 # Gathering info from the table RULES
	 my $membro = $ADDRGRP_ARRAY[1];
	 if ($membro eq "null"){
	    #do nothing
	 }else{
            if ($nome_grp eq $ADDRGRP_ARRAY[0] && $zone eq $ADDRGRP_ARRAY[2]){
               print HTML $membro."<BR>\n";
               $membro = "";
               @ADDRGRP_ARRAY = ();
            }
	 }
      }# while
      close(HANDLER);

   print HTML <<EOF;
	 </TD>
EOF
   }
   close(CAT);
   print HTML <<EOF;
      </TR>
   </TABLE>
   </BODY>
   </HTML>
EOF

   close(HTML);
}# sub AddrCreator
1;
