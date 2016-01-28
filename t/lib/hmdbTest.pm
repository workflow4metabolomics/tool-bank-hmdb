package lib::hmdbTest ;

use diagnostics; # this gives you more debugging information
use warnings;    # this warns you of bad practices
use strict;      # this prevents silly errors
use Exporter ;
use Carp ;

our $VERSION = "1.0";
our @ISA = qw(Exporter);
our @EXPORT = qw( parse_hmdb_csv_resultsTest check_state_from_hmdb_uaTest test_matches_from_hmdb_uaTest extract_sub_mz_listsTest prepare_multi_masses_queryTest get_matches_from_hmdb_uaTest);
our %EXPORT_TAGS = ( ALL => [qw( parse_hmdb_csv_resultsTest check_state_from_hmdb_uaTest test_matches_from_hmdb_uaTest extract_sub_mz_listsTest prepare_multi_masses_queryTest get_matches_from_hmdb_uaTest)] );

use lib '/Users/fgiacomoni/Inra/labs/perl/galaxy_tools/hmdb' ;
use lib::hmdb qw( :ALL ) ;

use Data::Dumper ;

## sub
sub extract_sub_mz_listsTest {
	
	my ($masses, $hmdb_limits, ) = @_ ;
	
	my $oHmdb = lib::hmdb->new() ;
	my $submasses = $oHmdb->extract_sub_mz_lists($masses, $hmdb_limits ) ;

	return ($submasses) ;
}

## sub
sub prepare_multi_masses_queryTest {
	
	my ($mzs ) = @_ ;
	
	my $oHmdb = lib::hmdb->new() ;
	my ( $hmdb_masses, $nb_masses_to_submit ) = $oHmdb->prepare_multi_masses_query($mzs) ;
	
	return ($hmdb_masses) ;
}

## sub
sub get_matches_from_hmdb_uaTest {
	
	my ( $hmdb_masses, $delta, $molecular_species ) = @_ ;
	
	my $oHmdb = lib::hmdb->new() ;
	my $hmdb_pages = $oHmdb->get_matches_from_hmdb_ua($hmdb_masses, $delta, $molecular_species) ;
	return ($hmdb_pages) ;
}


## sub
sub test_matches_from_hmdb_uaTest {
	
	my $oHmdb = lib::hmdb->new() ;
	my $status = $oHmdb->test_matches_from_hmdb_ua() ;
	return ($status) ;
}


## sub
sub check_state_from_hmdb_uaTest {
	my ($status ) = @_ ;
	
	my $oHmdb = lib::hmdb->new() ;
	my $res = $oHmdb->check_state_from_hmdb_ua($status) ;
	return($res) ;
}



## sub
sub parse_hmdb_csv_resultsTest {
	my ($hmdb_pages, $mzs ) = @_ ;
	
	my $oHmdb = lib::hmdb->new() ;
	my $result = $oHmdb->parse_hmdb_csv_results($hmdb_pages, $mzs) ; ## hash format result

	return($result) ;
}


1 ;