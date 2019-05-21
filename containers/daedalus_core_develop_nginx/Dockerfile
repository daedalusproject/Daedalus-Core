FROM daedalusproject/base_nginx_daedalus_light:201904300501
MAINTAINER Álvaro Castellano Vela <alvaro.castellano.vela@gmail.com>

COPY containers/daedalus_core_develop_nginx/nginx/vhost /etc/nginx/sites-enabled/default
COPY containers/daedalus_core_develop_nginx/nginx/nginx.conf /etc/nginx/nginx.conf

USER www-data

EXPOSE 80

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]
