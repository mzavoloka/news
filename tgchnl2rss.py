#!/usr/bin/python
import os
import sys
import re
from collections import namedtuple
from datetime import datetime
import PyRSS2Gen

import requests
from bs4 import BeautifulSoup

#from scripts.common import DEFAULT_REQUEST_TIMEOUT, DEFAULT_REQUEST_HEADERS
DEFAULT_REQUEST_TIMEOUT = 10
DEFAULT_REQUEST_HEADERS = {
    "User-Agent": "Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) "
                  "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 "
                  "Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
}

TELEGRAM_CHANNEL_WEBVIEW_PREFIX = "https://t.me/s/"
BACKGROUND_IMAGE_RE = re.compile("url\('(https://.+?)'\)")

TELEGRAM_MESSAGE_CLASS = ".tgme_widget_message"
TELEGRAM_MESSAGE_BUBBLE_CLASS = ".tgme_widget_message_bubble"
TELEGRAM_MESSAGE_TEXT_CLASS = ".tgme_widget_message_text"
TELEGRAM_MESSAGE_PHOTO_CLASS = ".tgme_widget_message_photo_wrap"
TELEGRAM_MESSAGE_DATE_CLASS = ".tgme_widget_message_date"

TelegramChannel = namedtuple("TelegramChannel", ["url", "name", "messages"])
TelegramMessage = namedtuple("TelegramMessage", ["url", "bubble", "text", "photo", "created_at"])

if len(sys.argv) < 2:
    print( "Usage: " + os.path.basename(__file__) + " tgchnl_name" )
    sys.exit("ERROR: No channel name specified in command line arguments")

tgchnl_name = sys.argv[1]

# Got from https://github.com/vas3k/infomate.club/blob/master/parsing/telegram/parser.py
def parse_channel(channel_name, only_text=False, limit=100) -> TelegramChannel:
    channel_url = TELEGRAM_CHANNEL_WEBVIEW_PREFIX + channel_name
    response = requests.get(
        url=channel_url,
        timeout=DEFAULT_REQUEST_TIMEOUT,
        headers=DEFAULT_REQUEST_HEADERS,
    )

    bs = BeautifulSoup(response.text, features="lxml")

    messages = []
    message_tags = bs.select(TELEGRAM_MESSAGE_CLASS)
    for message_tag in message_tags:
        message_bubble = None
        message_bubble_tag = message_tag.select(TELEGRAM_MESSAGE_BUBBLE_CLASS)
        if message_bubble_tag:
            message_bubble = str(message_bubble_tag[0])

        message_text = None
        message_text_tag = message_tag.select(TELEGRAM_MESSAGE_TEXT_CLASS)
        if message_text_tag:
            message_text = str(message_text_tag[0])

        message_photo = None
        message_photo_tag = message_tag.select(TELEGRAM_MESSAGE_PHOTO_CLASS)
        if message_photo_tag:
            message_photo = BACKGROUND_IMAGE_RE.search(str(message_photo_tag[0])).group(1)

        message_url = None
        message_time = datetime.utcnow()
        message_date_tag = message_tag.select(TELEGRAM_MESSAGE_DATE_CLASS)
        if message_date_tag:
            message_url = message_date_tag[0]["href"]
            message_datetime_tag = message_date_tag[0].select("time")
            if message_datetime_tag:
                message_time = datetime.strptime(message_datetime_tag[0]["datetime"][:19], "%Y-%m-%dT%H:%M:%S")

        messages.append(
            TelegramMessage(
                url=message_url,
                text=message_text,
                bubble=message_bubble,
                photo=message_photo,
                created_at=message_time,
            )
        )

    if only_text:
        messages = [m for m in messages if m.text]

    return TelegramChannel(
        url=channel_url,
        name=channel_name,
        messages=list(reversed(messages))[:limit],
    )


tgchnl = parse_channel( tgchnl_name )

rss = PyRSS2Gen.RSS2(
    title = tgchnl.name,
    link = tgchnl.url,
    description = tgchnl.name,
    pubDate = datetime.now(),
    lastBuildDate = datetime.now(),
)

for x in tgchnl.messages:
    rss.items.append(
        PyRSS2Gen.RSSItem(
            title = x.url,
            link = x.url,
            description = x.bubble,
            pubDate = x.created_at,
        )
    )

print( rss.to_xml(encoding='UTF-8') )
