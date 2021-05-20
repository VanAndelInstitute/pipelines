# Webserver with NGINX, HTTPS, Express

## Domain

The Internet is a little unclear on this point, but I believe it is a true
statement that in order to serve over HTTPS with a valid SSL certificate, you
need a domain name for verification of that certificate. Otherwise, there is no
"identity" for the SSL certificate to verify. You can self sign an SSL
certificate, but I think that will not fly with any sort of modern browser. But
I still need to confirm that.

So for starters, go register a domain name. You can do this on AWS via Route53. 

## Hardware

Create an EC2 instance and, ideally (to avoid needing to adjust your routing
later if you swap out instances), assign an Elastic IP address to it. I am 
most familiar with Ubuntu, so I use Ubuntu images for my instances. The  
following assumes you are in a Ubuntu (or at least Debian based) environment. 
Other environments will require tweaks to the installation procedures to use 
whatever package management system or build environment you have at your 
disposal.

## Routing

Now you need to connect your domain name to your EC2 instance based on its IP
address. Go to Route53 and click on the "Hosted zone" that was automatically
created when you registered your domain name (note that the zone will not be
created until the domain name registration goes through which can take a couple
of hours up to a couple of days). Click "Create Record Set" and create a prefix
for which requests will be routed. For example, you could create a record set
for the "www" prefix (typical for a website). Then fill in your instance's IP
address in the "Value" box, and click Save Record Set.

Note that HTTP requests will be routed to port 80 on your instance, and HTTPS
requests to port 443, as per the standard.

## Install NGINX

We will use NGINX as our server and reverse proxy to securely handle incoming
requests and serve outgoing responses. This will among other things avoid the
need to be running our express apps as root in order to listen on ports below
1000. HTTPS will be handled by NGINX so we don't need to worry about it within
our apps. The same thing could be achieved with Apache, or IIS, or whatever. But
I find NGINX to be simple and effective. YMMV.

Installation is easy. SSH to your instance (this is made simpler by creating 
an entry in [your ~/.ssh/config file](https://linuxize.com/post/using-the-ssh-config-file/) 
with the details). Then
execute the following commands:

```
sudo apt update
sudo apt install -y nginx
```

You should now be able to go to www.yourserver.com (assuming you used the 'www' 
prefix when setting up the routing above, and obviously substituting your 
domain name for "yourserver.com") and see the nginx welcome message.

## Enable HTTPS

In order to serve securely, we first need public and private certificates 
that verify our identity. 

IIUC, although you can generate SSL certificates for free with the AWS 
Certificate Manager, you can not actually download those certificates 
to your instance. Instead, you must use them with their Elastic Load 
Balancing service. Which is fine, but more infrastructure than we 
require here. 

The simplest (and still free) way to do this is to use certificates from 
[letsencrypt.org](letsencrypt.org) and install them on our instance all 
in one shot using [certbot](certbot.eff.org). For Ubuntu 18.04, the following 
is all that is required. (Earlier or later releases of Ubuntu may be slightly 
different. If the following does not work, check instructions at the certbot 
link above).

```
sudo -s
apt-get update
apt-get install software-properties-common
add-apt-repository universe
add-apt-repository ppa:certbot/certbot
apt-get update
apt-get install -y certbot python3-certbot-nginx
certbot --nginx

```

And answer the questions. When prompted for the domain name, enter the full
path including the prefix you configured above (e.g. "www.yourserver.com"). 
Wildcards (e.g. "*.yourserver.com") did not work for me.

Now visit your page again. If you use https:// (or if you selected auto 
re-direct when answering the certbot questions), you should see the 
lovely little lock appear next to the address in the address bar that 
indicates the web traffic is now secure!

## Create an express app

First we install `node.js`:

```
curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt-get install -y nodejs
```

We also need `pm2` to run our node apps as daemons (so they 
keep going after we log out. Sort of like `forever` on steroids. 
Or maybe it's the other way around. I don't know. Maybe there 
are no steroids involved. Anyway, `pm`2 seems somewhat more 
popular now.)

```
# install globally
sudo npm install -g pm2
```

Now we can create the `express.js` Hello World app:

```
const express = require('express')
const app = express()
const port = 3000

app.get('/', (req, res) => res.send('Hello World!'))

app.listen(port, () => console.log(`Example app listening at http://localhost:${port}`))
```

Save the above as `server.js`.

Then, execute:

```
pm2 start server.js
curl localhost:3000
```

The curl request should return the HTML of your hello world app.

Finally, we can configure `pm2` to restart itself and its managed processes 
in the event of a system reboot. 

```
pm2 startup systemd
```

That will spit out one more command you must run to adjust the system wide 
paths to find both `pm2` and your processes. In my case, it looked like this:

```
sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u ubuntu --hp /home/ubuntu
```

## Tell NGINX about your express app

Edit /etc/nginx/sites-available/default to add routing for your app. You will
need to find the `server` section that specifies `server_name www.yoursrver.com`, 
and then add nother location stanza after the root location stanza so it looks
something like this:

```
server {
  root /var/www/html;
  index index.html index.htm index.nginx-debian.html;
  server_name www.yourserver.com; # managed by Certbot
  
  location / {
                  # First attempt to serve request as file, then
                  # as directory, then fall back to displaying a 404.
                  try_files $uri $uri/ =404;
          }
          
  # this will be the relative path to your app.
  # DO NOT OMIT THE TRAILING SLASH!
  location /hello/ {
      # DO NOT OMIT THE TRAILING SLASH!
      proxy_pass http://localhost:3000/;
      proxy_http_version 1.1;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection 'upgrade';
      proxy_set_header Host $host;
      proxy_cache_bypass $http_upgrade;
  }
  listen [::]:443 ssl ipv6only=on; # managed by Certbot
  listen 443 ssl; # managed by Certbot
  ssl_certificate /etc/letsencrypt/live/powerups.trellice.io/fullchain.pem; # managed by Certbot
  ssl_certificate_key /etc/letsencrypt/live/powerups.trellice.io/privkey.pem; # managed by Certbot
  include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
  ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
}

```

**Note** that the trailing slashes on the `location` and `proxy_pass` 
declarations are essential. Without them, routing on any static 
resources from your express app (like css or javascript) will get
confusing because NGINX will add the location to the request path. 
You would then need to add this as a prefix to your routes in your 
express app, which will break if you ever want to change the 
the location. But if you add the trailing slashes, it tells NGINX 
not to pass that part to the proxied request and then you can 
ignore the upstream path in your express app and just refer to 
everything relative to the root of your app.

Next test your configuration:

```
sudo nginx -t
```

And finally restart nginx to load the new configuration.

```
sudo systemctl restart nginx
```

You should now be able to point your browser to https://www.yourserver.com/hello and 
be greeted with your hello world message.

Notice that there was nothing in our express app related to HTTPS. All those 
details are handled by NGINX. This makes app development and maintenance simpler.

You can now enhance your app and add additional apps (running on different ports) 
as required. 
