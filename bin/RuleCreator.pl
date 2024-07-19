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
# Script: RuleCreator.pl
#         is a part of NS2HTML
#
# Read data from .txt temporary files and create the HTML file
#
require "ReadConf.pl";
sub RuleCreator(){

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

   open HTML,"> $publish_dir/$hostname/$hostname-rules.$ANO$MES$DIA.html";

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
      <FONT SIZE=6 FACE=TIMES><B>Rulebase for $hostname</B></FONT><BR>
      <FONT SIZE=5 FACE=TIMES> <B>Creation:</B> $DIA/$MES/$ANO at $HORA:$MIN:$SEG h</FONT><P>
      <HR>
      <BR>
EOF

   # Selecting the zones from the table
   my $command = "cat ../tmp/rules.tmp | awk -F\";;;\" '{print \$2\"&&&\"\$3}' | sort | uniq";
   open CAT, "$command |";
   
   while (<CAT>) {
   
      # Slicing the lines
      chomp;
      @CAT_ARRAY = split(/&&&/,$_);
      # Gathering info from the table RULES
      my $src_zone = $CAT_ARRAY[0];
      my $dst_zone = $CAT_ARRAY[1];

      print HTML <<EOF;
      <BR>
      <FONT SIZE=2 COLOR=BLACK>From $src_zone To $dst_zone, Total policy: $total</FONT>
      <TABLE BORDER=1>
         <TR>
            <TD ALIGN=MIDDLE WIDTH=20 BGCOLOR=#99CCFF><B>ID</B></TD>
            <TD ALIGN=MIDDLE WIDTH=200 BGCOLOR=#99CCFF><B>Source</B></TD>
            <TD ALIGN=MIDDLE WIDTH=200 BGCOLOR=#99CCFF><B>Destination</B></TD>
            <TD ALIGN=MIDDLE WIDTH=200 BGCOLOR=#99CCFF><B>Service</B></TD>
            <TD ALIGN=MIDDLE WIDTH=80 BGCOLOR=#99CCFF><B>Action</B></TD>
            <TD ALIGN=MIDDLE WIDTH=80 BGCOLOR=#99CCFF><B>Options</B></TD>
         </TR>
         <TR>
EOF

      # Inserting the new data into the RULES table
      open HANDLER," ../tmp/rules.tmp" or die "Could not open ../tmp/rules.tmp. $!\n";
   
      while (<HANDLER>) {
   
         # Slicing the lines
         chomp;
         @RULES_ARRAY = split(/;;;/,$_);
   
         # Gathering info from the table RULES
         my $id = $RULES_ARRAY[0];
         my $src_zone = $RULES_ARRAY[1];
         my $dst_zone = $RULES_ARRAY[2];
         my $src_addr = $RULES_ARRAY[3];
         my $dst_addr = $RULES_ARRAY[4];
         my $svc = $RULES_ARRAY[5];
         my $action = $RULES_ARRAY[6];
         my $nat = $RULES_ARRAY[7];
         my $auth = $RULES_ARRAY[8];
         my $log = $RULES_ARRAY[9];
         my $count = $RULES_ARRAY[10];
         my $filter = $RULES_ARRAY[11];
         my $av = $RULES_ARRAY[12];
         my $status = $RULES_ARRAY[13];

         $src_addr =~ s/ /<BR>/g;
         $dst_addr =~ s/ /<BR>/g;
         $svc =~ s/ /<BR>/g;
      
         # Placing images
         if ($auth == 1){
            $auth = "<IMG SRC=images/user.gif alt='User authentication'>";
         }else{
            $auth = "&nbsp;";
         }
         if ($log == 1){
            $log = "<IMG SRC=images/log.gif alt='Log'>";
         }else{
            $log = "&nbsp;";
         }
         if ($count == 1){
            $count = "<IMG SRC=images/count.gif alt='Count'>";
         }else{
            $count = "&nbsp;";
         }
         if ($filter == 1){
            $filter = "<IMG SRC=images/url_filter.gif alt='URL Filtering'>";
         }else{
            $filter = "&nbsp;";
         }
         if ($av == 1){
            $av = "<IMG SRC=images/av.gif alt='Antivirus'>";
         }else{
            $av = "";
         }

         if ($nat){ $action = "";}
         if ($av) { $action = "";}

         if ($status){ $id = $id."<FONT COLOR=Red>(D)</FONT>";}

         if ("$src_zone&&&$dst_zone" eq $CAT_ARRAY[0]."&&&".$CAT_ARRAY[1]){
         print HTML <<EOF;
         <TD ALIGN=MIDDLE WIDTH=20 BGCOLOR=#CACACA>$id</TD>
         <TD ALIGN=MIDDLE WIDTH=200 BGCOLOR=#F4F4F4><A HREF="$hostname-addr.$ANO$MES$DIA.html">$src_addr</A></TD>
         <TD ALIGN=MIDDLE WIDTH=200 BGCOLOR=#F4F4F4><A HREF="$hostname-addr.$ANO$MES$DIA.html">$dst_addr</A></TD>
         <TD ALIGN=MIDDLE WIDTH=200 BGCOLOR=#F4F4F4><A HREF="$hostname-svc.$ANO$MES$DIA.html">$svc</A></TD>
         <TD ALIGN=MIDDLE WIDTH=80 BGCOLOR=#F4F4F4>$action $nat $av</TD>
         <TD ALIGN=MIDDLE WIDTH=80 BGCOLOR=#F4F4F4>$auth $log $count $filter</TD>
      </TR>
      <TR>
EOF
      }
      }# while rules
      close(HANDLER);
      print HTML "</TABLE>\n";
   }# while zones
   close(CAT);

   print HTML <<EOF;
   </BODY>
   </HTML>
EOF
   close(HTML);
} # sub RuleCreator
1;
