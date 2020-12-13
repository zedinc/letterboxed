use strict;
use warnings;
use Getopt::Long;

my $encrypt;

GetOptions(
    'encrypt' => sub { $encrypt = 1 },
    'decrypt' => sub { $encrypt = 0 },
);

if ( $encrypt ) {
    print join ' ' => map { unpack 'B8', $_ } split //, join '' => @ARGV;
}
else {
    print pack 'B*', $_ for @ARGV;
}
