FROM splitbrain/phpfarm:jessie

LABEL version="0.1.0"
LABEL repository="https://github.com/pinpoint-unsworth94/actions-phpcbf-m2"
LABEL homepage="https://github.com/pinpoint-unsworth94/actions-phpcbf-m2"
LABEL maintainer="Ben Unsworth <ben.unsworth@pinpointdesigns.co.uk>"

COPY "entrypoint.sh" "/entrypoint.sh"

ADD problem-matcher.json /problem-matcher.json

RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
