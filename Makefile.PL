use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Dancer::Plugin::Filter',
    AUTHOR       => 'Edward Allen (ealleniii _at_ cpan _dot_ org)',
    VERSION_FROM        => 'lib/Dancer/Plugin/Filter.pm',
    ABSTRACT            => 'YOUR APPLICATION ABSTRACT',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Dancer'     => 1.1806_01,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
