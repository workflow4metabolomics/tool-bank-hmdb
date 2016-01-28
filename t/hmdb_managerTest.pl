#! perl
use diagnostics;
use warnings;
no warnings qw/void/;
use strict;
no strict "refs" ;
use Test::More qw( no_plan );
use Test::Exception;
use FindBin ;
use Carp ;

## Specific Modules
use lib $FindBin::Bin ;
my $binPath = $FindBin::Bin ;
use lib::hmdbTest qw( :ALL ) ;


## To launch the right sequence : API, MAPPER, THREADER, ...
#my $sequence = 'MAPPER' ; 
my $sequence = 'MAIN' ; 
my $current_test = 1 ;

if ($sequence eq "MAIN") {
	print "\n\t\t\t\t  * * * * * * \n" ;
	print "\t  * * * - - - Test HMDB Main script - - - * * * \n\n" ;
	
	
	print "\n** Test $current_test extract_sub_mz_lists with an empty list of mzs **\n" ; $current_test++;
	
	throws_ok{ extract_sub_mz_listsTest([], 3)} '/The provided mzs list is empty/', 'Method \'extract_sub_mz_lists\' detects empty argument and died correctly' ;
	
	print "\n** Test $current_test extract_sub_mz_lists with a list of mzs and a limit of 3 **\n" ; $current_test++;
	is_deeply( extract_sub_mz_listsTest(
		['175.01', '238.19', '420.16', '780.32', '956.25', '1100.45' ], 3), 
		[ [ '175.01', '238.19', '420.16' ], [ '780.32', '956.25', '1100.45' ] ], 
		'Method \'extract_sub_mz_lists\' works with a list and return a well formated list of sublist of mzs');
	
	print "\n** Test $current_test prepare_multi_masses_query with an empty list of mzs **\n" ; $current_test++;	
	throws_ok{ prepare_multi_masses_queryTest([])} '/The input method parameter mass list is empty/', 'Method \'prepare_multi_masses_query\' detects empty argument and died correctly' ;
	
	print "\n** Test $current_test prepare_multi_masses_query with a list of mzs **\n" ; $current_test++;
	is_deeply( prepare_multi_masses_queryTest(
		['175.01', '238.19', '420.16', '780.32', '956.25', '1100.45' ] ), 
		'175.01%0D%0A238.19%0D%0A420.16%0D%0A780.32%0D%0A956.25%0D%0A1100.45%0D%0A', 
		'Method \'prepare_multi_masses_query\' works with a list of and return a well formated string for hmdb querying');
		
	print "\n** Test $current_test get_matches_from_hmdb_ua with a well-formated string of mzs **\n" ; $current_test++;
	is_deeply( get_matches_from_hmdb_uaTest(
		'175.01%0D%0A420.16%0D%0A780.32%0D%0A956.25%0D%0A1100.45%0D%0A', 0.001, 'positive'),
		[
          'query_mass,compound_id,formula,compound_mass,adduct,adduct_type,adduct_mass,delta',
          '175.01,HMDB60293,H2O3S2,113.94453531,M+IsoProp+H,+,175.009875,0.000125',
          '175.01,HMDB03745,C2H6O3S2,141.975835438,M+CH3OH+H,+,175.009324,0.000676',
          '175.01,HMDB31436,H4O4Si,95.987885149,M+DMSO+H,+,175.009105,0.000895',
          '175.01,HMDB33657,C17H10O6,310.047738052,M+H+K,+,175.009086,0.000914',
          '175.01,HMDB35230,C17H10O6,310.047738052,M+H+K,+,175.009086,0.000914',
          '420.16,HMDB60838,C17H17N3O4S,359.093976737,M+IsoProp+H,+,420.159317,0.000683',
          '420.16,HMDB60836,C17H17N3O4S,359.093976737,M+IsoProp+H,+,420.159317,0.000683'
        ],
		'Method \'get_matches_from_hmdb_ua\' works with a well-formated string of mzs and return a complete csv from hmdb');
	
	print "\n** Test $current_test test_matches_from_hmdb_ua to get hmdb status **\n" ; $current_test++;
	is_deeply (test_matches_from_hmdb_uaTest (), 
		\'200', 
		'The HMDB server is available: returns successful HTTP requests' ) ;
		
	print "\n** Test $current_test check_state_from_hmdb_ua to manage script execution with the hmdb server status **\n" ; $current_test++;
	is_deeply (check_state_from_hmdb_uaTest (\'200'),
		1,
		'The status 200 returns no error/warn' ) ;
		
	print "\n** Test $current_test prepare_multi_masses_query with an empty list of mzs **\n" ; $current_test++;	
	throws_ok{ check_state_from_hmdb_uaTest(\'504')} 
		'/Gateway Timeout: The HMDB server was acting as a gateway or proxy and did not receive a timely response from the upstream server/', 
		'Method \'check_state_from_hmdb_ua\' detects HTTP error code returned by HMDB and died correctly' ;
		
	print "\n** Test $current_test parse_hmdb_csv_results with the correct inputs for hmdb outputs parsing (csv format) **\n" ; $current_test++;
	is_deeply ( parse_hmdb_csv_resultsTest (
		[
          'query_mass,compound_id,formula,compound_mass,adduct,adduct_type,adduct_mass,delta',
          '175.01,HMDB60293,H2O3S2,113.94453531,M+IsoProp+H,+,175.009875,0.000125',
          '175.01,HMDB03745,C2H6O3S2,141.975835438,M+CH3OH+H,+,175.009324,0.000676',
          '175.01,HMDB31436,H4O4Si,95.987885149,M+DMSO+H,+,175.009105,0.000895',
          '175.01,HMDB33657,C17H10O6,310.047738052,M+H+K,+,175.009086,0.000914',
          '175.01,HMDB35230,C17H10O6,310.047738052,M+H+K,+,175.009086,0.000914',
          '420.16,HMDB60838,C17H17N3O4S,359.093976737,M+IsoProp+H,+,420.159317,0.000683',
          '420.16,HMDB60836,C17H17N3O4S,359.093976737,M+IsoProp+H,+,420.159317,0.000683'
        ],
        ['175.01', '238.19', '420.16']
	),
		[
          [
			{ 'ENTRY_ADDUCT' => 'M+IsoProp+H', 'ENTRY_DELTA' => '0.000125', 'ENTRY_ADDUCT_TYPE' => '+', 'ENTRY_FORMULA' => 'H2O3S2', 'ENTRY_ENTRY_ID' => 'HMDB60293', 'ENTRY_ADDUCT_MZ' => '175.009875', 'ENTRY_CPD_MZ' => '113.94453531' },
			{ 'ENTRY_ADDUCT' => 'M+CH3OH+H', 'ENTRY_ADDUCT_TYPE' => '+', 'ENTRY_DELTA' => '0.000676', 'ENTRY_FORMULA' => 'C2H6O3S2', 'ENTRY_ENTRY_ID' => 'HMDB03745', 'ENTRY_ADDUCT_MZ' => '175.009324', 'ENTRY_CPD_MZ' => '141.975835438' },
			{ 'ENTRY_CPD_MZ' => '95.987885149', 'ENTRY_FORMULA' => 'H4O4Si', 'ENTRY_ENTRY_ID' => 'HMDB31436', 'ENTRY_ADDUCT_MZ' => '175.009105', 'ENTRY_DELTA' => '0.000895', 'ENTRY_ADDUCT_TYPE' => '+', 'ENTRY_ADDUCT' => 'M+DMSO+H' },
			{ 'ENTRY_ADDUCT_TYPE' => '+', 'ENTRY_DELTA' => '0.000914', 'ENTRY_ADDUCT' => 'M+H+K', 'ENTRY_CPD_MZ' => '310.047738052', 'ENTRY_ENTRY_ID' => 'HMDB33657', 'ENTRY_ADDUCT_MZ' => '175.009086', 'ENTRY_FORMULA' => 'C17H10O6' },
			{ 'ENTRY_ADDUCT' => 'M+H+K', 'ENTRY_DELTA' => '0.000914', 'ENTRY_ADDUCT_TYPE' => '+', 'ENTRY_FORMULA' => 'C17H10O6', 'ENTRY_ADDUCT_MZ' => '175.009086', 'ENTRY_ENTRY_ID' => 'HMDB35230', 'ENTRY_CPD_MZ' => '310.047738052' }
          ],
          [],
          [
            { 'ENTRY_ADDUCT' => 'M+IsoProp+H', 'ENTRY_ADDUCT_TYPE' => '+', 'ENTRY_DELTA' => '0.000683', 'ENTRY_ENTRY_ID' => 'HMDB60838', 'ENTRY_ADDUCT_MZ' => '420.159317', 'ENTRY_FORMULA' => 'C17H17N3O4S', 'ENTRY_CPD_MZ' => '359.093976737' }, 
            { 'ENTRY_CPD_MZ' => '359.093976737', 'ENTRY_FORMULA' => 'C17H17N3O4S', 'ENTRY_ENTRY_ID' => 'HMDB60836', 'ENTRY_ADDUCT_MZ' => '420.159317', 'ENTRY_ADDUCT_TYPE' => '+', 'ENTRY_DELTA' => '0.000683', 'ENTRY_ADDUCT' => 'M+IsoProp+H' }
          ]
        ],
		'Method \'parse_hmdb_csv_results\' works with a well-formated csv output and returns a a well formated array' ) ;
		
	print "\n** Test $current_test parse_hmdb_csv_results with a void hmdb output and a list of mzs **\n" ; $current_test++;
	is_deeply ( parse_hmdb_csv_resultsTest ( [], ['175.01', '238.19', '420.16'] ),
		[ [], [], [] ],
		'Method \'parse_hmdb_csv_results\' works with a empty csv output and returns an empty but well formatted array' ) ;
	
	print "\n** Test $current_test parse_hmdb_csv_results with a void hmdb output and a void mz list  **\n" ; $current_test++;
	is_deeply ( parse_hmdb_csv_resultsTest ( [], [] ),
		[],
		'Method \'parse_hmdb_csv_results\' works with a empty csv output/mz list and returns an empty but well formatted array' ) ;
}

















## END of the script