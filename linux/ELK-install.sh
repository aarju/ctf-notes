#/bin/bash
#Ask some info
echo -n "Enter ELK Server IP or FQDN: "
read eip
echo -n "Enter Admin Web Password: "
read adpwd

#Update System
sudo apt-get update
sudo apt-get upgrade -y

#Java Pre-Req
sudo add-apt-repository ppa:webupd8team/java -y
sudo apt-get update
sudo apt-get install oracle-java8-installer -y

#Add Repo Info
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
sudo apt-get install apt-transport-https -y
echo "deb https://artifacts.elastic.co/packages/5.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-5.x.list
sudo apt-get update

#Elastic Search
sudo apt-get install elasticsearch -y
echo "network.host: localhost" | sudo tee /etc/elasticsearch/elasticsearch.yml
sudo systemctl daemon-reload
sudo systemctl enable elasticsearch.service
sudo systemctl restart elasticsearch.service

#Kibana
sudo apt-get install kibana -y
cat <<EOC | sudo su
cat <<EOT > /etc/kibana/kibana.yml
server.host: "localhost"
EOT
exit
EOC
sudo systemctl daemon-reload
sudo systemctl enable kibana.service
sudo systemctl restart kibana.service

#NGINX Reverse Proxy
echo "admin:`openssl passwd -apr1 $adpwd`" | sudo tee -a /etc/nginx/htpasswd.users
sudo apt-get -y install nginx -y
cat <<EOC | sudo su
cat <<EOT > /etc/nginx/sites-available/default
server {
    listen 80;

    server_name $eip;
    
    auth_basic "Restricted Access";
    auth_basic_user_file /etc/nginx/htpasswd.users;
    
    location / {
        proxy_pass http://localhost:5601;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \\\$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \\\$host;
        proxy_cache_bypass \\\$http_upgrade;        
    }
}
EOT
exit
EOC
sudo systemctl restart nginx

#Logstash
sudo apt-get install logstash -y
sudo mkdir -p /etc/pki/tls/certs
sudo mkdir /etc/pki/tls/private
cd /etc/pki/tls; sudo openssl req -subj '/CN='$eip'/' -x509 -days 3650 -batch -nodes -newkey rsa:2048 -keyout private/logstash-forwarder.key -out certs/logstash-forwarder.crt
cat <<EOC | sudo su
cat <<EOT > /etc/logstash/conf.d/02-beats-input.conf
input {
  beats {
    port => 5044
    ssl => true
    ssl_certificate => "/etc/pki/tls/certs/logstash-forwarder.crt"
    ssl_key => "/etc/pki/tls/private/logstash-forwarder.key"
  }
}
EOT
exit
EOC
cat <<EOC | sudo su
cat <<EOT > /etc/logstash/conf.d/10-syslog-filter.conf
filter {
  if [type] == "syslog" {
    grok {
      match => { "message" => "%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:syslog_hostname} %{DATA:syslog_program}(?:\[%{POSINT:syslog_pid}\])?: %{GREEDYDATA:syslog_message}" }
      add_field => [ "received_at", "%{@timestamp}" ]
      add_field => [ "received_from", "%{host}" ]
    }
    syslog_pri { }
    date {
      match => [ "syslog_timestamp", "MMM  d HH:mm:ss", "MMM dd HH:mm:ss" ]
    }
  }
}
EOT
exit
EOC
cat <<EOC | sudo su
cat <<EOT > /etc/logstash/conf.d/11-syslog-apache.conf
filter {
  if [source] =~ "apache" {
    if [source] =~ "access" {
      mutate { replace => { "type" => "apache_access" } }
      grok {
        match => { "message" => "%{COMBINEDAPACHELOG}" }
      }
    } else if [source] =~ "error" {
       mutate { replace => { type => "apache_error" } }
    } else {
       mutate { replace => { type => "apache_random"} }
    }
    date {
      match => [ "timestamp" , "dd/MMM/yyyy:HH:mm:ss Z" ]
    }
  }
}
EOT
exit
EOC
cat <<EOC | sudo su
cat <<EOT > /etc/logstash/conf.d/30-elasticsearch-output.conf
output {
  elasticsearch {
    hosts => "localhost:9200"
    manage_template => false
    index => "%{[@metadata][beat]}-%{+YYYY.MM.dd}"
    document_type => "%{[@metadata][type]}"
  }
}
EOT
exit
EOC
sudo systemctl daemon-reload
sudo /usr/share/logstash/bin/logstash-plugin install logstash-input-beats
sudo systemctl enable logstash.service
sudo systemctl restart logstash.service

#Packetbeat
sudo apt-get install packetbeat -y
cat <<EOC | sudo su
cat <<EOT > /etc/packetbeat/packetbeat.yml
packetbeat.flows:
  timeout: 30s
  period: 10s
packetbeat.protocols.icmp:
  enabled: true
packetbeat.protocols.amqp:
  ports: [5672]
packetbeat.protocols.cassandra:
  ports: [9042]
packetbeat.protocols.dns:
  ports: [53]
  include_authorities: true
  include_additionals: true
packetbeat.protocols.http:
  ports: [80, 8080, 8000, 5000, 8002]
packetbeat.protocols.memcache:
  ports: [11211]
packetbeat.protocols.mysql:
  ports: [3306]
packetbeat.protocols.pgsql:
  ports: [5432]
packetbeat.protocols.redis:
  ports: [6379]
packetbeat.protocols.thrift:
  ports: [9090]
packetbeat.protocols.mongodb:
  ports: [27017]
packetbeat.protocols.nfs:
  ports: [2049]
output.logstash:
  hosts: ["$eip:5044"]
  ssl.certificate_authorities: ["/etc/pki/tls/certs/logstash-forwarder.crt"]
EOT
exit
EOC
sudo systemctl daemon-reload
sudo systemctl enable packetbeat.service
curl -XPUT 'http://localhost:9200/_template/packetbeat' -d@/etc/packetbeat/packetbeat.template.json
sudo /usr/share/packetbeat/scripts/import_dashboards

#Metricbeat
sudo apt-get install metricbeat -y
cat <<EOC | sudo su
cat <<EOT > /etc/metricbeat/metricbeat.yml
metricbeat.modules:
- module: system
  metricsets:
    - cpu
    - load
    - core
    - diskio
    - filesystem
    - fsstat
    - memory
    - network
    - process
  enabled: true
  period: 10s
  processes: ['.*']
output.logstash:
  hosts: ["$eip:5044"]
  ssl.certificate_authorities: ["/etc/pki/tls/certs/logstash-forwarder.crt"]
EOT
exit
EOC
sudo systemctl daemon-reload
sudo systemctl enable metricbeat.service
curl -XPUT 'http://localhost:9200/_template/metricbeat' -d@/etc/metricbeat/metricbeat.template.json
sudo /usr/share/metricbeat/scripts/import_dashboards

#FileBeat
sudo apt-get install filebeat -y
cat <<EOC | sudo su
cat <<EOT > /etc/filebeat/filebeat.yml
filebeat.prospectors:
- input_type: log
  paths:
    - /var/log/*/*.log
- document_type: syslog
  paths:
    - /var/log/syslog
output.logstash:
  hosts: ["$eip:5044"]
  ssl.certificate_authorities: ["/etc/pki/tls/certs/logstash-forwarder.crt"]
EOT
exit
EOC
sudo systemctl daemon-reload
sudo systemctl enable filebeat.service
curl -XPUT 'http://localhost:9200/_template/filebeat' -d@/etc/filebeat/filebeat.template.json
sudo /usr/share/filebeat/scripts/import_dashboards

sudo systemctl restart filebeat
sudo systemctl restart metricbeat
sudo systemctl restart packetbeat


###
# CREATE CLIENT INSTALL SCRIPT
###
cat <<EOS > ~/ELK-client-install.sh
sudo apt-get update
sudo apt-get upgrade
#Add Repo Info
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
sudo apt-get install apt-transport-https
echo "deb https://artifacts.elastic.co/packages/5.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-5.x.list
sudo apt-get update
#CERT
sudo mkdir -p /etc/pki/tls/certs
cat <<EOC | sudo su
cat <<EOT > /etc/pki/tls/certs/logstash-forwarder.crt
$(sudo cat /etc/pki/tls/certs/logstash-forwarder.crt)
EOT
exit
EOC
#Packetbeat
sudo apt-get install packetbeat
cat <<EOC | sudo su
cat <<EOT > /etc/packetbeat/packetbeat.yml
packetbeat.flows:
  timeout: 30s
  period: 10s
packetbeat.protocols.icmp:
  enabled: true
packetbeat.protocols.amqp:
  ports: [5672]
packetbeat.protocols.cassandra:
  ports: [9042]
packetbeat.protocols.dns:
  ports: [53]
  include_authorities: true
  include_additionals: true
packetbeat.protocols.http:
  ports: [80, 8080, 8000, 5000, 8002]
packetbeat.protocols.memcache:
  ports: [11211]
packetbeat.protocols.mysql:
  ports: [3306]
packetbeat.protocols.pgsql:
  ports: [5432]
packetbeat.protocols.redis:
  ports: [6379]
packetbeat.protocols.thrift:
  ports: [9090]
packetbeat.protocols.mongodb:
  ports: [27017]
packetbeat.protocols.nfs:
  ports: [2049]
output.logstash:
  hosts: ["$eip:5044"]
  ssl.certificate_authorities: ["/etc/pki/tls/certs/logstash-forwarder.crt"]
EOT
exit
EOC
sudo systemctl daemon-reload
sudo systemctl enable packetbeat.service
#Metricbeat
sudo apt-get install metricbeat
cat <<EOC | sudo su
cat <<EOT > /etc/metricbeat/metricbeat.yml
metricbeat.modules:
- module: system
  metricsets:
    - cpu
    - load
    - core
    - diskio
    - filesystem
    - fsstat
    - memory
    - network
    - process
  enabled: true
  period: 10s
  processes: ['.*']
output.logstash:
  hosts: ["$eip:5044"]
  ssl.certificate_authorities: ["/etc/pki/tls/certs/logstash-forwarder.crt"]
EOT
exit
EOC
sudo systemctl daemon-reload
sudo systemctl enable filebeat.service
#FileBeat
sudo apt-get install filebeat
cat <<EOC | sudo su
cat <<EOT > /etc/filebeat/filebeat.yml
filebeat.prospectors:
- input_type: log
  paths:
    - /var/log/*/*.log
- document_type: syslog
  paths:
    - /var/log/syslog
output.logstash:
  hosts: ["$eip:5044"]
  ssl.certificate_authorities: ["/etc/pki/tls/certs/logstash-forwarder.crt"]
EOT
exit
EOC
sudo systemctl daemon-reload
sudo systemctl enable filebeat.service
sudo systemctl restart filebeat
sudo systemctl restart metricbeat
sudo systemctl restart packetbeat
EOS