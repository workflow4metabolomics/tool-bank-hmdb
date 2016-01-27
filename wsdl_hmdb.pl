#!perl

## script  : wsdl_hmdb.pl
#=============================================================================
#                              Included modules and versions
#=============================================================================
## Perl modules
use strict ;
use warnings ;
use Carp qw (cluck croak carp) ;

use Data::Dumper ;
use Getopt::Long ;
use Text::CSV ;
use POSIX ;
use FindBin ; ## Permet de localisez le repertoire du script perl d'origine

## Specific Modules (Home made...)
use lib $FindBin::Bin ;
my $binPath = $FindBin::Bin ;
use lib::hmdb qw( :ALL ) ;
## PFEM Perl Modules
use lib::conf  qw( :ALL ) ;
use lib::csv  qw( :ALL ) ;

## Initialized values
my ( $help ) = undef ;
my ( $mass ) = undef ;
my ( $masses_file, $col_id, $col_mass, $header_choice, $nbline_header ) = ( undef, undef, undef, undef, undef ) ;
my ( $delta, $molecular_species, $out_tab, $out_html, $out_xls ) = ( undef, undef, undef, undef, undef ) ;


#=============================================================================
#                                Manage EXCEPTIONS
#=============================================================================

&GetOptions ( 	"h"					=> \$help,				# HELP
				"mass:s"			=> \$mass,				## option : one masse
				"masses:s"			=> \$masses_file,		## option : path to the input
				"header_choice:s"	=> \$header_choice,		## Presence or not of header in tabular file
				"nblineheader:i"	=> \$nbline_header,		## numbre of header line present in file
				"colfactor:i"		=> \$col_mass,			## Column id for retrieve formula list in tabular file
				"delta:f"			=> \$delta,
				"mode:s"			=> \$molecular_species,	## Molecular species (positive/negative/neutral) 
				"output|o:s"		=> \$out_tab,			## option : path to the ouput (tabular : input+results )
				"view|v:s"			=> \$out_html,			## option : path to the results view (output2)
				"outputxls:s"		=> \$out_xls,			## option : path to the xls-like format output
            ) ;

#=============================================================================
#                                EXCEPTIONS
#=============================================================================
$help and &help ;

#=============================================================================
#                                MAIN SCRIPT
#=============================================================================


## -------------- Conf file ------------------------ :
my ( $CONF ) = ( undef ) ;
foreach my $conf ( <$binPath/*.cfg> ) {
	my $oConf = lib::conf::new() ;
	$CONF = $oConf->as_conf($conf) ;
}

## -------------- HTML template file ------------------------ :
foreach my $html_template ( <$binPath/*.tmpl> ) { $CONF->{'HTML_TEMPLATE'} = $html_template ; }


## --------------- Global parameters ---------------- :
my ( $ids, $masses, $results ) = ( undef, undef, undef ) ;
my ( $complete_rows, $nb_pages_for_html_out ) = ( undef, 1 ) ;
my $search_condition = "Search params : Molecular specie = $molecular_species / delta (mass-to-charge ratio) = $delta" ;

## --------------- retrieve input data -------------- :

## manage only one mass
if ( ( defined $mass ) and ( $mass ne '' ) ) {
	my @masses = split(" ", $mass);
	$masses = \@masses ;
	for (my $i=1 ; $i<=$#masses+1 ; $i++){ push (@$ids,"mz_0".sprintf("%04s", $i ) ); }
} ## END IF
## manage csv file containing list of masses
elsif ( ( defined $masses_file ) and ( $masses_file ne "" ) and ( -e $masses_file ) ) {
	## parse all csv for later : output csv build
	my $ocsv_input  = lib::csv->new() ;
	my $complete_csv = $ocsv_input->get_csv_object( "\t" ) ;
	$complete_rows = $ocsv_input->parse_csv_object($complete_csv, \$masses_file) ;
	
	## parse masses and set ids
	my $ocsv = lib::csv->new() ;
	my $csv = $ocsv->get_csv_object( "\t" ) ;
	if ( ( !defined $nbline_header ) or ( $nbline_header < 0 ) ) { $nbline_header = 0 ;	}
	$masses = $ocsv->get_value_from_csv_multi_header( $csv, $masses_file, $col_mass, $header_choice, $nbline_header ) ; ## retrieve mz values on csv
	my $nbmz = @$masses ;
	for (my $i=1 ; $i<=$nbmz+1 ; $i++){ 	push (@$ids,"mz_0".sprintf("%04s", $i ) ); }
}
else {
	warn "[warning] Input data are missing : none mass or file of masses\n" ;
	&help ;
}

## ---------------- launch queries -------------------- :

if ( ( defined $delta ) and ( $delta > 0 ) and ( defined $molecular_species ) and ( $molecular_species ne '' ) ) {
	## prepare masses list and execute query
	my $oHmdb = lib::hmdb::new() ;
	my $hmdb_pages = undef ;
	
	$results = [] ; # prepare arrays ref
	my $submasses = $oHmdb->extract_sub_mz_lists($masses, $CONF->{HMDB_LIMITS} ) ;
	
	foreach my $mzs ( @{$submasses} ) {
		
		my $result = undef ;
		my ( $hmdb_masses, $nb_masses_to_submit ) = $oHmdb->prepare_multi_masses_query($mzs) ;
		$hmdb_pages = $oHmdb->get_matches_from_hmdb_ua($hmdb_masses, $delta, $molecular_species) ;
		$result = $oHmdb->parse_hmdb_csv_results($hmdb_pages, $mzs) ; ## hash format result
		
		$results = [ @$results, @$result ] ;
	}
	
	## Uses N mz and theirs entries per page (see config file).
	# how many pages you need with your input mz list?
	$nb_pages_for_html_out = ceil( scalar(@{$masses} ) / $CONF->{HTML_ENTRIES_PER_PAGE} )  ;
	
#	print Dumper $results ;
}
else {
	croak "Can't work with HMDB : missing paramaters (list of masses, delta or molecular species)\n" ;
} ## end ELSE

## -------------- Produce HTML/CSV output ------------------ :

if ( ( defined $out_html ) and ( defined $results ) ) {
	my $oHtml = lib::hmdb::new() ;
	my ($tbody_object) = $oHtml->set_html_tbody_object( $nb_pages_for_html_out, $CONF->{HTML_ENTRIES_PER_PAGE} ) ;
	($tbody_object) = $oHtml->add_mz_to_tbody_object($tbody_object, $CONF->{HTML_ENTRIES_PER_PAGE}, $masses, $ids) ;
	($tbody_object) = $oHtml->add_entries_to_tbody_object($tbody_object, $CONF->{HTML_ENTRIES_PER_PAGE}, $masses, $results) ;
	my $output_html = $oHtml->write_html_skel(\$out_html, $tbody_object, $nb_pages_for_html_out, $search_condition, $CONF->{'HTML_TEMPLATE'}, $CONF->{'JS_GALAXY_PATH'}, $CONF->{'CSS_GALAXY_PATH'}) ;
	
} ## END IF
else {
#	croak "Can't create a HTML output for HMDB : no result found or your output file is not defined\n" ;
}

if ( ( defined $out_tab ) and ( defined $results ) ) {
	# produce a csv based on METLIN format
	my $ocsv = lib::hmdb::new() ;
	if (defined $masses_file) {
		my $lm_matrix = undef ;
		if ( ( defined $nbline_header ) and ( $header_choice eq 'yes' ) ) {
#			$lm_matrix = $ocsv->set_lm_matrix_object('hmdb', $masses, $results ) ;
			$lm_matrix = $ocsv->set_hmdb_matrix_object_with_ids('hmdb', $masses, $results ) ;
			$lm_matrix = $ocsv->add_lm_matrix_to_input_matrix($complete_rows, $lm_matrix, $nbline_header-1) ;
		}
		elsif ( ( $header_choice eq 'no' ) ) {
#			$lm_matrix = $ocsv->set_lm_matrix_object(undef, $masses, $results ) ;
			$lm_matrix = $ocsv->set_hmdb_matrix_object_with_ids(undef, $masses, $results ) ;
			$lm_matrix = $ocsv->add_lm_matrix_to_input_matrix($complete_rows, $lm_matrix, 0) ;
		}
		$ocsv->write_csv_skel(\$out_tab, $lm_matrix) ;
	}
	elsif (defined $mass) {
		$ocsv->write_csv_one_mass($masses, $ids, $results, $out_tab) ;
	}
} ## END IF
else {
	warn "Can't create a tabular output for HMDB : no result found or your output file is not defined\n" ;
}

## Write XLS like format
if ( ( defined $out_xls ) and ( defined $results ) ) {
	my $ocsv = lib::hmdb::new() ;
	$ocsv->write_csv_one_mass($masses, $ids, $results, $out_xls) ;
}


#====================================================================================
# Help subroutine called with -h option
# number of arguments : 0
# Argument(s)        :
# Return           : 1
#====================================================================================
sub help {
	print STDERR "
help of wsdl_hmdb

# wsdl_hmdb is a script to query HMDB website using mz and return a list of candidates sent by HMDB based on the ms search tool.
# Input : formula or list of formula
# Author : Franck Giacomoni and Marion Landi
# Email : fgiacomoni\@clermont.inra.fr
# Version : 1.4
# Created : 08/07/2012
# Updated : 21/01/2016
USAGE :		 
		wsdl_hmdb.pl 	-mass [one mass or a string list of exact masses] -delta [mz delta] -mode [molecular species: positive|negative|neutral] -output [output tabular file] -view [output html file] 
		
		or 
		wsdl_hmdb.pl 	-masses [an input file of mzs] -colfactor [col of mz] -header_choice [yes|no] -nblineheader [nb of lines containing file header : 0-n]
						-delta [mz delta] -mode [molecular species: positive|negative|neutral] -output [output tabular file] -view [output html file] 
						
		or 
		wsdl_hmdb.pl 	-h for help
		
		";
	exit(1);
}

## END of script - F Giacomoni 

__END__

=head1 NAME

 wsdl_hmdb.pl -- script to query HMDB website using mz and return a list of candidates sent by HMDB based on the ms search tool.

=head1 USAGE

	wsdl_hmdb.pl 	-mass [one mass or a string list of exact masses] -delta [mz delta] -mode [molecular species: positive|negative|neutral] -output [output tabular file] -view [output html file] 
		
	or 
	wsdl_hmdb.pl 	-masses [an input file of mzs] -colfactor [col of mz] -header_choice [yes|no] -nblineheader [nb of lines containing file header : 0-n]
					-delta [mz delta] -mode [molecular species: positive|negative|neutral] -output [output tabular file] -view [output html file] 

=head1 SYNOPSIS

This script manages batch queries on HMDB server. 

=head1 DESCRIPTION

This main program is a script to query HMDB website using mz and return a list of candidates sent by HMDB based on the ms search tool.

=over 4

=item B<function01>

=item B<function02>

=back

=head1 AUTHOR

Franck Giacomoni E<lt>franck.giacomoni@clermont.inra.frE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 VERSION

version 1.0 : 06 / 06 / 2013

version 1.2 : 27 / 01 / 2014

version 1.3 : 19 / 11 / 2014

version 1.4 : 21 / 01 / 2016 - a clean version for community

=cut