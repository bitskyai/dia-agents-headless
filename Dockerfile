FROM alpine:3.11.0

LABEL maintainer="BitSky docker maintainers <help.bitskyai@gmail.com>"

ENV SCREENSHOT=false \
    HEADLESS=true \
    INST_SCRIPTS=/tmp/scripts \
    STARTUPDIR=/dockerstartup \
    PRODUCER_DIR=/home/alpine/producer \
    NGINX_DIR=/home/alpine/nginx \
    HEADLESS_PORT=8090 \
    NGINX_PORT=80

ENV VERSION=v12.18.1 NPM_VERSION=6 YARN_VERSION=latest

# ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

# Make sure all the user has same environment
COPY alpine/scripts/ ${INST_SCRIPTS}/
COPY alpine/config /etc/skel/.config
RUN find ${INST_SCRIPTS} -name '*.sh' -exec chmod a+x {} +

# Install latest Chromium
# Install libraries, like python, nodejs, yarn
# Install common tools, like vim 
RUN set -e \
    # && echo "http://dl-cdn.alpinelinux.org/alpine/edge/main" > /etc/apk/repositories \
    # && echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories \
    # && echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
    # && echo "http://dl-cdn.alpinelinux.org/alpine/v3.11/main" >> /etc/apk/repositories \
    && apk update \
    && apk upgrade \
    && apk add --update --no-cache --update-cache \
    xvfb \
    x11vnc \ 
    xfce4 \ 
    xfce4-terminal \ 
    paper-icon-theme \
    # arc-theme \
    libstdc++ \
    python \
    chromium \
    harfbuzz \
    nss \
    freetype \
    ttf-freefont \
    # wqy-zenhei \
    bash \
    sudo \
    htop \
    procps \
    curl \
    vim \
    nginx \
    make \
    gcc \
    g++ \
    linux-headers \
    binutils-gold \
    gnupg \
    nodejs \
    nodejs-npm \
    yarn \
    && rm -rf /var/cache/* \
    && mkdir /var/cache/apk

ENV CHROME_BIN=/usr/bin/chromium-browser \
    CHROME_PATH=/usr/lib/chromium/ \
    PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=1 \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser \
    PUPPETEER_USER_DATA_DIR=/home/alpine/.config/chromium 

RUN set -e \
  && mkdir -p /usr/share/wallpapers \
  && curl https://img1.goodfon.com/original/2560x1600/3/4a/mlechnyy-put-kosmos-zvezdy-3734.jpg -o /usr/share/wallpapers/mlechnyy-put-kosmos-zvezdy-3734.jpg \
  && echo "CHROMIUM_FLAGS=\"--disable-dev-shm-usage --no-sandbox --disable-gpu-sandbox --disable-gpu --window-position=0,0\"" >> /etc/chromium/chromium.conf \
  && addgroup alpine \
  && adduser -G alpine -s /bin/bash -D alpine \
  && echo "alpine:alpine" | /usr/sbin/chpasswd \
  && echo "alpine ALL=NOPASSWD: ALL" >> /etc/sudoers \
  && apk del curl 

ENV USER=alpine \
    DISPLAY=:1 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    HOME=/home/alpine \
    TERM=xterm \
    SHELL=/bin/bash \
    VNC_PASSWD=welcome \
    VNC_PORT=5900 \
    VNC_RESOLUTION=1024x768 \
    VNC_COL_DEPTH=24  \
    NOVNC_PORT=6090 \
    NOVNC_HOME=/home/alpine/noVNC 

RUN set -e \
  && sudo apk update \
  # && sudo apk add ca-certificates wget \
  # && sudo update-ca-certificates \
  && mkdir -p $NOVNC_HOME/utils/websockify \
  && wget -qO- https://github.com/novnc/noVNC/archive/v1.1.0.tar.gz | tar xz --strip 1 -C $NOVNC_HOME \
  && wget -qO- https://github.com/novnc/websockify/archive/v0.9.0.tar.gz | tar xzf - --strip 1 -C $NOVNC_HOME/utils/websockify \
  && chmod +x -v $NOVNC_HOME/utils/*.sh \
  && ln -s $NOVNC_HOME/vnc_lite.html $NOVNC_HOME/index.html \
  && sudo apk del wget
RUN mkdir -p /run/nginx

COPY alpine/run_novnc /usr/bin/  

WORKDIR $HOME
EXPOSE $VNC_PORT $NOVNC_PORT $HEADLESS_PORT $NGINX_PORT

# Copy all files for Headless producer    
COPY workers ${PRODUCER_DIR}/workers/
COPY producerConfigs.js ${PRODUCER_DIR}/
COPY index.js ${PRODUCER_DIR}/
COPY package.json ${PRODUCER_DIR}/
COPY server.js ${PRODUCER_DIR}/
COPY utils-docker.js ${PRODUCER_DIR}/utils.js
COPY package-lock.json ${PRODUCER_DIR}/
COPY README.md ${PRODUCER_DIR}/

# Copy nginx filea
COPY alpine/nginx ${NGINX_DIR}

### Install only production node_modules
RUN cd ${PRODUCER_DIR}/ && npm ci --only=production

COPY alpine/startup $STARTUPDIR
# RUN ${INST_SCRIPTS}/set_user_permission.sh $STARTUPDIR $HOME $NGINX_DIR
# RUN chown -R alpine:alpine $STARTUPDIR \
#   && chown -R alpine:alpine $HOME \
#   && chown -R alpine:alpine $NGINX_DIR

# USER alpine

# tmp swith to root user, otherwise cannot start nginx in heroku env
USER 0

ENTRYPOINT ["/dockerstartup/vnc_startup.sh"]
CMD ["--wait"]

# Metadata
LABEL bitsky.image.vendor="BitSky" \
    bitsky.image.url="https://www.bitsky.ai" \
    bitsky.image.title="BitSky Headless Producer" \
    bitsky.image.description="Response for excuting task that need to use chrome and send back to Retailer Service." \
    bitsky.image.documentation="https://docs.bitsky.ai"