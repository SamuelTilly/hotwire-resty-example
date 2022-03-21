FROM openresty/openresty:1.19.9.1-alpine-fat as builder

ARG RESTY_VERSION="1.19.9.1"
ARG NCHAN_VERSION="1.2.15"
ARG RESTY_J="1"

# Should be able to collect this using $(openresty -V) instead
ARG RESTY_CONFIG_OPTIONS="\
  --with-compat \
  --with-file-aio \
  --with-http_addition_module \
  --with-http_auth_request_module \
  --with-http_dav_module \
  --with-http_flv_module \
  --with-http_geoip_module=dynamic \
  --with-http_gunzip_module \
  --with-http_gzip_static_module \
  --with-http_image_filter_module=dynamic \
  --with-http_mp4_module \
  --with-http_random_index_module \
  --with-http_realip_module \
  --with-http_secure_link_module \
  --with-http_slice_module \
  --with-http_ssl_module \
  --with-http_stub_status_module \
  --with-http_sub_module \
  --with-http_v2_module \
  --with-http_xslt_module=dynamic \
  --with-ipv6 \
  --with-mail \
  --with-mail_ssl_module \
  --with-md5-asm \
  --with-pcre-jit \
  --with-sha1-asm \
  --with-stream \
  --with-stream_ssl_module \
  --with-threads \
  "

ARG _RESTY_CONFIG_DEPS="--with-pcre \
  --with-cc-opt='-DNGX_LUA_ABORT_AT_PANIC -I/usr/local/openresty/pcre/include -I/usr/local/openresty/openssl/include' \
  --with-ld-opt='-L/usr/local/openresty/pcre/lib -L/usr/local/openresty/openssl/lib -Wl,-rpath,/usr/local/openresty/pcre/lib:/usr/local/openresty/openssl/lib' \
  "

RUN apk add --no-cache \
  build-base \
  coreutils \
  curl \
  gd-dev \
  geoip-dev \
  libxslt-dev \
  linux-headers \
  make \
  perl-dev \
  readline-dev \
  zlib-dev

RUN cd /tmp \
  && curl -fSL https://openresty.org/download/openresty-${RESTY_VERSION}.tar.gz -o openresty-${RESTY_VERSION}.tar.gz \
  && curl -fSL https://github.com/slact/nchan/archive/v${NCHAN_VERSION}.tar.gz -o nchan-${NCHAN_VERSION}.tar.gz \
  && tar xzf nchan-${NCHAN_VERSION}.tar.gz \
  && tar xzf openresty-${RESTY_VERSION}.tar.gz \
  && cd /tmp/openresty-${RESTY_VERSION} \
  && eval ./configure -j${RESTY_J} ${_RESTY_CONFIG_DEPS} ${RESTY_CONFIG_OPTIONS} \
  --add-dynamic-module=/tmp/nchan-${NCHAN_VERSION} \
  && make -j${RESTY_J} && make -j${RESTY_J} install

FROM openresty/openresty:1.19.9.1-alpine-fat

RUN apk add --no-cache openssl-dev && \
  luarocks install lua-resty-http && \
  luarocks install lua-resty-template && \
  luarocks install router

COPY --from=builder /usr/local/openresty/nginx/modules/ngx_nchan_module.so /usr/local/openresty/nginx/modules/ngx_nchan_module.so
RUN sed -i '33s;^;load_module "modules/ngx_nchan_module.so"\;\n;' /usr/local/openresty/nginx/conf/nginx.conf

WORKDIR /app
