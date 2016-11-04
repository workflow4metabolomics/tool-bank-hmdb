package lib::hmdb ;

use strict;
use warnings ;
use Exporter ;
use Carp ;

use LWP::Simple;
use LWP::UserAgent;
use URI::URL;
use SOAP::Lite;
use Encode;
use HTML::Template ;
use XML::Twig ;

use Data::Dumper ;

use vars qw($VERSION @ISA @EXPORT %EXPORT_TAGS);

our $VERSION = "1.0";
our @ISA = qw(Exporter);
our @EXPORT = qw( map_suppl_data_on_hmdb_results get_unik_ids_from_results get_hmdb_metabocard_from_id extract_sub_mz_lists test_matches_from_hmdb_ua prepare_multi_masses_query get_matches_from_hmdb_ua parse_hmdb_csv_results set_html_tbody_object add_mz_to_tbody_object add_entries_to_tbody_object write_html_skel set_lm_matrix_object set_hmdb_matrix_object_with_ids add_lm_matrix_to_input_matrix write_csv_skel write_csv_one_mass );
our %EXPORT_TAGS = ( ALL => [qw( map_suppl_data_on_hmdb_results get_unik_ids_from_results get_hmdb_metabocard_from_id extract_sub_mz_lists test_matches_from_hmdb_ua prepare_multi_masses_query get_matches_from_hmdb_ua parse_hmdb_csv_results set_html_tbody_object add_mz_to_tbody_object add_entries_to_tbody_object write_html_skel set_lm_matrix_object set_hmdb_matrix_object_with_ids add_lm_matrix_to_input_matrix write_csv_skel write_csv_one_mass )] );

=head1 NAME

My::Module - An example module

=head1 SYNOPSIS

    use My::Module;
    my $object = My::Module->new();
    print $object->as_string;

=head1 DESCRIPTION

This module does not really exist, it
was made for the sole purpose of
demonstrating how POD works.

=head1 METHODS

Methods are :

=head2 METHOD new

	## Description : new
	## Input : $self
	## Ouput : bless $self ;
	## Usage : new() ;

=cut

sub new {
    ## Variables
    my $self={};
    bless($self) ;
    return $self ;
}
### END of SUB
     

=head2 METHOD extract_sub_mz_lists

	## Description : extract a couples of sublist from a long mz list (more than $HMDB_LIMITS)
	## Input : $HMDB_LIMITS, $masses
	## Output : $sublists
	## Usage : my ( $sublists ) = extract_sub_mz_lists( $HMDB_LIMITS, $masses ) ;
	
=cut
## START of SUB
sub extract_sub_mz_lists {
	## Retrieve Values
    my $self = shift ;
    my ( $masses, $HMDB_LIMITS ) = @_ ;
    
    my ( @sublists, @sublist ) = ( (), () ) ;
    my $nb_mz = 0 ;
    my $nb_total_mzs = scalar(@{$masses}) ;
    
    if ($nb_total_mzs == 0) {
    	die "The provided mzs list is empty" ;
    }
    
    for ( my $current_pos = 0 ; $current_pos < $nb_total_mzs ; $current_pos++ ) {
    	
    	if ( $nb_mz < $HMDB_LIMITS ) {
    		if ( $masses->[$current_pos] ) { 	push (@sublist, $masses->[$current_pos]) ; $nb_mz++ ;	} # build sub list
    	} 
    	elsif ( $nb_mz == $HMDB_LIMITS ) {
    		my @tmp = @sublist ; push (@sublists, \@tmp) ; @sublist = () ;	$nb_mz = 0 ;
    		$current_pos-- ;
    	}
    	if ($current_pos == $nb_total_mzs-1) { 	my @tmp = @sublist ; push (@sublists, \@tmp) ; }
	}
    return(\@sublists) ;
}
## END of SUB

=head2 METHOD prepare_multi_masses_query

	## Description : Generate the adapted format of the mz list for HMDB
	## Input : $masses
	## Output : $hmdb_masses
	## Usage : my ( $hmdb_masses ) = prepare_multi_masses_query( $masses ) ;
	
=cut
## START of SUB
sub prepare_multi_masses_query {
	## Retrieve Values
    my $self = shift ;
    my ( $masses ) = @_ ;
    
    my $hmdb_masses = undef ;
    my $sep = '%0D%0A' ; ## retour chariot encode
    my ($nb_masses, $i) = (0, 0) ;
    
    if ( defined $masses ) {
    	my @masses = @{$masses} ;
    	my $nb_masses = scalar ( @masses ) ;
    	if ( $nb_masses == 0 ) { croak "The input method parameter mass list is empty" ; }
    	elsif ( $nb_masses >= 150 ) { croak "Your mass list is too long : HMDB allows maximum 150 query masses per request \n" ; } ## Del it --- temporary patch
	    
	    foreach my $mass (@masses) {
	    	
	    	if ($i < $nb_masses) {
	    		$hmdb_masses .= $mass.$sep ;
	    	}
	    	elsif ( $i == $nb_masses ) {
	    		$hmdb_masses .= $mass ;
	    	}
	    	else {
	    		last ;
	    	}
	    	$i ++ ;
	    }
    }
    else {
    	croak "No mass list found \n" ;
    }
    return($hmdb_masses, $nb_masses) ;
}
## END of SUB

=head2 METHOD test_matches_from_hmdb_ua

	## Description : test a single query with tests parameters on hmdb - get the status of the complete server infra.
	## Input : none
	## Output : $status_line
	## Usage : my ( $status_line ) = test_matches_from_hmdb_ua( ) ;
	
=cut
## START of SUB
sub test_matches_from_hmdb_ua {
	## Retrieve Values
    my $self = shift ;
    
    my @page = () ;

	my $ua = new LWP::UserAgent;
	$ua->agent("Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/34.0.1847.131 Safari/537.36");
	 
	my $req = HTTP::Request->new(
	    POST => 'http://specdb.wishartlab.com/ms/search.csv');
	
	$req->content_type('application/x-www-form-urlencoded');
	$req->content('utf8=TRUE&mode=positive&query_masses=420.159317&tolerance=0.000001&database=HMDB&commit=Download Results As CSV');
	 
	my $res = $ua->request($req);
#	print $res->as_string;
	my $status_line = $res->status_line ;
	($status_line) = ($status_line =~ /(\d+)/);
	
	
	return (\$status_line) ;
}
## END of SUB

=head2 METHOD check_state_from_hmdb_ua

	## Description : check the thhp status of hmdb and kill correctly the script if necessary.
	## Input : $status
	## Output : none
	## Usage : check_state_from_hmdb_ua($status) ;
	
=cut
## START of SUB
sub check_state_from_hmdb_ua {
	## Retrieve Values
    my $self = shift ;
    my ($status) = @_ ;
    
    if (!defined $$status) {
    	croak "No http status is defined for the distant server" ;
    }
    else {
    	unless ( $$status == 200 ) { 
    		if  ( $$status == 504 ) { croak "Gateway Timeout: The HMDB server was acting as a gateway or proxy and did not receive a timely response from the upstream server" ; }
    		else {
    			## None supported http code error ##
    		}
    	}
    }
    
    return (1) ;
}
## END of SUB

=head2 METHOD get_matches_from_hmdb_ua

	## Description : HMDB querying via an user agent with parameters : mz, delta and molecular species (neutral, pos, neg)
	## Input : $mass, $delta, $mode
	## Output : $results
	## Usage : my ( $results ) = get_matches_from_hmdb( $mass, $delta, $mode ) ;
	
=cut
## START of SUB
sub get_matches_from_hmdb_ua {
	## Retrieve Values
    my $self = shift ;
    my ( $masses, $delta, $mode ) = @_ ;
    
    my @page = () ;

	my $ua = new LWP::UserAgent;
	$ua->agent("Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/34.0.1847.131 Safari/537.36");
	$ua->timeout(500);
	 
	my $req = HTTP::Request->new(
	    POST => 'http://specdb.wishartlab.com/ms/search.csv');
	
	$req->content_type('application/x-www-form-urlencoded');
	$req->content('utf8=TRUE&mode='.$mode.'&query_masses='.$masses.'&tolerance='.$delta.'&database=HMDB&commit=Download Results As CSV');
	 
	my $res = $ua->request($req);
#	print $res->as_string;
	if ($res->is_success) {
	     @page = split ( /\n/, $res->decoded_content ) ;
	 } else {
	 	my $status_line = $res->status_line ;
	 	($status_line) = ($status_line =~ /(\d+)/);
	 	croak "HMDB service none available !! Status of the HMDB server is : $status_line\n" ;
	 }
	
	
	return (\@page) ;
}
## END of SUB

=head2 METHOD parse_hmdb_csv_results

	## Description : parse the csv results and get data
	## Input : $csv
	## Output : $results
	## Usage : my ( $results ) = parse_hmdb_csv_results( $csv ) ;
	
=cut
## START of SUB
sub parse_hmdb_csv_results {
	## Retrieve Values
    my $self = shift ;
    my ( $csv, $masses ) = @_ ;
    
    my $test = 0 ;
    my ($query_mass,$compound_id,$formula,$compound_mass,$adduct,$adduct_type,$adduct_mass,$delta) = (0, undef, undef, undef, undef, undef, undef, undef) ;
    
    my %result_by_entry = () ;
    my %features = () ;
    
#    print Dumper $csv ;
    
    foreach my $line (@{$csv}) {
    	
    	if ($line !~ /query_mass,compound_id,formula,compound_mass,adduct,adduct_type,adduct_mass,delta/) {
    		my @entry = split(/,/, $line) ;
    		
    		if ( !exists $result_by_entry{$entry[0]} ) { $result_by_entry{$entry[0]} = [] ; }
    		
    		$features{ENTRY_ENTRY_ID} = $entry[1] ;
    		$features{ENTRY_FORMULA} = $entry[2] ;
    		$features{ENTRY_CPD_MZ} = $entry[3] ;
    		$features{ENTRY_ADDUCT} = $entry[4] ;
    		$features{ENTRY_ADDUCT_TYPE} = $entry[5] ;
    		$features{ENTRY_ADDUCT_MZ} = $entry[6] ;
    		$features{ENTRY_DELTA} = $entry[7] ;
    		
    		my %temp = %features ;
    		
    		push (@{$result_by_entry{$entry[0]} }, \%temp) ;
    	}
    	else {
    		next ;
    	}
    } ## end foreach
    
    ## manage per query_mzs (keep query masses order by array)
    my @results = () ;
    foreach (@{$masses}) {
    	if ($result_by_entry{$_}) { push (@results, $result_by_entry{$_}) ; }
    	else {push (@results, [] ) ;} ;
    }
    return(\@results) ;
}
## END of SUB

=head2 METHOD parse_hmdb_page_results 

	## Description : [DEPRECATED] old HMDB html page parser
	## Input : $page
	## Output : $results
	## Usage : my ( $results ) = parse_hmdb_page_result( $pages ) ;
	
=cut
## START of SUB
sub parse_hmdb_page_results {
	## Retrieve Values
    my $self = shift ;
    my ( $page ) = @_ ;
    
    my @results = () ;
    my ($catch_table, $catch_name) = (0, 0) ;
    my ($name, $adduct, $adduct_mw, $cpd_mw, $delta) = (undef, undef, undef, undef, undef) ;
    
    if ( defined $page ) {
    	
    	my @page = @{$page} ;
    	my $ID = undef ;
    	my @result_by_mz = () ;
    	my %result_by_entry = () ;
    	
		foreach my $line (@page)   {
			
			#Section de la page contenant les resultat
			if( $line =~/<table>/ ) { $catch_table = 1 ; }
			
			## Si il existe un resultat :
			if($catch_table == 1) {
		    	
			    #Id de la molecule, et creation du lien
			    if( $line =~ /<a href=\"\/metabolites\/(\w+)\" (.*)>/ )  {
			    	$ID = $1 ;
			    	$catch_name = 0 ;
			    	next ;
			    }
			    #Nom de la molecule ONLY!!
			    if ( $catch_name == 0 ) {
			    	
			    	if( $line =~ /<td>(.+)<\/td>/ ) {
			    		
			    		if ( !defined $name ) {
			    			$name = $1 ;
			    			$result_by_entry{'ENTRY_ENTRY_ID'} = $ID ;
					    	$result_by_entry{'ENTRY_NAME'} = $name ;
					    	next ; 
			    		}
			    		if ( !defined $adduct ) { $adduct = $1 ;  $result_by_entry{'ENTRY_ADDUCT'} = $adduct ; next ; }
			    		if ( !defined $adduct_mw ) {  $adduct_mw = $1 ; $result_by_entry{'ENTRY_ADDUCT_MZ'} = $adduct_mw ; next ; 	}
			    		if ( !defined $cpd_mw ) { $cpd_mw = $1 ; $result_by_entry{'ENTRY_CPD_MZ'} = $cpd_mw ; next ; 	}
			    		if ( !defined $delta ) {
			    			$delta = $1 ;
			    			$result_by_entry{'ENTRY_DELTA'} = $delta ;
			    			$catch_name = 1 ;
			    			my %tmp = %result_by_entry ;
			    			push (@result_by_mz, \%tmp) ;
			    			%result_by_entry = () ;
			    			( $name, $cpd_mw, $delta, $adduct, $adduct_mw ) = ( undef, undef, undef, undef, undef ) ;
			    			next ;
			    		}
				    }
			    }
			}
			#Fin de la section contenant les resultats
			if( $line =~ /<\/table>/ ) {
				$catch_table = 0 ;
				my @Tmp = @result_by_mz ;
				push(@results, \@Tmp) ;
				@result_by_mz = () ;
			}
	    }
    }
    return(\@results) ;
}
## END of SUB


=head2 METHOD get_unik_ids_from_results

	## Description : get all unik ids from the hmdb result object
	## Input : $results
	## Output : $ids
	## Usage : my ( $ids ) = get_unik_ids_from_results ( $results ) ;
	
=cut
## START of SUB
sub get_unik_ids_from_results {
    ## Retrieve Values
    my $self = shift ;
    my ( $results ) = @_;
    my ( %ids ) = ( () ) ;
    
    foreach my $result (@{$results}) {
    	
    	foreach my $entries (@{$result}) {
    		
    		if ( ($entries->{'ENTRY_ENTRY_ID'}) and ($entries->{'ENTRY_ENTRY_ID'} ne '' ) ) {
    			$ids{$entries->{'ENTRY_ENTRY_ID'}} = 1 ;
    		}
    	}
    }
    
    return (\%ids) ;
}
### END of SUB



=head2 METHOD get_hmdb_metabocard_from_id

	## Description : get a metabocard (xml format from an ID on HMDB)
	## Input : $ids
	## Output : $metabocard_features
	## Usage : my ( $metabocard_features ) = get_hmdb_metabocard_from_id ( $ids ) ;
	
=cut
## START of SUB
sub get_hmdb_metabocard_from_id {
    ## Retrieve Values
    my $self = shift ;
    my ( $ids, $hmdb_url ) = @_;
    my ( %metabocard_features ) = ( () ) ;
    my $query = undef ;
    
    ## structure %metabocard_features
    # metabolite_id = (
    #	'metabolite_name' => '__name__',
    #	'metabolite_inchi' => '__inchi__',
    #	'metabolite_logp' => '__logp-ALOGPS__',
    #
    # )
    
    
    if( (defined $ids) and  ($ids > 0 ) ) {
    	
    	foreach my $id (keys %{$ids}) {
			
#			print "\n============== > $id **********************\n " ;
			my $twig = undef ;
			
			if (defined $hmdb_url) {
				$query = $hmdb_url.$id.'.xml' ;
				
				## test the header if exists
				my $response = head($query) ;
				
				if (!defined $response) {
					$metabocard_features{$id}{'metabolite_name'} = undef ;
					$metabocard_features{$id}{'metabolite_inchi'} = undef ;
					$metabocard_features{$id}{'metabolite_logp'} = undef ;
					## Need to be improve to manage http 404 or other response diff than 200
				}
				elsif ($response->is_success) {
					
					$twig = XML::Twig->nparse_ppe(
					
						twig_handlers => { 
							# metabolite name
							'metabolite/name' => sub { $metabocard_features{$id}{'metabolite_name'} = $_ -> text_only ; } ,
							# metabolite inchi
							'metabolite/inchi' => sub { $metabocard_features{$id}{'metabolite_inchi'} = $_ -> text_only ; } ,
							## metabolite logP
							'metabolite/predicted_properties/property' => sub {
								
								my ($kind, $source, $value ) = ( undef, undef, undef ) ;
								
								if (defined $_->children ) {
    								foreach my $field ($_->children) {
    									if ( $field->name eq 'kind') 		{ $kind = $field->text ; }
    									elsif ( $field->name eq 'source') 	{ $source = $field->text ; }
    									elsif ( $field->name eq 'value') 	{ $value = $field->text ; }
    									
    									if (defined $source ) {
    										if ( ( $kind eq 'logp' ) and ( $source eq 'ALOGPS' ) ) {
												$metabocard_features{$id}{'metabolite_logp'} = $value ;
											}
											($kind, $source, $value ) = ( undef, undef, undef ) ;
    									}
    								}
								}
							}
						}, 
						pretty_print => 'indented', 
						error_context => 1, $query
					);
						
#				    $twig->print;
					$twig->purge ;
				    
				    if (!$@) {
				    	
				    }
				    else {
				    	warn $@ ;
				    }
				}
			}
			else {
				warn "The hmdb metabocard url is not defined\n" ;
				last;
			}
    	}
    }
    else {
    	warn "The HMDB ids list from HMDB is empty - No metabocard found\n" ;
    }
    
#    print Dumper %metabocard_features ;
    return (\%metabocard_features) ;
}
### END of SUB


=head2 METHOD map_suppl_data_on_hmdb_results

	## Description : map supplementary data with already collected results with hmdb search
	## Input : $results, $features
	## Output : $results
	## Usage : my ( $results ) = map_suppl_data_on_hmdb_results ( $results, $features ) ;
	
=cut
## START of SUB
sub map_suppl_data_on_hmdb_results {
    ## Retrieve Values
    my $self = shift ;
    my ( $results, $features ) = @_;
    my ( @more_results ) = ( () ) ;
    
    @more_results = @{$results} ; ## Dump array ref to map
    
    foreach my $result (@more_results) {
    	
    	foreach my $entries (@{$result}) {
    		
    		if ( ($entries->{'ENTRY_ENTRY_ID'}) and ($entries->{'ENTRY_ENTRY_ID'} ne '' ) ) {
    			## check that we have a ID for mapping
    			my $current_id = $entries->{'ENTRY_ENTRY_ID'} ;
    			if ($features->{"$current_id"}) {
    				## Metabolite NAME
    				if (defined $features->{"$current_id"}{'metabolite_name'} ) {
    					$entries->{'ENTRY_ENTRY_NAME'} = $features->{"$current_id"}{'metabolite_name'}
    				}
    				else {
    					$entries->{'ENTRY_ENTRY_NAME'} = 'UNKNOWN' ;
    				}
    				## Metabolite INCHI
    				if (defined $features->{"$current_id"}{'metabolite_inchi'} ) {
    					$entries->{'ENTRY_ENTRY_INCHI'} = $features->{"$current_id"}{'metabolite_inchi'}
    				}
    				else {
    					$entries->{'ENTRY_ENTRY_INCHI'} = 'NA' ;
    				}
    				## Metabolite LOGP
    				if (defined $features->{"$current_id"}{'metabolite_logp'} ) {
    					$entries->{'ENTRY_ENTRY_LOGP'} = $features->{"$current_id"}{'metabolite_logp'}
    				}
    				else {
    					$entries->{'ENTRY_ENTRY_LOGP'} = 'NA' ;
    				}
    			}
    			else {
    				warn "This HMDB id doesn't match any collected ids\n" ;
    			}
    		}
    	}
    }
    
    return (\@more_results) ;
}
### END of SUB


=head2 METHOD set_html_tbody_object

	## Description : initializes and build the tbody object (perl array) needed to html template
	## Input : $nb_pages, $nb_items_per_page
	## Output : $tbody_object
	## Usage : my ( $tbody_object ) = set_html_tbody_object($nb_pages, $nb_items_per_page) ;
	
=cut
## START of SUB
sub set_html_tbody_object {
	my $self = shift ;
    my ( $nb_pages, $nb_items_per_page ) = @_ ;

	my ( @tbody_object ) = ( ) ;
	
	for ( my $i = 1 ; $i <= $nb_pages ; $i++ ) {
	    
	    my %pages = ( 
	    	# tbody feature
	    	PAGE_NB => $i,
	    	MASSES => [], ## end MASSES
	    ) ; ## end TBODY N
	    push (@tbody_object, \%pages) ;
	}
    return(\@tbody_object) ;
}
## END of SUB

=head2 METHOD add_mz_to_tbody_object

	## Description : initializes and build the mz object (perl array) needed to html template
	## Input : $tbody_object, $nb_items_per_page, $mz_list
	## Output : $tbody_object
	## Usage : my ( $tbody_object ) = add_mz_to_tbody_object( $tbody_object, $nb_items_per_page, $mz_list ) ;
	
=cut
## START of SUB
sub add_mz_to_tbody_object {
	my $self = shift ;
    my ( $tbody_object, $nb_items_per_page, $mz_list, $ids_list ) = @_ ;

	my ( $current_page, $mz_index ) = ( 0, 0 ) ;
	
	foreach my $page ( @{$tbody_object} ) {
		
		my @colors = ('white', 'green') ;
		my ( $current_index, , $icolor ) = ( 0, 0 ) ;
		
		for ( my $i = 1 ; $i <= $nb_items_per_page ; $i++ ) {
			# 
			if ( $current_index > $nb_items_per_page ) { ## manage exact mz per html page
				$current_index = 0 ; 
				last ; ##
			}
			else {
				$current_index++ ;
				if ( $icolor > 1 ) { $icolor = 0 ; }
				
				if ( exists $mz_list->[$mz_index]  ) {
					
					my %mz = (
						# mass feature
						MASSES_ID_QUERY => $ids_list->[$mz_index],
						MASSES_MZ_QUERY => $mz_list->[$mz_index],
						MZ_COLOR => $colors[$icolor],
						MASSES_NB => $mz_index+1,
						ENTRIES => [] ,
					) ;
					push ( @{ $tbody_object->[$current_page]{MASSES} }, \%mz ) ;
					# Html attr for mass
					$icolor++ ;
				}
			}
			$mz_index++ ;
		} ## foreach mz

		$current_page++ ;
	}
    return($tbody_object) ;
}
## END of SUB

=head2 METHOD add_entries_to_tbody_object

	## Description : initializes and build the entries object (perl array) needed to html template
	## Input : $tbody_object, $nb_items_per_page, $mz_list, $entries
	## Output : $tbody_object
	## Usage : my ( $tbody_object ) = add_entries_to_tbody_object( $tbody_object, $nb_items_per_page, $mz_list, $entries ) ;
	
=cut
## START of SUB
sub add_entries_to_tbody_object {
	## Retrieve Values
    my $self = shift ;
    my ( $tbody_object, $nb_items_per_page, $mz_list, $entries ) = @_ ;
    
    my $index_page = 0 ;
    my $index_mz_continous = 0 ;
    
    foreach my $page (@{$tbody_object}) {
    	
    	my $index_mz = 0 ;
    	
    	foreach my $mz (@{ $tbody_object->[$index_page]{MASSES} }) {
    		
    		my $index_entry = 0 ;
    		
    		my @anti_redondant = ('N/A') ;
    		my $check_rebond = 0 ;
    		my $check_noentry = 0 ; 
    		
    		foreach my $entry (@{ $entries->[$index_mz_continous] }) {
    			$check_noentry ++ ;
    			## dispo anti doublons des entries
    			foreach my $rebond (@anti_redondant) {
    				if ( $rebond eq $entries->[$index_mz_continous][$index_entry]{ENTRY_ENTRY_ID} ) {	$check_rebond = 1 ; last ; }
    			}
    			
    			if ( $check_rebond == 0 ) {
    				
    				 push ( @anti_redondant, $entries->[$index_mz_continous][$index_entry]{ENTRY_ENTRY_ID} ) ;
    				
    				my %entry = (
		    			ENTRY_COLOR => $tbody_object->[$index_page]{MASSES}[$index_mz]{MZ_COLOR},
		   				ENTRY_ENTRY_ID => $entries->[$index_mz_continous][$index_entry]{ENTRY_ENTRY_ID},
		   				ENTRY_ENTRY_ID2 => $entries->[$index_mz_continous][$index_entry]{ENTRY_ENTRY_ID},
						ENTRY_FORMULA => $entries->[$index_mz_continous][$index_entry]{ENTRY_FORMULA},
						ENTRY_CPD_MZ => $entries->[$index_mz_continous][$index_entry]{ENTRY_CPD_MZ},
						ENTRY_ADDUCT => $entries->[$index_mz_continous][$index_entry]{ENTRY_ADDUCT},
						ENTRY_ADDUCT_TYPE => $entries->[$index_mz_continous][$index_entry]{ENTRY_ADDUCT_TYPE},
						ENTRY_ADDUCT_MZ => $entries->[$index_mz_continous][$index_entry]{ENTRY_ADDUCT_MZ},
						ENTRY_DELTA => $entries->[$index_mz_continous][$index_entry]{ENTRY_DELTA},   			
		    		) ;
		    		
	    			push ( @{ $tbody_object->[$index_page]{MASSES}[$index_mz]{ENTRIES} }, \%entry) ;
    			}
    			$check_rebond = 0 ; ## reinit double control
    			$index_entry++ ;	
    		} ## end foreach
    		if ($check_noentry == 0 ) {
    			my %entry = (
		    			ENTRY_COLOR => $tbody_object->[$index_page]{MASSES}[$index_mz]{MZ_COLOR},
		   				ENTRY_ENTRY_ID => 'NONE',
		   				ENTRY_ENTRY_ID2 => '',
						ENTRY_FORMULA => 'n/a',
						ENTRY_CPD_MZ => 'n/a',
						ENTRY_ADDUCT => 'n/a',
						ENTRY_ADDUCT_TYPE => 'n/a',
						ENTRY_ADDUCT_MZ => 'n/a',
						ENTRY_DELTA => 0,   			
		    		) ;
		    		push ( @{ $tbody_object->[$index_page]{MASSES}[$index_mz]{ENTRIES} }, \%entry) ;
    		}
    		$index_mz ++ ;
    		$index_mz_continous ++ ;
    	}
    	$index_page++ ;
    }
    return($tbody_object) ;
}
## END of SUB

=head2 METHOD write_html_skel

	## Description : prepare and write the html output file
	## Input : $html_file_name, $html_object, $html_template
	## Output : $html_file_name
	## Usage : my ( $html_file_name ) = write_html_skel( $html_file_name, $html_object ) ;
	
=cut
## START of SUB
sub write_html_skel {
	## Retrieve Values
    my $self = shift ;
    my ( $html_file_name,  $html_object, $pages , $search_condition, $html_template, $js_path, $css_path ) = @_ ;
    
    my $html_file = $$html_file_name ;
    
    if ( defined $html_file ) {
		open ( HTML, ">$html_file" ) or die "Can't create the output file $html_file " ;
		
		if (-e $html_template) {
			my $ohtml = HTML::Template->new(filename => $html_template);
			$ohtml->param(  JS_GALAXY_PATH => $js_path, CSS_GALAXY_PATH => $css_path  ) ;
			$ohtml->param(  CONDITIONS => $search_condition  ) ;
			$ohtml->param(  PAGES_NB => $pages  ) ;
			$ohtml->param(  PAGES => $html_object  ) ;
			print HTML $ohtml->output ;
		}
		else {
			croak "Can't fill any html output : No template available ($html_template)\n" ;
		}
		
		close (HTML) ;
    }
    else {
    	croak "No output file name available to write HTML file\n" ;
    }
    return(\$html_file) ;
}
## END of SUB

=head2 METHOD set_lm_matrix_object

	## Description : build the hmdb_row under its ref form
	## Input : $header, $init_mzs, $entries
	## Output : $hmdb_matrix
	## Usage : my ( $hmdb_matrix ) = set_lm_matrix_object( $header, $init_mzs, $entries ) ;
	
=cut
## START of SUB
sub set_lm_matrix_object {
	## Retrieve Values
    my $self = shift ;
    my ( $header, $init_mzs, $entries ) = @_ ;
    
    my @hmdb_matrix = () ;
    
    if ( defined $header ) {
    	my @headers = () ;
    	push @headers, $header ;
    	push @hmdb_matrix, \@headers ;
    }
    
    my $index_mz = 0 ;
    
    foreach my $mz ( @{$init_mzs} ) {
    	
    	my $index_entries = 0 ;
    	my @clusters = () ;
    	my $cluster_col = undef ;
    	
    	my @anti_redondant = ('N/A') ;
    	my $check_rebond = 0 ;
    	
    	my $nb_entries = scalar (@{ $entries->[$index_mz] }) ;
    	    	
    	foreach my $entry (@{ $entries->[$index_mz] }) {
    		
    		## dispo anti doublons des entries
    		foreach my $rebond (@anti_redondant) {
    			if ( $rebond eq $entries->[$index_mz][$index_entries]{ENTRY_ENTRY_ID} ) {	$check_rebond = 1 ; last ; }
    		}
	    	
	    	if ( $check_rebond == 0 ) {
    				
	    		push ( @anti_redondant, $entries->[$index_mz][$index_entries]{ENTRY_ENTRY_ID} ) ;
		    			    	
		    	my $delta = $entries->[$index_mz][$index_entries]{ENTRY_DELTA} ;
	    		my $formula =  $entries->[$index_mz][$index_entries]{ENTRY_FORMULA} ;
	    		my $hmdb_id = $entries->[$index_mz][$index_entries]{ENTRY_ENTRY_ID}  ;
		    	
		    	## METLIN data display model 
		   		## entry1=VAR1::VAR2::VAR3::VAR4|entry2=VAR1::VAR2::VAR3::VAR4|...
		   		# manage final pipe
		   		if ($index_entries < $nb_entries-1 ) { 	$cluster_col .= $delta.'::('.$formula.')::'.$hmdb_id.'|' ; }
		   		else { 						   			$cluster_col .= $delta.'::('.$formula.')::'.$hmdb_id ; 	}
	    		
	    	}
	    	$check_rebond = 0 ; ## reinit double control
	    	$index_entries++ ;
	    } ## end foreach
	    if ( !defined $cluster_col ) { $cluster_col = 'NONE' ; }
    	push (@clusters, $cluster_col) ;
    	push (@hmdb_matrix, \@clusters) ;
    	$index_mz++ ;
    }
    return(\@hmdb_matrix) ;
}
## END of SUB

=head2 METHOD set_hmdb_matrix_object_with_ids

	## Description : build the hmdb_row under its ref form (IDS only)
	## Input : $header, $init_mzs, $entries
	## Output : $hmdb_matrix
	## Usage : my ( $hmdb_matrix ) = set_hmdb_matrix_object_with_ids( $header, $init_mzs, $entries ) ;
	
=cut
## START of SUB
sub set_hmdb_matrix_object_with_ids {
	## Retrieve Values
    my $self = shift ;
    my ( $header, $init_mzs, $entries ) = @_ ;
    
    my @hmdb_matrix = () ;
    
    if ( defined $header ) {
    	my @headers = () ;
    	push @headers, $header ;
    	push @hmdb_matrix, \@headers ;
    }
    
    my $index_mz = 0 ;
    
    foreach my $mz ( @{$init_mzs} ) {
    	
    	my $index_entries = 0 ;
    	my @clusters = () ;
    	my $cluster_col = undef ;
    	
    	my @anti_redondant = ('N/A') ;
    	my $check_rebond = 0 ;
    	
    	my $nb_entries = scalar (@{ $entries->[$index_mz] }) ;
    	    	
    	foreach my $entry (@{ $entries->[$index_mz] }) {
    		
    		## dispo anti doublons des entries
    		foreach my $rebond (@anti_redondant) {
    			if ( $rebond eq $entries->[$index_mz][$index_entries]{ENTRY_ENTRY_ID} ) {	$check_rebond = 1 ; last ; }
    		}
	    	
	    	if ( $check_rebond == 0 ) {
    				
	    		push ( @anti_redondant, $entries->[$index_mz][$index_entries]{ENTRY_ENTRY_ID} ) ;
	    		my $hmdb_id = $entries->[$index_mz][$index_entries]{ENTRY_ENTRY_ID}  ;
		    	
		    	## METLIN data display model -- IDs ONLY !!
		   		## entry1=VAR1::VAR2::VAR3::VAR4|entry2=VAR1::VAR2::VAR3::VAR4|...
		   		# manage final pipe
		   		if ($index_entries < $nb_entries-1 ) { 	$cluster_col .= $hmdb_id.'|' ; }
		   		else { 						   			$cluster_col .= $hmdb_id ; 	}
	    		
	    	}
	    	$check_rebond = 0 ; ## reinit double control
	    	$index_entries++ ;
	    } ## end foreach
	    if ( !defined $cluster_col ) { $cluster_col = 'NONE' ; }
    	push (@clusters, $cluster_col) ;
    	push (@hmdb_matrix, \@clusters) ;
    	$index_mz++ ;
    }
    return(\@hmdb_matrix) ;
}
## END of SUB

=head2 METHOD add_lm_matrix_to_input_matrix

	## Description : build a full matrix (input + lm column)
	## Input : $input_matrix_object, $lm_matrix_object, $nb_header
	## Output : $output_matrix_object
	## Usage : my ( $output_matrix_object ) = add_lm_matrix_to_input_matrix( $input_matrix_object, $lm_matrix_object, $nb_header ) ;
	
=cut
## START of SUB
sub add_lm_matrix_to_input_matrix {
	## Retrieve Values
    my $self = shift ;
    my ( $input_matrix_object, $lm_matrix_object, $nb_header ) = @_ ;
    
    my @output_matrix_object = () ;
    my $index_row = 0 ;
    my $line = 0 ;
    
    foreach my $row ( @{$input_matrix_object} ) {
    	my @init_row = @{$row} ;
    	$line++;
    	
    	if ( ( defined $nb_header ) and ( $line <= $nb_header) ) {
    		push (@output_matrix_object, \@init_row) ;
    		next ;
    	}
    	
    	if ( $lm_matrix_object->[$index_row] ) {
    		my $dim = scalar(@{$lm_matrix_object->[$index_row]}) ;
    		
    		if ($dim > 1) { warn "the add method can't manage more than one column\n" ;}
    		my $lm_col =  $lm_matrix_object->[$index_row][$dim-1] ;

   		 	push (@init_row, $lm_col) ;
	    	$index_row++ ;
    	}
    	push (@output_matrix_object, \@init_row) ;
    }
    return(\@output_matrix_object) ;
}
## END of SUB

=head2 METHOD write_csv_skel

	## Description : prepare and write csv output file
	## Input : $csv_file, $rows
	## Output : $csv_file
	## Usage : my ( $csv_file ) = write_csv_skel( $csv_file, $rows ) ;
	
=cut
## START of SUB
sub write_csv_skel {
	## Retrieve Values
    my $self = shift ;
    my ( $csv_file, $rows ) = @_ ;
    
    my $ocsv = lib::csv::new() ;
	my $csv = $ocsv->get_csv_object("\t") ;
	$ocsv->write_csv_from_arrays($csv, $$csv_file, $rows) ;
    
    return($csv_file) ;
}
## END of SUB

=head2 METHOD write_csv_one_mass

	## Description : print a cvs file
	## Input : $masses, $ids, $results, $file
	## Output : N/A
	## Usage : write_csv_one_mass( $ids, $results, $file ) ;
	
=cut
## START of SUB
sub write_csv_one_mass {
	## Retrieve Values
    my $self = shift ;
    my ( $masses, $ids, $results, $file,  ) = @_ ;

    open(CSV, '>:utf8', "$file") or die "Cant' create the file $file\n" ;
    print CSV "ID\tMASS_SUBMIT\tHMDB_ID\tCPD_FORMULA\tCPD_MW\tDELTA\n" ;
    	
    my $i = 0 ;
    	
    foreach my $id (@{$ids}) {
    	my $mass = undef ;
    	if ( $masses->[$i] ) { 	$mass = $masses->[$i] ; 	}
    	else {						last ; 					 	}
    	
    	if ( $results->[$i] ) { ## an requested id has a result in the list of hashes $results.

    		my @anti_redondant = ('N/A') ;
    		my $check_rebond = 0 ;
    		my $check_noentry = 0 ;
    		
    		foreach my $entry (@{$results->[$i]}) {
    			$check_noentry ++ ;
    			## dispo anti doublons des entries
	    		foreach my $rebond (@anti_redondant) {
	    			if ( $rebond eq $entry->{ENTRY_ENTRY_ID} ) { $check_rebond = 1 ; last ; }
	    		}
#	    		print "\n-----------------------" ;
#	    		print Dumper $entry->{ENTRY_ENTRY_ID} ;
#	    		print "-------------------------$check_rebond\n" ;
#		    	print Dumper @anti_redondant ;
		    	if ( $check_rebond == 0 ) {
	    			
		    		push ( @anti_redondant, $entry->{ENTRY_ENTRY_ID} ) ;

	    			print CSV "$id\t$mass\t$entry->{ENTRY_ENTRY_ID}\t" ;
	    			## print cpd name
	    			if ( $entry->{ENTRY_FORMULA} ) { print CSV "$entry->{ENTRY_FORMULA}\t" ; }
	    			else { 							 print CSV "N/A\t" ; }
	    			## print cpd mw
	    			if ( $entry->{ENTRY_CPD_MZ} ) { print CSV "$entry->{ENTRY_CPD_MZ}\t" ; }
	    			else { 							print CSV "N/A\t" ; }
	    			## print delta
	    			if ( $entry->{ENTRY_DELTA} ) {  print CSV "$entry->{ENTRY_DELTA}\n" ; }
	    			else { 							print CSV "N/A\n" ; }
		    	}
		    	$check_rebond = 0 ; ## reinit double control
    		} ## end foreach
    		if ($check_noentry == 0 ) {
    			print CSV "$id\t$mass\t".'NONE'."\tn/a\tn/a\t0\n" ;
    		}
    	}
    	$i++ ;
    }
   	close(CSV) ;
    return() ;
}
## END of SUB

1 ;


__END__

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

 perldoc hmdb.pm

=head1 Exports

=over 4

=item :ALL is ...

=back

=head1 AUTHOR

Franck Giacomoni E<lt>franck.giacomoni@clermont.inra.frE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 VERSION

version 1 : 06 / 06 / 2013

version 2 : 27 / 01 / 2014

version 3 : 19 / 11 / 2014

version 4 : 28 / 01 / 2016

version 5 : 02 / 11 /2016

=cut
