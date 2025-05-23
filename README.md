### What is
News aggregator based on newsboat. Gathers news from many sources and shows them on one webpage in
chronological order. 
![Sample screenshot 2025-05-16](img/Screenshot_2025-05-16_20-11-02.png?raw=true "Sample screenshot 2025-05-16")

### Installation
To run on your machine, build docker image from project's folder:
```
sudo docker build -t news .
```
And then run container (will need vacant 8181 port on your machine):
```
sudo docker run -it -p 8181:80 news
```
Then the project will be availabe at http://localhost:8181/news/vue

### How it works
Each minute the running instance of newsboat https://github.com/newsboat/newsboat is gathering news
to SQLite db file (usually present in ~/.newsboat/cache.db) via parsers converting html pages to RSS
feeds (like 2ch-parser.pl and tgchnl2rss.py).
Perl script webserver-news.pl connects to cache.db file to form a JSON api method that is available
to Vue app (that is calling 'allitems' method each 5 seconds). 'Mark all as read' button on top of the
page puts items' ids to localstorage making them rendered as more opaque. Hovering mouse on top of
any news card expands it.

- TODO archive older html-only version
