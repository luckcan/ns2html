#!/bin/sh

# sample: PERL5LIB=<ns2html_scripts> perl <ns2html_master_script> -f <Netscreen_config_file> -p <output_dir>
NS2HTML_ROOT=..

PERL5LIB=${NS2HTML_ROOT}/bin perl ${NS2HTML_ROOT}/bin/ns2html.pl -f ${NS2HTML_ROOT}/conf/firewall-test.conf -p ${NS2HTML_ROOT}/html/firewalls
