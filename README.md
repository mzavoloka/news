News aggregator based on newsboat. Gathers news from many sources and shows them on one html page. 
TODO add presentable screenshot here

Each minute the running instance of newsboat https://github.com/newsboat/newsboat is gathering news
to SQLite db file (usually present in ~/.newsboat/cache.db) via parsers converting html pages to RSS
feeds (like 2ch-parser.pl and tgchnl2rss.py).
Perl script webserver-news.pl connects to cache.db file to form a JSON api method that is available
to Vue app (that is calling 'allitems' method each 5 seconds). 'Mark all as read' button on top of the
page puts items' ids to localstorage making them rendered as more opaque.

TODO move newsboat config to this project
TODO put newsboat schema sample to this project
TODO move nginx config to this project
TODO archive older html-only version
