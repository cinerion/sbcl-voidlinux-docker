FROM ghcr.io/void-linux/void-linux:latest-thin-x86_64

RUN set -x \
    && xbps-install -Syu \
    && xbps-install -y bash sbcl curl wget gnupg libzstd-devel file-devel libmagic gcc libinotify-tools gzip make git tar \
    && sbcl --version

# /usr/bin/sh links to /usr/bin/dash in Void Linux
# but dash crashes when the docker image is loaded
# into Gitlab's CI pipeline. So we're linking to
# /usr/bin/bash instead.
RUN set -x \
    && rm /usr/bin/sh \
    && ln -sf /usr/bin/bash /usr/bin/sh

# Add the Quicklisp installer.
WORKDIR /usr/local/share/common-lisp/source/quicklisp/

ENV QUICKLISP_SIGNING_KEY D7A3489DDEFE32B7D0E7CC61307965AB028B5FF7

RUN set -x \
    && curl -fsSL "https://beta.quicklisp.org/quicklisp.lisp" > quicklisp.lisp \
    && curl -fsSL "https://beta.quicklisp.org/quicklisp.lisp.asc" > quicklisp.lisp.asc \
    && GNUPGHOME="$(mktemp -d)" \
    && export GNUPGHOME \
    && gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "${QUICKLISP_SIGNING_KEY}" \
    && gpg --batch --verify "quicklisp.lisp.asc" "quicklisp.lisp" \
    && rm quicklisp.lisp.asc \
    && rm -rf "$GNUPGHOME"

Clean a little bit
RUN set -x \
    && xbps-remove -y gnupg \
    && xbps-remove -yo \
    && rm -r /var/cache/xbps

# Add the script to trivially install Quicklisp and install it.
COPY install-quicklisp /usr/local/bin/install-quicklisp
RUN set -x \
    && QUICKLISP_ADD_TO_INIT_FILE=true /usr/local/bin/install-quicklisp


# Add the entrypoint
WORKDIR /

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["sbcl"]
