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
# Script: ReadConf.pl
#         is a part of NS2HTML
#
# Read config variables from ns2html.cfg file.
#
sub ReadConf(){

   # Receiving the variable to proccess
   my $VAR = shift;

   # Openning the ns2html.cfg file
   open CFG," ../etc/ns2html.cfg" or die "Could not open ns2html.cfg file: $!\n";

   while (<CFG>){
      chomp;
      s/"//g; # Removing '"' from line

      # If line starts with comments '#', dont proccess it.
      next if (m/^#/);

      # Find the value and split it into the correct variable
      if (m/$VAR/){
         # Find the corresponding value of VAR
         ($none,$VALUE) = split(/=/,$_);
         goto END;
      }# if
   }# while
   END:
   close(CFG);
   return($VALUE);
}# sub ReadConf
1;
