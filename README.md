README
======

- This is a set of scripts that **install and configure a web2py application running over nginx + uwsgi** or just a new web2py application on that enviroment.


- I did some changes to make it work on fresh debian 8 install, you may get issues running it on a live enviroment (just let me know and i'll be glad to help).

- **CREDITS:** Adapted from web2py's scripts/setup-web2py-nginx-uwsgi-ubuntu.sh


####Scritps

[*setup-web2py-nginx-uwsgi-debian8.sh*]

- installs all packages needed to run your web2py app;
- installs and configure uwsgi (middleware to run python applications);
- installs and confiugre nginx (one of the most popular web servers);
- downloads a fresh web2py's source code and extracts at '/home/www-data';
- generates a self-signed certificate to enable HTTPS right away;
- creates a 'remove script' at APP folder to make uninstall easily (just APP, it does not touch nginx neither uwsgi core files)



[*setup-web2py-new_app-debian8.sh*]

- installs and configure new web2py app;
- assumes you've already run **setup-web2py-nginx-uwsgi-debian8.sh** previously;
- downloads a fresh web2py's source code and extracts at '/home/www-data';
- generates a self-signed certificate to enable HTTPS right away;
- creates a 'remove script' at APP folder to make uninstall easily (just APP, it does not touch nginx neither uwsgi core files)



#### Changelog
 2016/07/10:

- using uwsgi package provided by Debian repo;
- new web2py's folder skeleton broke uwsgi's app config --> fixed (a simple link got it)
- improve SSL/TLS private key (x509 certificate) to 2048 bits
- setting x509v3 extensions in temporary file


#### TO-DO
- review nginx conf for better settings  
- improve x509v3 extensions config
- improve uwsgi to work on emperor mode (maybe building service [emperor.uwsgi.service](http://uwsgi-docs.readthedocs.io/en/latest/Systemd.html) at deploy )
