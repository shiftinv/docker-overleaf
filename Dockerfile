# ---------------------------------------------
# Overleaf Community Edition (overleaf/overleaf)
# ---------------------------------------------

FROM sharelatex/sharelatex-base:latest

ENV baseDir .


# Install app settings files
# --------------------------
ADD ${baseDir}/settings.coffee /etc/sharelatex/settings.coffee
ENV SHARELATEX_CONFIG /etc/sharelatex/settings.coffee


# Install dependencies needed to run configuration scripts
# --------------------------------------------------------
ADD ${baseDir}/package.json /var/www/package.json
ADD ${baseDir}/git-revision.js /var/www/git-revision.js

# Replace overleaf/config/services.js with the list of available 
# services in Overleaf Community Edition
# --------------------------------------------------------------
ADD ${baseDir}/services.js /var/www/sharelatex/config/services.js

# Checkout Overleaf Community Edition repo
# ----------------------------------------
RUN cd /var/www/sharelatex \
 && mv config /tmp/ \
 && git clone https://github.com/overleaf/overleaf.git . \
 && git checkout deb1ca36391c71cfec3720ddd9181e0f8be89101 \
 && mv /tmp/config/services.js config/ \

# Checkout services
# -----------------
 && cd /var/www \
 && npm install -g grunt-cli \
 && npm install \
 && cd /var/www/sharelatex \
 && npm install \
 && grunt install \

# install and compile services
# ----------------------------
 && bash bin/install-services \
 && bash bin/compile-services \

# Links CLSI synctex to its default location
# ------------------------------------------
 && ln -s /var/www/sharelatex/clsi/bin/synctex /opt/synctex \

# Change application ownership to www-data
# ----------------------------------------
 && chown -R www-data:www-data /var/www/sharelatex \

# Stores the version installed for each service
# ---------------------------------------------
 && cd /var/www \
 && node git-revision > revisions.txt \

# Clean up caches/tmp/git/etc.
# ------------------------
 && rm -rf /root/.node-gyp /root/.npm /var/www/node_modules \
 && find /tmp/ /var/tmp/ -mindepth 1 -maxdepth 1 -exec rm -rf {} + \
 && find /var/www/sharelatex -name ".git" -exec rm -rf "{}" +


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


EXPOSE 80

WORKDIR /

ENTRYPOINT ["/sbin/my_init"]

