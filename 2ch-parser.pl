#!/usr/bin/perl
use strict;
use feature 'say';

BEGIN { push @INC, '.' }
#use alphadumper;

use JSON::XS;
use DateTime;
use XML::RSS;

my $domen;
$domen = '2ch.life';
$domen = '2ch.hk';

my $content = `curl --silent 'https://$domen/news/catalog.json'`
    or die "Empty curl output";

#my $json = eval { JSON::decode_json( $content ) };
my $json = eval { JSON::XS->new->utf8->decode( $content ) };
die "Error parsing 2ch response: $@" if $@;
die "No threads found" unless $json->{threads}->@*;

my @hot_threads =
sort { $b->{ts} <=> $a->{ts} }
map {
    {
        id    => $_->{num},
        url   => "https://$domen/news/res/$_->{num}.html",
        ts    => $_->{timestamp},
        dt    => DateTime->from_epoch($_->{timestamp}),
        title => $_->{subject},
        text  => $_->{comment},
        views => $_->{views},
        comments => $_->{posts_count},
        files => [ map { "https://$domen/$_->{path}" } $_->{files}->@* ],
    }
}
grep {
    not $_->{closed}
    and ( $_->{posts_count} >= 60 and $_->{views} >= 2300
          or $_->{views} >= 2700 )
} $json->{threads}->@*;

# TODO suggested_source


my $rss = XML::RSS->new(
    version => '2.0',
    #encode_output => 0,
);
$rss->channel(
    title => '2ch hot news',
    link => "https://$domen/news",
	pubDate	=> DateTime->now,
    lastBuildDate => DateTime->now,
);

binmode STDOUT, ":utf8";
for ( @hot_threads ) {
    #say "-------------------------------------------------";
    #say "Url: $_->{url}";
    #say "Date: ".$_->{dt}->datetime(' ');
    #say "Title: $_->{title}";
    #say "Text: ".substr($_->{text}, 0, 250);
    #say "Comments: $_->{comments}";
    #say "Views: $_->{views}";

    $rss->add_item(
        permaLink => $_->{url},
        title => sprintf(
            "Comments: %03d Views: %05s Title: %s",
            $_->{comments},
            $_->{views},
            $_->{title}
        ),
        pubDate => $_->{dt},
        description => $_->{text}.
            "<br><br>Files:".join( '', map { "<br><a href='$_'>$_</a>" } $_->{files}->@* ),
    );
}

#$rss->save('2ch-hot-news.rdf');
say $rss->as_string; # for newsboat
