FROM alpine:3.12

ENV ALPINE_VERSION=3.12
ENV TIMEZONE=Asia/Shanghai

COPY github_hosts /tmp/
COPY Shanghai /etc/localtime

#### packages from https://pkgs.alpinelinux.org/packages
# These are always installed. Notes:
#   * dumb-init: a proper init system for containers, to reap zombie children
#   * bash: For entrypoint, and debugging
#   * tzdata: For timezone
#   * python3: the binaries themselves
#   * libnsl: for cx_Oracle's libclntsh.so
#   * libaio: for cx_Oracle
#   * mysql-dev: for using mysqlclient/MySQLdb
ENV PACKAGES="\
  dumb-init tzdata bash vim tini ncftp busybox-extras \
  python3 \
  mysql-dev \
"

# These packages are not installed immediately, but are added at runtime or ONBUILD to shrink the image as much as possible. Notes:
#   * build-base: used so we include the basic development packages (gcc)
#   * linux-headers: commonly needed, and an unusual package name from Alpine.
#   * python3-dev: are used for gevent e.g.
ENV BUILD_PACKAGES="\
  build-base \
  linux-headers \
  python3-dev \
"

## running
RUN echo "Begin" \
  && echo '199.232.68.133 raw.githubusercontent.com' >> /etc/hosts \
  && echo "${TIMEZONE}" > /etc/timezone \
  && GITHUB_URL='https://github.com/tianxiawuzhe/chgcheck_alpine312_py385_django312/raw/master' \
  && wget -O Dockerfile --timeout=30 -t 5 "${GITHUB_URL}/Dockerfile" \
  && wget -O entrypoint.sh --timeout=30 -t 5 "${GITHUB_URL}/entrypoint.sh" \
  && chmod +x /entrypoint.sh \
  && ls -l /entrypoint.sh \
  && sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories \
  && echo "********** 安装临时依赖" \
  && apk add --no-cache --virtual=.build-deps $BUILD_PACKAGES \
  && echo "********** 安装永久依赖" \
  && apk add --no-cache $PACKAGES \
  && echo "********** 更新python信息" \
##  && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
  && sed -i 's:mouse=a:mouse-=a:g' /usr/share/vim/vim82/defaults.vim \
  && { [[ -e /usr/bin/python ]] || ln -sf /usr/bin/python3.8 /usr/bin/python; } \
  && python -m ensurepip \
  && python -m pip install --upgrade --no-cache-dir pip \
  && cd /usr/bin \
  && ls -l python* pip* \
  && echo "********** 安装python包" \
  && speed="-i http://mirrors.aliyun.com/pypi/simple  --trusted-host mirrors.aliyun.com" \
  && pip install --no-cache-dir wheel ${speed} \
  && pip install --no-cache-dir Django==3.1.2 ${speed} \
  && pip install --no-cache-dir uwsgi==2.0.19.1 ${speed} \
  && pip install --no-cache-dir uwsgitop==0.11 ${speed} \
  && pip install --no-cache-dir celery==5.0.1 ${speed} \
  && pip install --no-cache-dir django-celery-results==1.2.1 ${speed} \
  && pip install --no-cache-dir django-celery-beat==2.1.0 ${speed} \
  && pip install --no-cache-dir mysqlclient==2.0.1 ${speed} \
  && pip install --no-cache-dir pandas==1.1.3 ${speed} \
  && pip install --no-cache-dir redis3==3.5.2.2 ${speed} \
  && echo "********** 删除依赖包" \
  && apk del .build-deps \
  && ls -l python* pip* \
  && echo "End"

EXPOSE 8080-8089
ENTRYPOINT ["/entrypoint.sh"]
CMD ["tail", "-f", "/dev/null"]
