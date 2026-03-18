#!/usr/bin/perl
use v5.40;
use mylib::oneline;
use HTML::TreeBuilder;
use XML::RSS;
use Encode qw(encode_utf8 decode_utf8);
use DateTime;
use DateTime::Format::Strptime;

my $strp = DateTime::Format::Strptime->new(
    pattern => '%Y %d %b, %H:%M',
    locale	 => 'en_US', # to parse Mar, Feb, etc.
);

my $channel_name = $ARGV[0] or die "No channel name arg provided";
my $channel_url = "https://tgstat.ru/channel/\@$channel_name";
my $cmd = oneline " curl '$channel_url'
  --silent
  --cookie-jar
  --compressed
  -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:145.0) Gecko/20100101 Firefox/145.0'
  -H 'Upgrade-Insecure-Requests: 1'";
say $cmd if $ENV{DEBUG};
my $content = `$cmd`;
say $content if $ENV{DEBUG};

my $tree = HTML::TreeBuilder->new_from_content(decode_utf8 $content);
my ( $posts_list ) = $tree->look_down(_tag => 'div', class => qr/\bposts-list\b/)
    or die $tree->as_HTML()."\nERROR Didnt find posts list";
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
    $post->id =~ /post-(\d+)/;
    my $tgstat_id = $1;

    my $text = $post->look_down(_tag => 'div', class => qr/\bpost-text\b/);

    my $last_a = ( $post->look_down(_tag => 'a') )[-1];
    my $post_url = 'https://tgstat.ru'.$last_a->attr('href');

    my $post_header = $post->look_down(_tag => 'div', class => qr/\bpost-header\b/);
    my $post_ts = $post_header->look_down(_tag => 'p', class => qr/\btext-muted\b/);
    my $post_date = $strp->parse_datetime(
        DateTime->now()->year.' '.$post_ts->as_text);

    $rss->add_item(
        permaLink => $post_url,
        title => $post_url,
        pubDate => $post_date,
        #description => decode_utf8($text->as_text),
        #description => $text->as_text,
        description => $text->as_HTML,
    );
}

say $rss->as_string; # for newsboat
