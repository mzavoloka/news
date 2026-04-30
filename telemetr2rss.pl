#!/usr/bin/perl
use v5.40;
use utf8;
use HTML::TreeBuilder;
use XML::RSS;
use Encode qw(encode_utf8 decode_utf8);
use DateTime;
use DateTime::Format::Strptime;

sub ol($s) { $s =~ s/\s+/ /gr } # r modifier to return result

my $strp = DateTime::Format::Strptime->new(
    pattern => '%d.%m.%Y %H:%M',
    locale	 => 'en_US', # to parse Mar, Feb, etc.
);

my $channel_name = $ARGV[0] or die "No channel name arg provided";
my $channel_url = "https://telemetr.me/content/\@$channel_name";
my $cmd = ol"curl '$channel_url'
  --silent
  --cookie-jar /tmp/telemetr2rss-cookie-jar.txt
  --compressed
  -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:145.0) Gecko/20100101 Firefox/145.0'
  -H 'Upgrade-Insecure-Requests: 1'";
say $cmd if $ENV{DEBUG};
my $content = `$cmd`;
say $content if $ENV{DEBUG};

my $tree = HTML::TreeBuilder->new_from_content(decode_utf8 $content);
my ( $posts_list ) = $tree->look_down(_tag => 'div', class => qr/\bpost-list\b/)
    or die $tree->as_HTML()."\nERROR Didnt find post-list";
my @posts = $posts_list->content_list();

my $rss = XML::RSS->new(
    version => '2.0',
    #encode_output => 0, # NOTE maybe comment it
);
$rss->channel(
    title => $channel_name,
    link => $channel_url,
    pubDate => DateTime->now,
    lastBuildDate => DateTime->now,
);

for my $post ( @posts ) {
    my $header = $post->look_down(_tag => 'div', class => qr/\bpost-card__header\b/)
        or next; # skips "Смотреть все посты"
    my $body = $post->look_down(_tag => 'div', class => qr/\bpost-card__body\b/);
    my $hdate = $header->look_down(_tag => 'a', class => qr/\bpost-card__header-date\b/);
    $hdate->as_text =~ /Пост от (\d\d\.\d\d.\d\d\d\d \d\d:\d\d)/;
    my $post_date = $strp->parse_datetime($1);

    $rss->add_item(
        permaLink => "$channel_name-$post_date",
        title => "$channel_name-$post_date",
        pubDate => $post_date,
        description => "<h4>$channel_name-$post_date</h4>".$body->as_HTML,
    );
}

say $rss->as_string; # for newsboat
