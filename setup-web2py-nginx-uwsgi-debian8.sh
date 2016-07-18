#!/bin/bash
echo 'Setup-web2py-nginx-uwsgi-debian8.sh'
echo 'Requires Debian 8 (Jessie) and installs Nginx + uWSGI + Web2py'
# Check if user has root privileges
if [[ $EUID -ne 0 ]]; then
   echo "You must run the script as root or using sudo"
   exit 1
fi


# Get Web2py Application Name
echo -e "Web2py Application Name: \c "
read  APPNAME
echo

# Get Domain Name
echo -e "Enter app's domains names (Ex: www.example.com, example.com): \c "
read  DOMAINS
echo

# Get Web2py Admin Password
echo -e "Web2py Admin Password: \c "
read  PW

# Upgrade and install needed software
apt-get update
apt-get -y upgrade
apt-get -y autoremove
apt-get -y autoclean
echo "Installing nginx"
apt-get -y install nginx
echo "Installing uwsgi"
apt-get -y install uwsgi uwsgi-plugin-python
apt-get -y install build-essential sudo python-dev libxml2-dev unzip
echo


# Create common nginx sections
echo "Configuring nginx's $APPNAME config at /etc/nginx/conf.d/$APPNAME"
mkdir /etc/nginx/conf.d/"$APPNAME"
echo '
gzip_static on;
gzip_http_version   1.1;
gzip_proxied        expired no-cache no-store private auth;
gzip_disable        "MSIE [1-6]\.";
gzip_vary           on;
' > /etc/nginx/conf.d/"$APPNAME"/gzip_static.conf
echo '
gzip on;
gzip_disable "msie6";
gzip_vary on;
gzip_proxied any;
gzip_comp_level 6;
gzip_buffers 16 8k;
gzip_http_version 1.1;
gzip_types text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript;
' > /etc/nginx/conf.d/"$APPNAME"/gzip.conf


# Create configuration file /etc/nginx/sites-available/"$APPNAME"
echo "server {
        listen          80;
        server_name     $DOMAINS;

        ###to enable correct use of response.static_version
        #location ~* ^/(\w+)/static(?:/_[\d]+\.[\d]+\.[\d]+)?/(.*)$ {
        #    alias /home/www-data/$APPNAME/applications/\$1/static/\$2;
        #    expires max;
        #}
        ###

        ###if you use something like myapp = dict(languages=['en', 'it', 'jp'], default_language='en') in your routes.py
        #location ~* ^/(\w+)/(en|it|jp)/static/(.*)$ {
        #    alias /home/www-data/$APPNAME/applications/\$1/;
        #    try_files static/\$2/\$3 static/\$3 = 404;
        #}
        ###

        location ~* ^/(\w+)/static/ {
            root /home/www-data/$APPNAME/applications/;
            #remove next comment on production
            #expires max;
            ### if you want to use pre-gzipped static files (recommended)
            ### check scripts/zip_static_files.py and remove the comments
            # include /etc/nginx/conf.d/$APPNAME/gzip_static.conf;
            ###
        }

        location / {
            uwsgi_pass      unix:///tmp/$APPNAME.socket;
            include         uwsgi_params;
            uwsgi_param     UWSGI_SCHEME \$scheme;
            uwsgi_param     SERVER_SOFTWARE    'nginx/\$nginx_version';

            ###remove the comments to turn on if you want gzip compression of your pages
            # include /etc/nginx/conf.d/$APPNAME/gzip.conf;
            ### end gzip section

            ### remove the comments if you use uploads (max 10 MB)
            #client_max_body_size 10m;
            ###
        }
}

server {
        listen 443 ssl spdy;
        server_name     $DOMAINS;

        ssl_certificate         /etc/nginx/ssl/$APPNAME.crt;
        ssl_certificate_key     /etc/nginx/ssl/$APPNAME.key;
        ssl_prefer_server_ciphers on;
        ssl_session_cache shared:ssl_session_cache:1M;
        ssl_session_timeout 600m;
        ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA:ECDHE-ECDSA-AES128-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA256:EDH-RSA-DES-CBC3-SHA;
        ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
        keepalive_timeout    70;

        location / {
            uwsgi_pass      unix:///tmp/$APPNAME.socket;
            include         uwsgi_params;
            uwsgi_param     UWSGI_SCHEME \$scheme;
            uwsgi_param     SERVER_SOFTWARE    'nginx/\$nginx_version';
            ###remove the comments to turn on if you want gzip compression of your pages
            # include /etc/nginx/conf.d/$APPNAME/gzip.conf;
            ### end gzip section
            ### remove the comments if you want to enable uploads (max 10 MB)
            #client_max_body_size 10m;
            ###
        }
        ## if you serve static files through https, copy here the section
        ## from the previous server instance to manage static files

}" >/etc/nginx/sites-available/"$APPNAME"

ln -s /etc/nginx/sites-available/"$APPNAME" /etc/nginx/sites-enabled/"$APPNAME"
rm /etc/nginx/sites-enabled/default
mkdir /etc/nginx/ssl
cd /etc/nginx/ssl

# Create a temporary openssl conf
echo "
[ req ]
default_bits		= 2048
default_keyfile 	= privkey.pem
distinguished_name	= req_distinguished_name
string_mask = utf8only

[ req_distinguished_name ]
countryName			= Country Name (2 letter code)
countryName_default		= AU
countryName_min			= 2
countryName_max			= 2
stateOrProvinceName		= State or Province Name (full name)
stateOrProvinceName_default	= Some-State
localityName			= Locality Name (eg, city)
0.organizationName		= Organization Name (eg, company)
0.organizationName_default	= Internet Widgits Pty Ltd
organizationalUnitName		= Organizational Unit Name (eg, section)
commonName			= Common Name (e.g. server FQDN, your PRIMARY domain)
commonName_max			= 64
emailAddress			= Email Address
emailAddress_max		= 64

[ usr_cert ]
basicConstraints=CA:TRUE
keyUsage = digitalSignature, keyEncipherment, keyAgreement
extendedKeyUsage=serverAuth
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer
" > /tmp/openssl.cnf

echo 'Creating a x509 certificate (2048 bits key-length and valid for 365 days) to run HTTPS'
openssl genrsa -out "$APPNAME".key 2048
chmod 400 "$APPNAME".key
openssl req -new -x509 -sha256 -days 365 -key "$APPNAME".key -config /tmp/openssl.cnf -extensions usr_cert -out "$APPNAME".crt
openssl x509 -noout -fingerprint -text -in "$APPNAME".crt > "$APPNAME".info
rm -rf /tmp/certificate.txt

# Create configuration file /etc/uwsgi/"$APPNAME".ini
echo "Creating uwsgi configuration file /etc/uwsgi/apps-available/$APPNAME.ini"
echo "[uwsgi]

socket = /tmp/$APPNAME.socket
pythonpath = /home/www-data/$APPNAME/
mount = /=wsgihandler:application
processes = 4
master = true
harakiri = 60
reload-mercy = 8
cpu-affinity = 1
stats = /tmp/$APPNAME.stats.socket
max-requests = 2000
limit-as = 512
reload-on-as = 256
reload-on-rss = 192
uid = www-data
gid = www-data
cron = 0 0 -1 -1 -1 python /home/www-data/$APPNAME/web2py.py -Q -S welcome -M -R scripts/sessions2trash.py -A -o
no-orphans = true
enable-threads = true
" >/etc/uwsgi/apps-available/"$APPNAME".ini
ln -s /etc/uwsgi/apps-available/"$APPNAME".ini /etc/uwsgi/apps-enabled/


# Install Web2py
mkdir /home/www-data
cd /home/www-data
wget http://web2py.com/examples/static/web2py_src.zip
unzip web2py_src.zip
rm web2py_src.zip
mv web2py "$APPNAME"
chown -R www-data:www-data "$APPNAME"
cd /home/www-data/"$APPNAME"
sudo -u www-data python -c "from gluon.main import save_password; save_password('$PW',443)"

# Needed on new versions of web2py where new folders where added
ln -s handlers/wsgihandler.py .

#Create app remove(rm) script
echo Creating app remove\(rm\) script at /home/www-data/"$APPNAME"/"$APPNAME"_remove_app.sh
echo "
#!/bin/bash
rm -rf /etc/uwsgi/apps-available/"$APPNAME".ini /tmp/$APPNAME* /home/www-data/$APPNAME
systemctl stop nginx.service
find /etc/nginx/ -name *$APPNAME* -exec rm -rf {} \\;
systemctl restart nginx.service
systemctl reload uwsgi.service
" > /home/www-data/"$APPNAME"/"$APPNAME"_remove_app.sh && chmod +x /home/www-data/"$APPNAME"/"$APPNAME"_remove_app.sh

#(Re)Start services
echo '(Re)Starting services'
systemctl restart nginx.service
systemctl restart uwsgi.service
echo 'Done! Enjoy your app!'
echo



echo '
**** you can reload uwsgi with
# systemctl reload uwsgi.service
**** and stop it with
# systemctl stop uwsgi.service
**** to reload web2py only (without restarting uwsgi)
# touch --no-dereference /etc/uwsgi/"$APPNAME".ini
'
