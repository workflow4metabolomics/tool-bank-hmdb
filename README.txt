## ****** HMDB environnemnt : ****** ##
# version December 2014 M Landi / F Giacomoni

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

# libs pfem PERL : this lib were included in local. NO PATH TO CHANGE !!!
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
!!! EDIT THE FOLLOWING LINES in the config file : ~/metabolomics/Identification/Banks_Queries/HMDB/conf_hmdb.cfg
JS_GALAXY_PATH=http://YOUR_GALAXY_HOSTNAME/static/scripts/libs/outputs
CSS_GALAXY_PATH=http://YOUR_GALAXY_HOSTNAME/static/style
HTML_TEMPLATE=absolute_path_to_/hmdb.tmpl


PS :If Galaxy can't find the file "hmdb.tmpl", perform this command line : perl -pi -e 's/\r//g' conf_hmdb.cfg
--

## --- XML HELP PART --- ##
one image : 
hmdb.png
--

## --- DATASETS --- ##
No data set ! waiting for galaxy pages
--

## --- ??? COMMENTS ??? --- ##
If Galaxy can't find the file "hmdb.tmpl", perform this command line : " perl -pi -e 's/\r//g' " on the conf file "conf_hmdb.cfg".

To use full funtionalities of html output files : 
  - check that sanitize_all_html option in universe_wsgi.ini file is uncomment and set to FALSE.
  - copy the following JS files in YOUR_GALAXY_PATH/static/scripts/libs/outputs/ : jquery.simplePagination.js
  - copy the following CSS files in YOUR_GALAXY_PATH/static/style/ : simplePagination.css
 Their files (pfem-js and pfem-css) are available in the ABIMS toolshed "Tool Dependency Packages" category.
--