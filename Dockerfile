FROM centos:7
ENV container=docker

MAINTAINER Justin Cook <jhcook@gmail.com>

# Basic packages
RUN rpm -Uvh https://www.mirrorservice.org/sites/dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm \
  && yum -y install passwd sudo git wget openssl

# Redis
RUN yum install -y redis

# RabbitMQ
RUN yum install -y erlang \
  && curl -s https://packagecloud.io/install/repositories/rabbitmq/rabbitmq-server/script.rpm.sh | bash \
  && yum install -y rabbitmq-server-3.6.1-1.noarch 

# Generate keys
RUN git clone https://github.com/joemiller/joemiller.me-intro-to-sensu.git \
  && cd joemiller.me-intro-to-sensu ; ./ssl_certs.sh clean && ./ssl_certs.sh generate \
  && mkdir -p /etc/rabbitmq/ssl \
  && cp server_cert.pem /etc/rabbitmq/ssl/cert.pem \
  && cp server_key.pem /etc/rabbitmq/ssl/key.pem \
  && cp testca/cacert.pem /etc/rabbitmq/ssl/
ADD ./files/rabbitmq.config /etc/rabbitmq/
RUN systemctl enable rabbitmq-server \
  && rabbitmq-plugins enable rabbitmq_management --offline

# Sensu server
ADD ./files/sensu.repo /etc/yum.repos.d/
RUN yum install -y sensu
ADD ./files/config.json /etc/sensu/
RUN mkdir -p /etc/sensu/ssl \
  && cp /joemiller.me-intro-to-sensu/client_cert.pem /etc/sensu/ssl/cert.pem \
  && cp /joemiller.me-intro-to-sensu/client_key.pem /etc/sensu/ssl/key.pem

# uchiwa
RUN yum install -y uchiwa
ADD ./files/uchiwa.json /etc/sensu/

# supervisord
RUN wget http://peak.telecommunity.com/dist/ez_setup.py ; python ez_setup.py \
  && easy_install supervisor
ADD ./files/supervisord.conf /etc/supervisord.conf

EXPOSE 3000 4567 5671 15672

CMD ["/usr/bin/supervisord"]

