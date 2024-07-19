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
# Script: SvcCreator.pl
#         is a part of NS2HTML
#
# Read data from .txt temporary files and create the HTML file
#
require "ReadConf.pl";
sub SvcCreator(){

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

   open HTML,"> $publish_dir/$hostname/$hostname-svc.$ANO$MES$DIA.html";

   # Generating the html
   print HTML <<EOF;
   <HTML>
      <HEADER>
	 <TITLE>NS2HTML - Netscreen Config Parser </TITLE>
       <style type="text/css">
     <!--
       BODY
     {
       margin: 0;
       padding: 0;
     }

     BODY, P, DIV, TD, TH, TR, FORM, OL, UL, LI, INPUT, TEXTAREA, SELECT, A
     {
       font-family: Verdana, Tahoma, Arial, Helvetica, sans-serif;
       font-size: 9px;
	 }

     A:hover  {
       color: #3366CC;
	   text-decoration: none;
     }

     A  {
       color: #3366CC;
	   text-decoration: underline;
     }

     .code
     {
	   font-family: Courier, "Courier New", Monospaced, Serif;
     }
     -->
   </style>

   <BODY BGCOLOR=WHITE>
      <FONT SIZE=6 FACE=TIMES><B>Services for $hostname</B></FONT><BR>
      <FONT SIZE=5 FACE=TIMES> <B>Creation:</B> $DIA/$MES/$ANO at $HORA:$MIN:$SEG h</FONT><P>
      <HR>
      <BR>
      <TABLE BORDER=1>
	 <TR>
	    <TD ALIGN=MIDDLE WIDTH=200 BGCOLOR=#99CCFF><B>Name</B></TD>
	    <TD ALIGN=MIDDLE WIDTH=80 BGCOLOR=#99CCFF><B>Protocol</B></TD>
	    <TD ALIGN=MIDDLE WIDTH=200 BGCOLOR=#99CCFF><B>Src Port</B></TD>
	    <TD ALIGN=MIDDLE WIDTH=200 BGCOLOR=#99CCFF><B>Dst Port</B></TD>
	 </TR>
EOF

      # Openning the default services file
      open DEFAULT,"< ../etc/default_services.txt" or die "Couldn't open default_services.txt file. $!\n";

      # Generating the default services table
      while(<DEFAULT>){
	 chomp;
	 @DEFAULT_SERVICES = split(/ +/,$_);
	 #$name = `echo $_ | awk '{print \$1'}`;
	 #chomp($name);
	 $name = $DEFAULT_SERVICES[0];
	 $proto = $DEFAULT_SERVICES[1];
	 ($src_port,$dst_port) = split('/',$DEFAULT_SERVICES[2]);

	 if (! $src_port){ $src_port = "-"};
	 if (! $dst_port){ $dst_port = "-"};
	 #if ($src_port == ""){ $src_port = "-"};
	 #if ($dst_port == ""){ $dst_port = "-"};

	 # Printing the HTML table
	 print HTML <<EOF;
      <TR>
	 <TD ALIGN=MIDDLE WIDTH=200 BGCOLOR=#F4F4F4>$name</TD>
	 <TD ALIGN=MIDDLE WIDTH=80 BGCOLOR=#F4F4F4>$proto</TD>
	 <TD ALIGN=MIDDLE WIDTH=200 BGCOLOR=#F4F4F4>$src_port</TD>
	 <TD ALIGN=MIDDLE WIDTH=200 BGCOLOR=#F4F4F4>$dst_port</TD>
      </TR>
EOF
      }

      # Inserting the new data into the RULES table
      open HANDLER," ../tmp/services.tmp" or die"Could not open ../tmp/services.tmp. $!\n";

      while (<HANDLER>) {

	 # Slicing the lines
	 chomp;
	 @SERVICES_ARRAY = split(/;;;/,$_);

	 # Gathering info from the table RULES
	 my $name = $SERVICES_ARRAY[0];
	 my $proto = $SERVICES_ARRAY[1];
	 my $src_port = $SERVICES_ARRAY[2];
	 my $dst_port = $SERVICES_ARRAY[3];

	 print HTML <<EOF;
      <TR>
	 <TD ALIGN=MIDDLE WIDTH=200 BGCOLOR=#F4F4F4>$name</TD>
	 <TD ALIGN=MIDDLE WIDTH=80 BGCOLOR=#F4F4F4>$proto</TD>
	 <TD ALIGN=MIDDLE WIDTH=200 BGCOLOR=#F4F4F4>$src_port</TD>
	 <TD ALIGN=MIDDLE WIDTH=200 BGCOLOR=#F4F4F4>$dst_port</TD>
      </TR>
EOF
      }# while
      close(HANDLER);

   #
   # Group of Service
   #

   print HTML <<EOF;
   </TABLE>
      <BR><BR><BR>
      <FONT SIZE=6 FACE=TIMES><B>Service Groups for $hostname</B></FONT><BR>
      <FONT SIZE=5 FACE=TIMES> <B>Creation:</B> $DIA/$MES/$ANO at $HORA:$MIN:$SEG h</FONT><P>
      <HR>
      <BR>
      <TABLE BORDER=1>
	 <TR>
	    <TD ALIGN=MIDDLE WIDTH=200 BGCOLOR=#99CCFF><B>Group Name</B></TD>
	    <TD ALIGN=MIDDLE WIDTH=500 BGCOLOR=#99CCFF><B>Group Members</B></TD>
	 </TR>
EOF

   # Selecting the new data into the ADDR_GRP table
   $command = "cat ../tmp/service-grp.tmp | awk -F\";;;\" '{print \$1}' | uniq";
   open CAT,"$command |" or die "Could not open ../tmp/service-grp.tmp on first open. $!\n";

   $counter = 0;
   while (<CAT>) {

      # Slicing the lines
      chomp;
      @CAT_ARRAY = split(/;;;/,$_);

      my $nome_grp = $CAT_ARRAY[0];

      # Selecting the new data into the ADDR_GRP table
      $command_1 = "cat ../tmp/service-grp.tmp | grep $nome_grp | uniq";
      open CAT_1,"$command_1 |" or die "Could not open ../tmp/service-grp.tmp on second open. $!\n";

      chomp($nome_grp);
      print HTML <<EOF;
      <TR>
	 <TD ALIGN=MIDDLE WIDTH=200 BGCOLOR=#F4F4F4>$nome_grp</TD>
	 <TD ALIGN=MIDDLE WIDTH=200 BGCOLOR=#F4F4F4>
EOF

      while (<CAT_1>) {

	 # Slicing the lines
	 chomp;
	 @CAT_1_ARRAY = split(/;;;/,$_);

	 # Gathering info from the table RULES
	 my $membro = $CAT_1_ARRAY[1];
	 if ($membro eq "null"){
	    #do nothing
	 }else{
	    chomp($membro);
	    print HTML $membro."<BR>\n";
	 }
      }# while
      close(CAT_1);
      $counter++;

      print HTML <<EOF;
	 </TD>
      </TR>
EOF
   }# while
   close(CAT);

   if ($counter == 0){
      print HTML "<TD ALIGN=MIDDLE WIDTH=200 BGCOLOR=#F4F4F4> -- </TD>\n";
      print HTML "<TD ALIGN=MIDDLE WIDTH=200 BGCOLOR=#F4F4F4> -- </TD>\n";
   }


   print HTML <<EOF;
   </BODY>
   </HTML>
EOF
   close(HTML);
}# sub SvcCreator
1;
