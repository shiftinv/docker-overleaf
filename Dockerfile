# ---------------------------------------------
# Overleaf Community Edition (overleaf/overleaf)
# ---------------------------------------------

FROM phusion/baseimage:0.11

ENV baseDir .


# ------------
#  BASE IMAGE
# ------------

# Install Node + other dependencies
# --------------------
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - \
 && apt-get update \
 && apt-get install -y nodejs sudo build-essential wget net-tools unzip time imagemagick optipng strace nginx git python zlib1g-dev libpcre3-dev aspell aspell-* \
 && apt-get clean \
 && find /var/lib/apt/lists/ /tmp/ /var/tmp/ -mindepth 1 -maxdepth 1 -exec rm -rf "{}" + \
 && rm /etc/nginx/sites-enabled/default


# Install Node6 (required by some services)
# -----------------------------------------
RUN cd /opt \
 && wget https://nodejs.org/dist/v6.17.1/node-v6.17.1-linux-x64.tar.gz \
 && mkdir -p /opt/nodejs \
 && tar -xzf node-v6.17.1-linux-x64.tar.gz -C /opt/nodejs/ \
 && rm node-v6.17.1-linux-x64.tar.gz \
 && cd /opt/nodejs \
 && mv node-v6.17.1-linux-x64 6.17.1\
 && ln -s /opt/nodejs/6.17.1/bin/node /usr/bin/node6


# Set up sharelatex user and home directory
# -----------------------------------------
RUN adduser --system --group --home /var/www/sharelatex --no-create-home sharelatex \
 && mkdir -p /var/lib/sharelatex \
 && chown www-data:www-data /var/lib/sharelatex \
 && mkdir -p /var/log/sharelatex \
 && chown www-data:www-data /var/log/sharelatex \
 && mkdir -p /var/lib/sharelatex/data/template_files \
 && chown www-data:www-data /var/lib/sharelatex/data/template_files



# ------------
#  MAIN IMAGE
# ------------

# Install app settings files
# --------------------------
ADD ${baseDir}/settings.coffee /etc/sharelatex/settings.coffee
ENV SHARELATEX_CONFIG /etc/sharelatex/settings.coffee


# Copy build dependencies
# -----------------------
ADD ${baseDir}/git-revision.sh /var/www/git-revision.sh
ADD ${baseDir}/services.js /var/www/sharelatex/config/services.js

# Checkout Overleaf Community Edition repo
# ----------------------------------------
RUN cd /var/www/sharelatex \
 && mv config /tmp/ \
 && git clone https://github.com/overleaf/overleaf.git . \
 && git checkout deb1ca36391c71cfec3720ddd9181e0f8be89101 \
 && mv /tmp/config/services.js config/ \
 \
# Checkout services
# -----------------
RUN cd /var/www/sharelatex \
&&    npm install \
&&    grunt install \
  \
# Cleanup not needed artifacts
# ----------------------------
&&  rm -rf /root/.cache /root/.npm $(find /tmp/ -mindepth 1 -maxdepth 1) \
# Stores the version installed for each service
# ---------------------------------------------
&&  cd /var/www \
&&    ./git-revision.sh > revisions.txt \
  \
# Cleanup the git history
# -------------------
&&  rm -rf $(find /var/www/sharelatex -name .git)

# Install npm dependencies
# ------------------------
RUN cd /var/www/sharelatex \
&&    bash ./bin/install-services \
  \
# Cleanup not needed artifacts
# ----------------------------
&&  rm -rf /root/.cache /root/.npm $(find /tmp/ -mindepth 1 -maxdepth 1)

# Compile CoffeeScript
# --------------------
RUN cd /var/www/sharelatex \
&&    bash ./bin/compile-services

# Links CLSI sycntex to its default location
# ------------------------------------------
RUN ln -s /var/www/sharelatex/clsi/bin/synctex /opt/synctex


# Copy runit service startup scripts to its location
# --------------------------------------------------
ADD ${baseDir}/runit /etc/service


# Configure nginx
# ---------------
ADD ${baseDir}/nginx/nginx.conf /etc/nginx/nginx.conf
ADD ${baseDir}/nginx/sharelatex.conf /etc/nginx/sites-enabled/sharelatex.conf


# Configure log rotation
# ----------------------
ADD ${baseDir}/logrotate/sharelatex /etc/logrotate.d/sharelatex


# Copy Phusion Image startup scripts to its location
# --------------------------------------------------
COPY ${baseDir}/init_scripts/ /etc/my_init.d/

# Copy app settings files
# -----------------------
COPY ${baseDir}/settings.coffee /etc/sharelatex/settings.coffee

# Set Environment Variables
# --------------------------------
ENV WEB_API_USER "sharelatex"

ENV SHARELATEX_APP_NAME "Overleaf Community Edition"


EXPOSE 80

WORKDIR /

ENTRYPOINT ["/sbin/my_init"]


##### Hotfix 2.0.2
# Patch 1: Fixes anonymous link sharing
ADD hotfix/2.0.2/1-anon-upload.patch /var/www/sharelatex/web/app/src/Features/Uploads/1-anon-upload.patch
RUN cd /var/www/sharelatex/web/app/src/Features/Uploads/ && \
    patch < 1-anon-upload.patch


# Patch 2: Fixes read-only access
ADD hotfix/2.0.2/2-read-only-access.patch /var/www/sharelatex/web/app/src/Features/TokenAccess/3-read-only-access.patch
RUN cd /var/www/sharelatex/web/app/src/Features/TokenAccess/ && \
    patch < 3-read-only-access.patch


# Patch 3: Fixes url linking
ADD hotfix/2.0.2/3-url-linking-1.patch /var/www/sharelatex/web/app/src/infrastructure/6-url-linking-1.patch
RUN cd /var/www/sharelatex/web/app/src/infrastructure/ && \
    patch < 6-url-linking-1.patch
ADD hotfix/2.0.2/4-url-linking-2.patch /var/www/sharelatex/web/app/views/project/editor/7-url-linking-2.patch
RUN cd /var/www/sharelatex/web/app/views/project/editor/ && \
    patch < 7-url-linking-2.patch


# Patch 4: Disables analytics
ADD hotfix/2.0.2/5-disable-analytics-1.patch /var/www/sharelatex/web/app/src/Features/Analytics/8-disable-analytics-1.patch
RUN cd /var/www/sharelatex/web/app/src/Features/Analytics/ && \
    patch < 8-disable-analytics-1.patch
ADD hotfix/2.0.2/6-disable-analytics-2.patch /var/www/sharelatex/web/app/src/infrastructure/9-disable-analytics-2.patch
RUN cd /var/www/sharelatex/web/app/src/infrastructure/ && \
    patch < 9-disable-analytics-2.patch
