use strict;
use warnings;
use List::Util 'uniq';
use Getopt::Long;
use Data::Printer;
use 5.010;



sub letterbox {
    
    my ( $A, $B, $C, $D ) = @_;
    
      return $D ? qr/
                    ^(?: (?&A)(?=(?&B)|(?&C)|(?&D)|$)
                       | (?&B)(?=(?&A)|(?&C)|(?&D)|$)
                       | (?&C)(?=(?&A)|(?&B)|(?&D)|$)
                       | (?&D)(?=(?&A)|(?&B)|(?&C)|$) )+$
                    (?(DEFINE)
                      (?<A> [$A] )
                      (?<B> [$B] )
                      (?<C> [$C] )
                      (?<D> [$D] ) )
                    /ix
           : $C ? qr/
                    ^(?: (?&A)(?=(?&B)|(?&C)|$)
                       | (?&B)(?=(?&A)|(?&C)|$)
                       | (?&C)(?=(?&A)|(?&B)|$) )+$
                    (?(DEFINE)
                      (?<A> [$A] )
                      (?<B> [$B] )
                      (?<C> [$C] ) )
                    /ix
           :      qr/
                    ^(?: (?&A)(?=(?&B))|$)
                       | (?&B)(?=(?&A))|$) )+$
                    (?(DEFINE)
                      (?<A> [$A] )
                      (?<B> [$B] ) )
                    /ix
    # /
      # ^
      # (?:
        # (?&A)(?=(?&B)|(?&C)|(?&D))
      # | (?&B)(?=(?&A)|(?&C)|(?&D))
      # | (?&C)(?=(?&A)|(?&B)|(?&D))
      # | (?&D)(?=(?&A)|(?&B)|(?&C))
      # )+(?:(?&A)|(?&B)|(?&C)|(?&D))$
      # (?(DEFINE)
        # (?<A> [PUH] )
        # (?<B> [OFI] )
        # (?<C> [BSL] )
        # (?<D> [EMN] )
      # )
    # /ix
}

sub match_all {
 
    state %seen;
    my $key = "@{[sort @_]}";
    if ( ! exists $seen{$key} ) {
        my $r = join '' => map "(?=.*?$_)", @_;
        $seen{$key} = qr/^$r/i
    }
    
    return $seen{$key}
}

sub first_letter { uc substr $_[0], 0, 1 }
sub last_letter { uc substr $_[0], length($_[0])-1 }
sub repeats { length($_[0]) - unique($_[0]) }
sub unique { uniq(map uc, split //, $_[0]) }
sub all_unique { ! repeats( $_[0] ) }

sub contains_all {
    
    my ($word, $missing) = @_;
    my $bool = 1;
    for ( @$missing ) {
        $bool &&= $word =~ /$_/i ;
        return unless $bool;
    }
    return 1;
}

sub recursive_search {
    
    my ( $words, $sides, $so_far ) = @_ ;
    
    my $letterboxable = letterbox( @$sides );
    my @candidates = grep /$letterboxable/, @$words ;
    
}

my ( $pairs, $list_words, $recursive );
my $source = 'words_nyt.txt';
GetOptions(
    'pairs' => sub { $pairs = 1 },
    'words' => sub { $list_words = 1 },
    'recursive' => sub { $recursive = 1 },
    'source=s' => \$source,
);

my $letterboxable = letterbox( @ARGV );
my @letters = map {split //, $_} @ARGV;
my (%score, %starts_with);

open my $words, '<', $source or die $!;
while (<$words>) {
    
    chomp;
    
    if ( /$letterboxable/ && length > 2) {
        my $word = $_;
        my @missing = grep { ! /[$word]/i } @letters;
        
        my $first_letter = first_letter( $word );
        my $last_letter = last_letter( $word );
        $starts_with{$first_letter} //= [];
        push @{ $starts_with{$first_letter} }, $word;
        
        $score{$word}{first} = $first_letter;
        $score{$word}{length} = length;
        $score{$word}{repeats} = repeats($word);
        $score{$word}{score} = unique($word);
        $score{$word}{missing} = [ @missing ];
        $score{$word}{last} = $last_letter;
    }
}
close $words or die $!;

my @candidates = keys %score;

if ( $pairs ) {
    
    for my $word ( @candidates ) {
        
        my ( $last, $missing ) = @{ $score{$word}}{ qw<last missing> };
        
        my $match = match_all( @$missing );
        # print $match, "\n";
        # my @next = grep contains_all($_, $missing), @{ $starts_with{$last} };
        my @next = grep /$match/, @{ $starts_with{$last} };
        $score{$word}{next} = [ @next ];
        $score{$word}{has_next} = !! @next;
        
        if ( $score{$word}{has_next} ) {
            
            my $next_word = ( sort {  $score{$a}{repeats} <=> $score{$b}{repeats}
                                || $score{$a}{length} <=> $score{$b}{length} } @{$score{$word}{next}} )[0];
            $score{$word}{next_word} = $next_word;
            $score{$word}{net_score} = $score{$word}{repeats} + $score{$next_word}{repeats}
                                    + $score{$word}{length}  + $score{$next_word}{length}
                                    - unique( $word . $next_word);
        }
    }
    
    # Report out
    
    print join( "\t" => qw< word next_word net_score > ) => "\n";
    for my $word ( sort { $score{$a}{net_score} <=> $score{$b}{net_score} }
                    grep $score{$_}{has_next},
                    @candidates
                ) {
        
        print join( "\t" => $word, map $score{$word}{$_}, qw< next_word net_score > ) => "\n";
    }
}

if ( $list_words ) {
    
    print join( "\t" => qw< word length score repeats missing> ) => "\n";
    for my $word ( sort { $score{$b}{score} <=> $score{$a}{score} || $score{$b}{length} <=> $score{$a}{length} } grep $score{$_}{score} >= 5, @candidates ) {
        
        print join( "\t" => $word,
                            map( $score{$word}{$_}, qw< length score repeats >),
                            join( '' => @{$score{$word}{missing}} )
                  ) => "\n";
    }
}

if ( $recursive ) {
    
    recursive_search( \@candidates, \@ARGV );
    
    my @no_repetitions = grep $score{$_}{repeats} == 0, keys %score;
    print 0+@no_repetitions, " words without repeating letters\n";
    
    my %links;
    for my $word ( sort @no_repetitions ) {
        print $word, "\n";
        my $first = $score{$word}{first};
        my $last = $score{$word}{last};
        my $missing = join '' => sort @{ $score{$word}{missing} };
        $links{$first}{$last}{$missing}++;
    }
    
    my @from = sort keys %links;
    my @to = sort( uniq( map keys %{$links{$_}}, @from ) );
    
    # print join( "\t" => '', @from ), "\n";
    # for my $to ( @to ) {
        # print join "\t" => $to, map { exists $links{$_}{$to} ? 'X' : '' } @from ;
        # print "\n";
    # }
    
    for my $from ( keys %links ) {
        for my $to ( keys %{ $links{$from} } ) {
            for my $missing ( keys %{ $links{$from}{$to} } ) {
                
                my @needed = ( $to, split //, $missing );
                my $needed = match_all( @needed );
                my @possible = grep /$needed/, @no_repetitions;
                if ( @possible ) {
                    print "From: $from , To: $to, Possible: @possible\n";
                }
            }
        }
    }
}