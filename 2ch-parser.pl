#!/usr/bin/perl
use strict;
use feature 'say';
use utf8;

BEGIN { push @INC, '.' }
use alphadumper;

use JSON;
use DateTime;


my $content = `curl 'https://2ch.hk/news/catalog.json'`
    or die "Empty curl output";

my $json = eval { JSON::decode_json($content) };
die "Error parsing 2ch response: $@" if $@;
die "No threads found" unless $json->{threads}->@*;

my @hot_threads =
sort { $b->{ts} <=> $a->{ts} }
map {
    {
        id    => $_->{num},
        url   => "https://2ch.hk/news/res/$_->{num}.html",
        ts    => $_->{timestamp},
        dt    => DateTime->from_epoch($_->{timestamp}),
        title => $_->{subject},
        text  => $_->{comment},
        views => $_->{views},
        comments => $_->{posts_count},
    }
}
grep {
    not $_->{closed}
    and ( $_->{posts_count} >= 30 or $_->{views} >= 1000 )
} $json->{threads}->@*;

# TODO suggested_source

binmode STDOUT, ":utf8";
for ( @hot_threads ) {
    say "-------------------------------------------------";
    say "Url: $_->{url}";
    say "Date: ".$_->{dt}->datetime(' ');
    say "Title: $_->{title}";
    say "Text: ".substr($_->{text}, 0, 250);
    say "Comments: $_->{comments}";
    say "Views: $_->{views}";
}
