HMDB MS search - search by masses on HMDB online bank
=====================================================

[![bioconda-badge](https://img.shields.io/badge/install%20with-bioconda-brightgreen.svg?style=flat-square)](http://bioconda.github.io) [![Build Status](https://travis-ci.org/workflow4metabolomics/tool-bank-hmdb.svg?branch=master)](https://travis-ci.org/workflow4metabolomics/tool-bank-hmdb)

Our project
-----------
The [Workflow4Metabolomics](http://workflow4metabolomics.org), W4M in short, is a French infrastructure offering software tool processing, analyzing and annotating metabolomics data. It is based on the Galaxy platform.


HMDB MS search - search by masses on HMDB online bank
-----------------------------------------------------

Tool using the HMDB Library Search.


Galaxy
------
Galaxy is an open, web-based platform for data intensive biomedical research. Whether on the free public server or your own instance, you can perform, reproduce, and share complete analyses. 

Homepage: [https://galaxyproject.org/](https://galaxyproject.org/)


Dependencies using Conda
------------------------
[![bioconda-badge](https://img.shields.io/badge/install%20with-bioconda-brightgreen.svg?style=flat-square)](http://bioconda.github.io)


[Conda](http://conda.pydata.org/) is package manager that among many other things can be used to manage Python packages.

```
#To install miniconda2
#http://conda.pydata.org/miniconda.html
#To install the tool dependencies using conda:
conda install perl-lwp-simple perl-lwp-useragent perl-uri-url perl-soap-lite perl-list-moreutils perl-text-csv perl perl-html-template
#To set an environment:
conda create -n tool-bank-hmdb perl-soap-lite perl-list-moreutils perl-json perl-html-template`
#To activate the environment:
. activate tool-bank-hmdb
```


Travis
------
[![Build Status](https://travis-ci.org/workflow4metabolomics/tool-bank-hmdb.svg?branch=master)](https://travis-ci.org/workflow4metabolomics/tool-bank-hmdb)

Test and Deploy with Confidence. Easily sync your GitHub projects with Travis CI and you'll be testing your code in minutes!

Historic contributors
---------------------
- Franck Giacomoni @fgiacomoni - [French Metabolomics and Fluxomics Infrastructure (MetaboHUB)](http://www.metabohub.fr/en) - [La plateforme "Exploration du Métabolisme" (PFEM, Clermont-Ferrand)](http://www6.clermont.inra.fr/plateforme_exploration_metabolisme)
- Marion Landi - [LIFEGRID grant](http://www.lifegrid.fr/fr/home/le-pra-lifegrid.html) - [La plateforme "Exploration du Métabolisme" (PFEM, Clermont-Ferrand)](http://www6.clermont.inra.fr/plateforme_exploration_metabolisme)
