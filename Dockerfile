FROM debian:stretch

RUN apt-get -y update \
    && apt-get -y install \
    apt-transport-https \
    ca-certificates \
    wget

RUN wget -O "/etc/apt/trusted.gpg.d/php.gpg" "https://packages.sury.org/php/apt.gpg" \
    && sh -c 'echo "deb https://packages.sury.org/php/ stretch main" > /etc/apt/sources.list.d/php.list'

RUN apt-get -y update \
    && apt-get -y install \
    git \
    curl \
    php7.3 php7.3-common php7.3-cli php7.3-curl php7.3-dev php7.3-gd php7.3-intl php7.3-mysql php7.3-mbstring php7.3-xml php7.3-xsl php7.3-zip php7.3-json php7.3-xdebug php7.3-soap php7.3-bcmath \
    php7.2 php7.2-common php7.2-cli php7.2-curl php7.2-dev php7.2-gd php7.2-intl php7.2-mysql php7.2-mbstring php7.2-xml php7.2-xsl php7.2-zip php7.2-json php7.2-xdebug php7.2-soap php7.2-bcmath \
    php7.1 php7.1-common php7.1-cli php7.1-curl php7.1-dev php7.1-gd php7.1-intl php7.1-mysql php7.1-mbstring php7.1-xml php7.1-xsl php7.1-zip php7.1-json php7.1-xdebug php7.1-soap php7.1-bcmath \
    zip \
    && apt-get clean \
    && rm -rf \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/* \
    /usr/share/man \
    /usr/share/doc \
    /usr/share/doc-base

LABEL version="0.1.0"
LABEL repository="https://github.com/pinpoint-unsworth94/actions-phpcbf-m2"
LABEL homepage="https://github.com/pinpoint-unsworth94/actions-phpcbf-m2"
LABEL maintainer="Ben Unsworth <ben.unsworth@pinpointdesigns.co.uk>"

COPY "entrypoint.sh" "/entrypoint.sh"

RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
