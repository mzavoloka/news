package alphadumper;

use Data::Dumper;

use base 'Exporter';
our @EXPORT = qw( alphadumper );

=item
Same as uni::perl::dumper but dumps hash keys in sorted order and unfolds references.
Thus making it possible to see differences between similar but not equal data structures in your difftool.
=cut
sub alphadumper (@) { # got it from uni::perl::dumper::dumper_dd ...
	no strict 'refs';
    my $s = Data::Dumper->new([@_])
        ->Freezer('DUMPER_freeze')
        ->Terse(1)
        ->Indent(1)
        ->Purity(0)
        #->Useqq(1)   # ... and commented this ...
                      # makes russian letters appear as \321\202\320\265\320\272\321\201\321\202
        ->Quotekeys(0)
        ->Deepcopy(1) # ... and added this ...
        ->Sortkeys(1) # ... and this
        ->Dump;
    $s =~ s/\\x\{([a-f0-9]{1,4})\}/chr hex $1/sge;
    return $s;
}

1;
