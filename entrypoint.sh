#!/bin/bash
set -e
echo "ENTERING ENTRYPOINT"

# bypass dpi to gain access to youtube.com
./ciadpi-x86_64 -p 8080 -s0 -o1 -Ar -o1 -At -f-1 -r1+s -As --ttl 5 &

newsboat -x reload & # runs newsboat without ui in background

./webserver-news.pl &
sudo nginx -g "daemon off;" &

echo "LEAVING ENTRYPOINT"
/bin/bash
