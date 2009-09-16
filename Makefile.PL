use inc::Module::Install;
name 'PSGIRPC';
all_from 'lib/PSGIRPC.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
