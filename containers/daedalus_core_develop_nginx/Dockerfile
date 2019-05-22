FROM daedalusproject/base_nginx_daedalus_light:201904300501
MAINTAINER Álvaro Castellano Vela <alvaro.castellano.vela@gmail.com>

COPY containers/daedalus_core_develop_nginx/nginx/vhost /etc/nginx/sites-enabled/default
COPY containers/daedalus_core_develop_nginx/nginx/nginx.conf /etc/nginx/nginx.conf

RUN chown -R www-data:www-data /var/lib/nginx \
    && mkdir -p /var/run/nginx \
    && chown www-data:www-data /var/run/nginx \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

USER www-data

EXPOSE 8080

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]
