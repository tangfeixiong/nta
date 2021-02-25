# ModSecurity-Nginx

Reference:
+ https://github.com/kubernetes/ingress-nginx/tree/master/rootfs
+ https://github.com/SpiderLabs/ModSecurity/wiki/Compilation-recipes-for-v3.x#ubuntu-1504
+ https://github.com/coreruleset/coreruleset
+ https://www.modsecurity.org/CRS/Documentation/making.html
+ https://github.com/coreruleset/modsecurity-docker/tree/master/v3-nginx
+ https://github.com/OWASP/www-community

## VM

host
```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/libmodsecurity$ \
hostname -I | awk '{print $2}'
172.28.128.3
```

__Httpbin backend__

Reference https://httpbin.org/
```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/libmodsecurity$ \
docker run -d --rm --name httpbin --cpus 0.5 --memory 512M --expose 80 --privileged kennethreitz/httpbin
WARNING: Your kernel does not support swap limit capabilities or the cgroup is not mounted. Memory limited without swap.
5d9f9d460c104a6a80780a6609f6bc7136bdf559054b67df147c4be476845b85
```

```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/libmodsecurity$ \
docker inspect httpbin -f '{{.NetworkSettings.IPAddress}}'
172.17.0.3
```
Modify nginx.conf proxy config like `proxy_pass http://172.17.0.3/;`

__Nginx reverse proxy with ModSecurity__

```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/libmodsecurity$ \
sudo nginx -c $PWD/nginx.conf -t
nginx: the configuration file /Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/libmodsecurity/nginx.conf syntax is ok
nginx: configuration file /Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/libmodsecurity/nginx.conf test is successful
```

```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/libmodsecurity$ \
sudo /usr/sbin/nginx -c $PWD/nginx.conf -g "daemon off;"
```

reverse proxy
```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/libmodsecurity$ \
curl http://172.28.128.3:8989/get
{
  "args": {}, 
  "headers": {
    "Accept": "*/*", 
    "Connection": "close", 
    "Host": "172.17.0.3", 
    "User-Agent": "curl/7.58.0"
  }, 
  "origin": "172.17.0.1", 
  "url": "http://172.17.0.3/get"
}
```

__SQL Injection__

```
bogon:libmodsecurity fanhongling$ ./runtests_curl.sh waf.sql
{
  "args": {}, 
  "data": "", 
  "files": {}, 
  "form": {
    "customer_id": "'1234567'"
  }, 
  "headers": {
    "Accept": "*/*", 
    "Connection": "close", 
    "Content-Length": "21", 
    "Content-Type": "application/x-www-form-urlencoded", 
    "Host": "172.17.0.3", 
    "User-Agent": "curl/7.37.1"
  }, 
  "json": null, 
  "origin": "172.17.0.1", 
  "url": "http://172.17.0.3/post"
}
---sql injection trial---
* Hostname was NOT found in DNS cache
*   Trying 172.28.128.3...
* Connected to 172.28.128.3 (172.28.128.3) port 8989 (#0)
> POST //post HTTP/1.1
> User-Agent: curl/7.37.1
> Host: 172.28.128.3:8989
> Accept: */*
> Content-Length: 54
> Content-Type: application/x-www-form-urlencoded
> 
* upload completely sent off: 54 out of 54 bytes
< HTTP/1.1 403 Forbidden
* Server nginx/1.14.0 (Ubuntu) is not blacklisted
< Server: nginx/1.14.0 (Ubuntu)
< Date: Thu, 21 Jan 2021 02:48:15 GMT
< Content-Type: text/html
< Content-Length: 178
< Connection: keep-alive
< 
<html>
<head><title>403 Forbidden</title></head>
<body bgcolor="white">
<center><h1>403 Forbidden</h1></center>
<hr><center>nginx/1.14.0 (Ubuntu)</center>
</body>
</html>
* Connection #0 to host 172.28.128.3 left intact
```



## Docker

Hands-on - [hands-on-docker.txt](./hands-on-docker.txt)
```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/libmodsecurity$ \
docker commit -a "tangfeixiong <tangfx128@google.com>" -m "nginx with ModSecurity" -c "EXPOSE 80 443" ubuntu-libmodsec tangfeixiong/nginx-modsecurity-dev
sha256:3a4eee03b01584fa784c540c4d73fe927996f3dce6bad99b2af9a61394fa5e4f
```

Build stage - [docker-build.txt](./docker-build.txt)
```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/libmodsecurity/rootfs$ \
docker build --target=builder --rm --force-rm --no-cache -f Dockerfile.Ubuntu-18-04 -t tangfeixiong/nginx_modsecurity_build .
```

__Httpbin backend__
```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/libmodsecurity/rootfs$ \
docker run -d --rm --name httpbin --cpus 0.5 --memory 512M --expose 80 --cap-add NET_ADMIN --cap-add SYS_ADMIN kennethreitz/httpbin
Unable to find image 'kennethreitz/httpbin:latest' locally
latest: Pulling from kennethreitz/httpbin
473ede7ed136: Pull complete 
c46b5fa4d940: Pull complete 
93ae3df89c92: Pull complete 
6b1eed27cade: Pull complete 
0373952b589d: Pull complete 
7b82cd0ee527: Pull complete 
a36b2d884a89: Pull complete 
Digest: sha256:599fe5e5073102dbb0ee3dbb65f049dab44fa9fc251f6835c9990f8fb196a72b
Status: Downloaded newer image for kennethreitz/httpbin:latest
WARNING: Your kernel does not support swap limit capabilities or the cgroup is not mounted. Memory limited without swap.
84f4534d1ed85668ab66a376f66902269e4bbeef92ef3c8f9065b9330521f00a
```

```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/libmodsecurity/rootfs$ \
docker inspect httpbin -f "{{.NetworkSettings.IPAddress}}"
172.17.0.3
```

__Nginx reverse proxy with ModSecurity__
```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/libmodsecurity$ docker run -ti --rm --name nginx-modsecurity-build --expose 80 --link httpbin:httpbin -v $PWD/vol-mnt/etc/nginx/nginx.conf-reverse-proxy-httpbin:/etc/nginx/nginx.conf tangfeixiong/nginx_modsecurity_build bash

root@791b96744117:/# /usr/local/nginx/sbin/nginx -g "daemon off;"
```

server
```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/libmodsecurity$ docker inspect nginx-modsecurity-build -f "{{.NetworkSettings.IPAddress}}"
172.17.0.4
```

no proxy
```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/libmodsecurity$ \
curl http://172.17.0.4/index.html
```

proxy
```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/libmodsecurity$ \
curl http://172.17.0.4/
```

Refer to [httpbin.org](http://httpbin.org/#/)

### compose

```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/libmodsecurity$ /Users/fanhongling/Downloads/99-mirror/linux-bin/docker-compose up
Creating network "libmodsecurity_waf" with the default driver
Creating libmodsecurity_httpbin_1 ... done
Creating nginx-modsecurity-demo   ... done
Attaching to libmodsecurity_httpbin_1, nginx-modsecurity-demo
httpbin_1            | [2021-02-25 07:11:46 +0000] [1] [INFO] Starting gunicorn 19.9.0
httpbin_1            | [2021-02-25 07:11:46 +0000] [1] [INFO] Listening at: http://0.0.0.0:80 (1)
httpbin_1            | [2021-02-25 07:11:46 +0000] [1] [INFO] Using worker: gevent
httpbin_1            | [2021-02-25 07:11:46 +0000] [8] [INFO] Booting worker with pid: 8
nginx-modsecurity-demo | {"transaction":{"client_ip":"172.25.0.1","time_stamp":"Thu Feb 25 07:13:06 2021","server_id":"b95acb6bfbe68eba1e98ebbd6d3d6afdbb21d7c6","client_port":60246,"host_ip":"172.25.0.2","host_port":80,"unique_id":"default-15dae819c50926670677d7793f8b423b","request":{"method":"GET","http_version":1.1,"uri":"/","headers":{"Host":"172.25.0.2","User-Agent":"curl/7.58.0","Accept":"*/*"}},"response":{"body":"<!DOCTYPE html>\n<html lang=\"en\">\n\n<head>\n    <meta charset=\"UTF-8\">\n    <title>httpbin.org</title>\n    <link href=\"https://fonts.googleapis.com/css?family=Open+Sans:400,700|Source+Code+Pro:300,600|Titillium+Web:400,600,700\"\n        rel=\"stylesheet\">\n    <link rel=\"stylesheet\" type=\"text/css\" href=\"/flasgger_static/swagger-ui.css\">\n    <link rel=\"icon\" type=\"image/png\" href=\"/static/favicon.ico\" sizes=\"64x64 32x32 16x16\" />\n    <style>\n        html {\n            box-sizing: border-box;\n            overflow: -moz-scrollbars-vertical;\n            overflow-y: scroll;\n        }\n\n        *,\n        *:before,\n        *:after {\n            box-sizing: inherit;\n        }\n\n        body {\n            margin: 0;\n            background: #fafafa;\n        }\n    </style>\n</head>\n\n<body>\n    <a href=\"https://github.com/requests/httpbin\" class=\"github-corner\" aria-label=\"View source on Github\">\n        <svg width=\"80\" height=\"80\" viewBox=\"0 0 250 250\" style=\"fill:#151513; color:#fff; position: absolute; top: 0; border: 0; right: 0;\"\n            aria-hidden=\"true\">\n            <path d=\"M0,0 L115,115 L130,115 L142,142 L250,250 L250,0 Z\"></path>\n            <path d=\"M128.3,109.0 C113.8,99.7 119.0,89.6 119.0,89.6 C122.0,82.7 120.5,78.6 120.5,78.6 C119.2,72.0 123.4,76.3 123.4,76.3 C127.3,80.9 125.5,87.3 125.5,87.3 C122.9,97.6 130.6,101.9 134.4,103.2\"\n                fill=\"currentColor\" style=\"transform-origin: 130px 106px;\" class=\"octo-arm\"></path>\n            <path d=\"M115.0,115.0 C114.9,115.1 118.7,116.5 119.8,115.4 L133.7,101.6 C136.9,99.2 139.9,98.4 142.2,98.6 C133.8,88.0 127.5,74.4 143.8,58.0 C148.5,53.4 154.0,51.2 159.7,51.0 C160.3,49.4 163.2,43.6 171.4,40.1 C171.4,40.1 176.1,42.5 178.8,56.2 C183.1,58.6 187.2,61.8 190.9,65.4 C194.5,69.0 197.7,73.2 200.1,77.6 C213.8,80.2 216.3,84.9 216.3,84.9 C212.7,93.1 206.9,96.0 205.4,96.6 C205.1,102.4 203.0,107.8 198.3,112.5 C181.9,128.9 168.3,122.5 157.7,114.1 C157.9,116.9 156.7,120.9 152.7,124.9 L141.0,136.5 C139.8,137.7 141.6,141.9 141.8,141.8 Z\"\n                fill=\"currentColor\" class=\"octo-body\"></path>\n        </svg>\n    </a>\n    <svg xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" style=\"position:absolute;width:0;height:0\">\n        <defs>\n            <symbol viewBox=\"0 0 20 20\" id=\"unlocked\">\n                <path d=\"M15.8 8H14V5.6C14 2.703 12.665 1 10 1 7.334 1 6 2.703 6 5.6V6h2v-.801C8 3.754 8.797 3 10 3c1.203 0 2 .754 2 2.199V8H4c-.553 0-1 .646-1 1.199V17c0 .549.428 1.139.951 1.307l1.197.387C5.672 18.861 6.55 19 7.1 19h5.8c.549 0 1.428-.139 1.951-.307l1.196-.387c.524-.167.953-.757.953-1.306V9.199C17 8.646 16.352 8 15.8 8z\"></path>\n            </symbol>\n\n            <symbol viewBox=\"0 0 20 20\" id=\"locked\">\n                <path d=\"M15.8 8H14V5.6C14 2.703 12.665 1 10 1 7.334 1 6 2.703 6 5.6V8H4c-.553 0-1 .646-1 1.199V17c0 .549.428 1.139.951 1.307l1.197.387C5.672 18.861 6.55 19 7.1 19h5.8c.549 0 1.428-.139 1.951-.307l1.196-.387c.524-.167.953-.757.953-1.306V9.199C17 8.646 16.352 8 15.8 8zM12 8H8V5.199C8 3.754 8.797 3 10 3c1.203 0 2 .754 2 2.199V8z\"\n                />\n            </symbol>\n\n            <symbol viewBox=\"0 0 20 20\" id=\"close\">\n                <path d=\"M14.348 14.849c-.469.469-1.229.469-1.697 0L10 11.819l-2.651 3.029c-.469.469-1.229.469-1.697 0-.469-.469-.469-1.229 0-1.697l2.758-3.15-2.759-3.152c-.469-.469-.469-1.228 0-1.697.469-.469 1.228-.469 1.697 0L10 8.183l2.651-3.031c.469-.469 1.228-.469 1.697 0 .469.469.469 1.229 0 1.697l-2.758 3.152 2.758 3.15c.469.469.469 1.229 0 1.698z\"\n                />\n            </symbol>\n\n            <symbol viewBox=\"0 0 20 20\" id=\"large-arrow\">\n                <path d=\"M13.25 10L6.109 2.58c-.268-.27-.268-.707 0-.979.268-.27.701-.27.969 0l7.83 7.908c.268.271.268.709 0 .979l-7.83 7.908c-.268.271-.701.27-.969 0-.268-.269-.268-.707 0-.979L13.25 10z\"\n                />\n            </symbol>\n\n            <symbol viewBox=\"0 0 20 20\" id=\"large-arrow-down\">\n                <path d=\"M17.418 6.109c.272-.268.709-.268.979 0s.271.701 0 .969l-7.908 7.83c-.27.268-.707.268-.979 0l-7.908-7.83c-.27-.268-.27-.701 0-.969.271-.268.709-.268.979 0L10 13.25l7.418-7.141z\"\n                />\n            </symbol>\n\n\n            <symbol viewBox=\"0 0 24 24\" id=\"jump-to\">\n                <path d=\"M19 7v4H5.83l3.58-3.59L8 6l-6 6 6 6 1.41-1.41L5.83 13H21V7z\" />\n            </symbol>\n\n            <symbol viewBox=\"0 0 24 24\" id=\"expand\">\n                <path d=\"M10 18h4v-2h-4v2zM3 6v2h18V6H3zm3 7h12v-2H6v2z\" />\n            </symbol>\n\n        </defs>\n    </svg>\n\n\n    <div id=\"swagger-ui\">\n        <div data-reactroot=\"\" class=\"swagger-ui\">\n            <div>\n                <div class=\"information-container wrapper\">\n                    <section class=\"block col-12\">\n                        <div class=\"info\">\n                            <hgroup class=\"main\">\n                                <h2 class=\"title\">httpbin.org\n                                    <small>\n                                        <pre class=\"version\">0.9.2</pre>\n                                    </small>\n                                </h2>\n                                <pre class=\"base-url\">[ Base URL: httpbin.org/ ]</pre>\n                            </hgroup>\n                            <div class=\"description\">\n                                <div class=\"markdown\">\n                                    <p>A simple HTTP Request &amp; Response Service.\n                                        <br>\n                                        <br>\n                                        <b>Run locally: </b>\n                                        <code>$ docker run -p 80:80 kennethreitz/httpbin</code>\n                                    </p>\n                                </div>\n                            </div>\n                            <div>\n                                <div>\n                                    <a href=\"https://kennethreitz.org\" target=\"_blank\">the developer - Website</a>\n                                </div>\n                                <a href=\"mailto:me@kennethreitz.org\">Send email to the developer</a>\n                            </div>\n                        </div>\n                        <!-- ADDS THE LOADER SPINNER -->\n                        <div class=\"loading-container\">\n                            <div class=\"loading\"></div>\n                        </div>\n\n                    </section>\n                </div>\n            </div>\n        </div>\n    </div>\n\n\n    <div class='swagger-ui'>\n        <div class=\"wrapper\">\n            <section class=\"clear\">\n                <span style=\"float: right;\">\n                    [Powered by\n                    <a target=\"_blank\" href=\"https://github.com/rochacbruno/flasgger\">Flasgger</a>]\n                    <br>\n                </span>\n            </section>\n        </div>\n    </div>\n\n\n\n    <script src=\"/flasgger_static/swagger-ui-bundle.js\"> </script>\n    <script src=\"/flasgger_static/swagger-ui-standalone-preset.js\"> </script>\n    <script src='/flasgger_static/lib/jquery.min.js' type='text/javascript'></script>\n    <script>\n\n        window.onload = function () {\n            \n\n            fetch(\"/spec.json\")\n                .then(function (response) {\n                    response.json()\n                        .then(function (json) {\n                            var current_protocol = window.location.protocol.slice(0, -1);\n                            if (json.schemes[0] != current_protocol) {\n                                // Switches scheme to the current in use\n                                var other_protocol = json.schemes[0];\n                                json.schemes[0] = current_protocol;\n                                json.schemes[1] = other_protocol;\n\n                            }\n                            json.host = window.location.host;  // sets the current host\n\n                            const ui = SwaggerUIBundle({\n                                spec: json,\n                                validatorUrl: null,\n                                dom_id: '#swagger-ui',\n                                deepLinking: true,\n                                jsonEditor: true,\n                                docExpansion: \"none\",\n                                apisSorter: \"alpha\",\n                                //operationsSorter: \"alpha\",\n                                presets: [\n                                    SwaggerUIBundle.presets.apis,\n                                    // yay ES6 modules ↘\n                                    Array.isArray(SwaggerUIStandalonePreset) ? SwaggerUIStandalonePreset : SwaggerUIStandalonePreset.default\n                                ],\n                                plugins: [\n                                    SwaggerUIBundle.plugins.DownloadUrl\n                                ],\n            \n            // layout: \"StandaloneLayout\"  // uncomment to enable the green top header\n        })\n\n        window.ui = ui\n\n        // uncomment to rename the top brand if layout is enabled\n        // $(\".topbar-wrapper .link span\").replaceWith(\"<span>httpbin</span>\");\n        })\n    })\n}\n    </script>  <div class='swagger-ui'>\n    <div class=\"wrapper\">\n        <section class=\"block col-12 block-desktop col-12-desktop\">\n            <div>\n\n                <h2>Other Utilities</h2>\n\n                <ul>\n                    <li>\n                        <a href=\"/forms/post\">HTML form</a> that posts to /post /forms/post</li>\n                </ul>\n\n                <br />\n                <br />\n            </div>\n        </section>\n    </div>\n</div>\n</body>\n\n</html>","http_code":200,"headers":{"Server":"nginx/1.19.6","Date":"Thu, 25 Feb 2021 07:13:06 GMT","Content-Length":"9593","Content-Type":"text/html; charset=utf-8","Access-Control-Allow-Origin":"*","Connection":"keep-alive","Access-Control-Allow-Credentials":"true"}},"producer":{"modsecurity":"ModSecurity v3.0.4 (Linux)","connector":"ModSecurity-nginx v1.0.1","secrules_engine":"DetectionOnly","components":["OWASP_CRS/3.3.0\""]},"messages":[{"message":"Host header is a numeric IP address","details":{"match":"Matched \"Operator `Rx' with parameter `^[\\d.:]+$' against variable `REQUEST_HEADERS:Host' (Value: `172.25.0.2' )","reference":"o0,10v21,10","ruleId":"920350","file":"/etc/nginx/owasp-modsecurity-crs/rules/REQUEST-920-PROTOCOL-ENFORCEMENT.conf","lineNumber":"718","data":"172.25.0.2","severity":"4","ver":"OWASP_CRS/3.3.0","rev":"","tags":["application-multi","language-multi","platform-multi","attack-protocol","paranoia-level/1","OWASP_CRS","capec/1000/210/272","PCI/6.5.10"],"maturity":"0","accuracy":"0"}}]}}
nginx-modsecurity-demo | {"transaction":{"client_ip":"172.25.0.1","time_stamp":"Thu Feb 25 07:13:18 2021","server_id":"b95acb6bfbe68eba1e98ebbd6d3d6afdbb21d7c6","client_port":60322,"host_ip":"172.25.0.2","host_port":80,"unique_id":"default-394febecdf2713c57b09447c6542f700","request":{"method":"GET","http_version":1.1,"uri":"/get","headers":{"Host":"172.25.0.2","User-Agent":"curl/7.58.0","Accept":"*/*"}},"response":{"body":"","http_code":200,"headers":{"Server":"nginx/1.19.6","Date":"Thu, 25 Feb 2021 07:13:18 GMT","Content-Length":"203","Content-Type":"application/json","Access-Control-Allow-Origin":"*","Connection":"keep-alive","Access-Control-Allow-Credentials":"true"}},"producer":{"modsecurity":"ModSecurity v3.0.4 (Linux)","connector":"ModSecurity-nginx v1.0.1","secrules_engine":"DetectionOnly","components":["OWASP_CRS/3.3.0\""]},"messages":[{"message":"Host header is a numeric IP address","details":{"match":"Matched \"Operator `Rx' with parameter `^[\\d.:]+$' against variable `REQUEST_HEADERS:Host' (Value: `172.25.0.2' )","reference":"o0,10v24,10","ruleId":"920350","file":"/etc/nginx/owasp-modsecurity-crs/rules/REQUEST-920-PROTOCOL-ENFORCEMENT.conf","lineNumber":"718","data":"172.25.0.2","severity":"4","ver":"OWASP_CRS/3.3.0","rev":"","tags":["application-multi","language-multi","platform-multi","attack-protocol","paranoia-level/1","OWASP_CRS","capec/1000/210/272","PCI/6.5.10"],"maturity":"0","accuracy":"0"}}]}}
^CGracefully stopping... (press Ctrl+C again to force)
Stopping libmodsecurity_httpbin_1 ... done
Stopping nginx-modsecurity-demo   ... done
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/libmodsecurity$ /Users/fanhongling/Downloads/99-mirror/linux-bin/docker-compose down
Removing libmodsecurity_httpbin_1 ... done
Removing nginx-modsecurity-demo   ... done
Removing network libmodsecurity_waf
```