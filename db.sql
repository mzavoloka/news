-- In newsboat cache.db file
CREATE INDEX idx_feedurl_pubDate ON rss_item(feedurl, pubDate);
