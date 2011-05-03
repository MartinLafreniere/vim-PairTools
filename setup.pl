#!/usr/bin/perl
# setup.pl
# Setup PairTools for Unix
# Copyright (C) 2011 Martin Lafreniere
use strict;
use warnings;

use File::Copy;

my $vimfilespath;
# Choose whether we use default path or the user's
if ($#ARGV > -1)
{
    -d $ARGV[0] || die "ERROR: CANNOT FIND VIMFILES PATH $ARGV[0].\n";
    $vimfilespath = $ARGV[0];
}
else
{
    $vimfilespath = $ENV{'HOME'} . "/.vim";
}

# Copy plugin files into user vimfiles
print "COPYING plugin/pairtools.vim into ${vimfilespath}/plugin\n";
copy("plugin/pairtools.vim", "${vimfilespath}/plugin");

print "COPYING plugin/pairtools.txt into ${vimfilespath}/doc\n";
copy("doc/pairtools.txt", "${vimfilespath}/doc");

# Make sure to install the help file
print "OPENING Vim session to install help file (pairtools.txt)\n";
exec 'vim --servername INSTALL_PAIRTOOLS --cmd "helptags ' . $vimfilespath . '/doc | quit"'

