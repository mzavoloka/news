# Recommended way to build and run:
# sudo docker build -t news .
# sudo docker run -it -p 8181:80 news

FROM archlinux

RUN pacman -Sy && pacman -S --noconfirm \
    sudo wget newsboat \
    perl perl-json-xs perl-datetime perl-xml-rss perl-file-homedir \
    perl-dbi perl-dbd-sqlite perl-template-toolkit perl-cgi-fast \
    python python-pyrss2gen python-requests python-beautifulsoup4 python-lxml \
    nginx git npm

RUN ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime

COPY nginx.conf /etc/nginx/

RUN useradd zavoloka
RUN echo "zavoloka ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers

USER zavoloka
WORKDIR /home/zavoloka

RUN wget https://github.com/hufrea/byedpi/releases/download/v0.16.6/byedpi-16.6-x86_64.tar.gz
RUN tar xvf byedpi-16.6-x86_64.tar.gz
RUN chmod +x ciadpi-x86_64

RUN mkdir /home/zavoloka/.newsboat/
COPY .newsboat/urls /home/zavoloka/.newsboat/
COPY .newsboat/config /home/zavoloka/.newsboat/

COPY tgchnl2rss.py /home/zavoloka/
COPY 2ch-parser.pl /home/zavoloka/

#RUN mkdir ~/src
COPY webserver-news.pl /home/zavoloka/
RUN mkdir src
WORKDIR src
RUN git clone https://github.com/mzavoloka/news
WORKDIR news/vuenews
RUN npm i
RUN npm run build
WORKDIR /home/zavoloka/

#EXPOSE 80

#ENTRYPOINT ["/bin/bash"]
COPY entrypoint.sh /home/zavoloka/
ENTRYPOINT ["./entrypoint.sh"]
