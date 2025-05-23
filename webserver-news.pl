#!/usr/bin/perl
use strict;
use feature 'say';
use Encode qw( encode_utf8 );
use JSON::XS qw( encode_json decode_json );
use DBI;
use DBD::SQLite::Constants ':dbd_sqlite_string_mode';
use DateTime;
use Template;
use Data::Dumper;
use List::Util qw( min );
use File::HomeDir;

#BEGIN { push @INC, '.' }
#use alphadumper;

my $homyak  = File::HomeDir->my_home;

use CGI::Fast
    socket_path => '*:9090',
    listen_queue => 5;

while (my $q = CGI::Fast->new) {
    eval {
        process_request($q);
    };
    if ( $@ ) { print $@ };
}

exit;

sub process_request {
    my ( $q ) = @_;

    if ( $q->script_name =~ /^\/news\/*$/ ) {
        print $q->header('text/html; charset=utf-8');
        print encode_utf8( gen_index() );
    }
    elsif ( $q->script_name =~ /^\/news\/+allitems\/*$/ ) {
        print $q->header('application/json; charset=utf-8');
        print encode_json( allitems() );
    }
    elsif ( $q->script_name =~ /^\/news.html\/*$/ ) {
        print $q->header('text/html; charset=utf-8');
        open FH, '<', 'news.html';
        print while <FH>;
    }
    else {
        print "Unknown route ".$q->script_name;
    }
}

sub allitems {
    my $dbh = DBI->connect(
        "dbi:SQLite:dbname=$homyak/.newsboat/cache.db",
        '', # usr
        '', # pwd
        { sqlite_string_mode => DBD_SQLITE_STRING_MODE_UNICODE_STRICT }
    ) or die "Couldn't connect: $@";
    #$dbh->trace(1);

    my $feeds = $dbh->selectall_hashref( 'SELECT rssurl, url, title, lastmodified, is_rtl, etag FROM rss_feed', 'rssurl' );
    #die alphadumper $feeds;

    our $local_tz = DateTime::TimeZone->new( name => 'local' );

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
            my $tdiff = time - $items->{$_}{pubDate};
            if ( $tdiff <= 20 * 60 ) { # 20 mins
                $items->{$_}{recency} = 'recent';
            }
            elsif ( $tdiff <= 60 * 60 ) { # 1 hour
                $items->{$_}{recency} = 'recent2';
            }
            elsif ( $tdiff <= 60 * 60 * 24 ) { # 1 day
                $items->{$_}{recency} = 'recentday';
            }

            if ( $rssurl =~ /youtube/ ) {
                $ytitems->{$_} = $items->{$_}
            }
            elsif ( $rssurl =~ /tg\.i-c-a\.su/ ) {
                next;
            }
            elsif ( $rssurl =~ /tgchnl2rss/ ) {
                $tgitems->{$_} = $items->{$_};
                $tgitems->{$_}{content} =~ s/(datetime="\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\+00:00">)\d\d:\d\d/${1}$items->{$_}{hdate}/;
            }
            elsif ( $rssurl =~ /smart-lab\./ ) {
                $slitems->{$_} = $items->{$_};
            }
            elsif ( $rssurl =~ /rbc/ ) {
                $rbitems->{$_} = $items->{$_}
            }
            else{
                $otitems->{$_} = $items->{$_};
            }
        }
    }

    my $now = DateTime->now(time_zone => $local_tz);

    return {
        page_gen_time => $now->ymd." ".$now->hms,
        tg_news => [
            map {
                {
                    id      => $_->{id},
                    hdate   => $_->{hdate},
                    content => $_->{content},
                    url     => $_->{url},
                    recency => $_->{recency},
                }
            } (
                sort { $b->{pubDate} <=> $a->{pubDate} or $a->{url} cmp $b->{url} }
                values %$tgitems
            )[0..min(100, keys(%$tgitems) - 1)]
        ],
        sl_news => [
            map {
                {
                    id      => $_->{id},
                    hdate    => $_->{hdate},
                    author   => ( $_->{author} =~ /https:..smart-lab.ru.my.([^\/]+).blog/ ),
                    title    => $_->{title},
                    content  => $_->{content} eq $_->{title} ? '' : $_->{content},
                    #content => substr($_->{content},0,1000),
                    url      => $_->{url},
                    recency  => $_->{recency},
                }
            } (
                sort { $b->{pubDate} <=> $a->{pubDate} or $a->{url} cmp $b->{url} }
                values %$slitems
            )[0..min(100, keys(%$slitems) - 1)]
        ],
        yt_news => [
            map {
                {
                    id      => $_->{id},
                    hdate   => $_->{hdate},
                    author  => $_->{author},
                    title   => $_->{title},
                    content => substr($_->{content},0,300),
                    url     => $_->{url},
                    recency => $_->{recency},
                }
            } (
                sort { $b->{pubDate} <=> $a->{pubDate} or $a->{url} cmp $b->{url} }
                values %$ytitems
            )[0..min(10, keys(%$ytitems) - 1)]
        ],
        ot_news => [
            map {
                {
                    id      => $_->{id},
                    hdate   => $_->{hdate},
                    author  => $_->{author},
                    title   => $_->{title},
                    content => $_->{content},
                    url     => $_->{url},
                    recency => $_->{recency},
                }
            } (
                sort { $b->{pubDate} <=> $a->{pubDate} or $a->{url} cmp $b->{url} }
                values %$otitems
            )[0..min(30, keys(%$otitems) - 1)]
        ],
    };
}

sub gen_index {
    my $tt = Template->new( { ENCODING => 'utf8' } );
    my $html_output = '';
    $tt->process(
        'template.tmpl',
        allitems(),
        \$html_output,
        { binmode => ':utf8' }
    );
    return $html_output;
}
