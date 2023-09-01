#!/usr/bin/perl
use HTML::Template;
use DBI;
use strict;
use feature 'say';

BEGIN { push @INC, '.' }
use alphadumper;

my $dbh = DBI->connect("dbi:SQLite:dbname=$ENV{HOME}/.newsboat/cache.db") or die "Couldn't connect: $@";
#$dbh->trace(1);

my $feeds = $dbh->selectall_hashref( 'SELECT rssurl, url, title, lastmodified, is_rtl, etag FROM rss_feed', 'rssurl' );
#die alphadumper $feeds;

my $ytitems = {};
my $tgitems = {};
my $slitems = {};
my $otitems = {};
my $rbitems = {};
for my $rssurl ( keys %$feeds ) {
    my $items = $dbh->selectall_hashref(
        "SELECT
            id,
            guid,
            title,
            author,
            url,
            feedurl,
            pubDate,
            datetime( pubDate, 'unixepoch', 'localtime' ) as hdate,
            content
        FROM rss_item
        WHERE feedurl = ?
        ORDER BY pubDate desc
        LIMIT 100",
        'url', #'id'
        {},
        $rssurl,
    );
    for ( keys %$items ) {
        if ( $rssurl =~ /youtube/ ) {
            $ytitems->{$_} = $items->{$_}
        }
        elsif ( $rssurl =~ /tg\.i-c-a\.su/ ) {
            next;
        }
        elsif ( $rssurl =~ /tgchnl2rss/ ) {
            $tgitems->{$_} = $items->{$_}
        }
        elsif ( $rssurl =~ /smart-lab\./ ) {
            $slitems->{$_} = $items->{$_}
        }
        elsif ( $rssurl =~ /rbc/ ) {
            $rbitems->{$_} = $items->{$_}
        }
        else{
            $otitems->{$_} = $items->{$_}
        }
    }
}

my $tmpl = HTML::Template->new(filename => 'template.tmpl');



$tmpl->param(
    TG => 'Telegram',
    TG_NEWS => [
        map {
            {
                hdate => $_->{hdate},
                content => $_->{content},
                url     => $_->{url},
            }
        } (
            sort { $b->{pubDate} <=> $a->{pubDate} }
            values %$tgitems
        )[0..200]
    ],
    SL => 'Smartlab',
    SL_NEWS => [
        map {
            {
                hdate => $_->{hdate},
                author => $_->{author},
                title => $_->{title},
                content => $_->{content} eq $_->{title} ? '' : $_->{content},
                #content => substr($_->{content},0,1000),
                url     => $_->{url},
            }
        } (
            sort { $b->{pubDate} <=> $a->{pubDate} }
            values %$slitems
        )[0..100]
    ],
    YT => 'Youtube',
    YT_NEWS => [
        map {
            {
                hdate => $_->{hdate},
                author => $_->{author},
                title => $_->{title},
                content => substr($_->{content},0,300),
                url     => $_->{url},
            }
        } (
            sort { $b->{pubDate} <=> $a->{pubDate} }
            values %$ytitems
        )[0..20]
    ],
    OT => 'Other',
    OT_NEWS => [
        map {
            {
                hdate => $_->{hdate},
                author => $_->{author},
                title => $_->{title},
                content => $_->{content},
                url     => $_->{url},
            }
        } (
            sort { $b->{pubDate} <=> $a->{pubDate} }
            values %$otitems
        )[0..200]
    ],
    #RB => 'RBC',
    #RB_NEWS => [
    #    map {
    #        {
    #            hdate => $_->{hdate},
    #            #author => $->{author},
    #            title => $_->{title},
    #            content => $_->{content},
    #            url     => $_->{url},
    #        }
    #    }
    #    sort { $b->{pubDate} <=> $a->{pubDate} }
    #    values %$rbitems
    #],
);
open( my $fh, '>', 'news.html' ) or die "Error opening file for writing";
print $fh $tmpl->output();
