## ****** HMDB environnemnt : ****** ##
# version January 2016 M Landi / F Giacomoni - INRA - METABOHUB - workflow4metabolomics.org core team

## --- PERL compilator / libraries : --- ##
$ perl -v
This is perl, v5.10.1 (*) built for x86_64-linux-thread-multi

# libs CORE PERL : 
use strict ;
use warnings ;
use Carp qw (cluck croak carp) ;
use Exporter ;
use Data::Dumper ;
use Getopt::Long ;
use FindBin ;
use Encode;

# libs CPAN PERL : 
$ perl -e 'use Text::CSV'
$ perl -e 'use LWP::Simple'
$ perl -e 'use URI::URL'
$ perl -e 'use SOAP::Lite'
$ perl -e 'use HTML::Template'
$ sudo perl -MCPAN -e shell
cpan> install Text::CSV
cpan> install LWP::Simple
cpan> install URI::URL
cpan> install SOAP::Lite
cpan>  install HTML::Template

# libs pfem PERL : this lib were included in lib dir.
use conf::conf  qw( :ALL ) ;
use formats::csv  qw( :ALL ) ;
--

## --- R bin and Packages : --- ##
No interaction with R
-- 

## --- Binary dependencies --- ##
No interaction with binary - use only HMDB post method (http://www.hmdb.ca/spectra/ms/search?)
--

## --- Config : --- ##
JS and CSS (used in HTML output format) are now hosted on cdn.rawgit.com server - no local config needed


PS :If Galaxy can't find the file "hmdb.tmpl", perform this command line : perl -pi -e 's/\r//g' conf_hmdb.cfg
--

## --- XML HELP PART --- ##
one image : 
hmdb.png
--

## --- DATASETS OR TUTORIAL --- ##
Please find help on W4M : 
--

## --- ??? COMMENTS ??? --- ##
If Galaxy can't find the file "hmdb.tmpl", perform this command line : " perl -pi -e 's/\r//g' " on the conf file "conf_hmdb.cfg".

To use fully functionalities of HTML output format file : 
  - check that sanitize_all_html option in universe_wsgi.ini file is uncomment and set to FALSE.
--