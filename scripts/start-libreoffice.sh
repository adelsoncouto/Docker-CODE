#!/bin/sh

# Fix lool resolv.conf problem (wizdude)
rm /opt/lool/systemplate/etc/resolv.conf
ln -s /etc/resolv.conf /opt/lool/systemplate/etc/resolv.conf

if test "${DONT_GEN_SSL_CERT-set}" == set; then
# Generate new SSL certificate instead of using the default
mkdir -p /opt/ssl/
cd /opt/ssl/
mkdir -p certs/ca
openssl genrsa -out certs/ca/root.key.pem 2048
openssl req -x509 -new -nodes -key certs/ca/root.key.pem -days 9131 -out certs/ca/root.crt.pem -subj "/C=DE/ST=BW/L=Stuttgart/O=Dummy Authority/CN=Dummy Authority"
mkdir -p certs/{servers,tmp}
mkdir -p "certs/servers/localhost"
openssl genrsa -out "certs/servers/localhost/privkey.pem" 2048 -key "certs/servers/localhost/privkey.pem"
if test "${cert_domain-set}" == set; then
openssl req -key "certs/servers/localhost/privkey.pem" -new -sha256 -out "certs/tmp/localhost.csr.pem" -subj "/C=DE/ST=BW/L=Stuttgart/O=Dummy Authority/CN=localhost"
else
openssl req -key "certs/servers/localhost/privkey.pem" -new -sha256 -out "certs/tmp/localhost.csr.pem" -subj "/C=DE/ST=BW/L=Stuttgart/O=Dummy Authority/CN=${cert_domain}"
fi
openssl x509 -req -in certs/tmp/localhost.csr.pem -CA certs/ca/root.crt.pem -CAkey certs/ca/root.key.pem -CAcreateserial -out certs/servers/localhost/cert.pem -days 9131
mv certs/servers/localhost/privkey.pem /etc/loolwsd/key.pem
mv certs/servers/localhost/cert.pem /etc/loolwsd/cert.pem
mv certs/ca/root.crt.pem /etc/loolwsd/ca-chain.cert.pem
fi

# Replace trusted host and set admin username and password
perl -pi -e "s/localhost<\/host>/${domain}<\/host>/g" /etc/loolwsd/loolwsd.xml
perl -pi -e "s/<username (.*)>.*<\/username>/<username \1>${username}<\/username>/" /etc/loolwsd/loolwsd.xml
perl -pi -e "s/<password (.*)>.*<\/password>/<password \1>${password}<\/password>/" /etc/loolwsd/loolwsd.xml
perl -pi -e "s/<server_name (.*)>.*<\/server_name>/<server_name \1>${server_name}<\/server_name>/" /etc/loolwsd/loolwsd.xml
perl -pi -e "s/de_DE en_GB en_US es_ES fr_FR it nl pt_BR pt_PT ru<\/allowed_languages>/${allowed_languages}<\/allowed_languages>/g" /etc/loolwsd/loolwsd.xml
 
# Start loolwsd
su -c "/usr/bin/loolwsd --version --o:sys_template_path=/opt/lool/systemplate --o:lo_template_path=/opt/collaboraoffice5.3 --o:child_root_path=/opt/lool/child-roots --o:file_server_root_path=/usr/share/loolwsd" -s /bin/bash lool
