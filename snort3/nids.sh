#!/bin/bash -e

remote_addr='47.111.106.160:8093'

docker_container_addr()
{
	c=${1-"httpbin"}
	ip=$(docker inspect $c -f '{{.NetworkSettings.IPAddress}}')
	echo $ip
}

ip=$(docker_container_addr)
ip="172.28.128.3"
port=${2-"80"}

icmp_ping()
{
    ip=$(docker_container_addr)
    ping -c3 $ip
}

http_react_from_outbound()
{	
	for number in {1..3}; do	
	    curl -i http://$addr/
	    # curl -iv http://$addr/mnt/ --form 'vulnerability=malicious' --form 'sample=@snort3-docker.txt'
	done
}

http_react_to_inbound()
{	
	for number in {1..1}; do	
	    curl -i http://$addr/anything/react
	    # curl -iv http://$addr/mnt/ --form 'vulnerability=malicious' --form 'sample=@snort3-docker.txt'
	done
}

http_uri_curl()
{
	ip=$(docker_container_addr)
	port=${1-"80"}
	addr=${ip}:${port}
	
	for number in {1..2}; do	
	    curl -i http://$addr/anything?anthing#anything
	    # curl -iv http://$addr/mnt/ --form 'vulnerability=malicious' --form 'sample=@snort3-docker.txt'
	done
}

http_post_json()
{
	ip=$(docker_container_addr)
	port=${1-"80"}
	addr=${ip}:${port}
	
	curl -i http://$addr/anything -XPOST -H "Content-Type: application/json" -d '
anything	
'
}

http_post_form()
{
	ip=$(docker_container_addr)
	port=${1-"80"}
	addr=${ip}:${port}
	
	for number in {1..2}; do	
	    curl -i http://$addr/anything/form -XPOST --form 'name=clusterA' &
	done
	wait
	# curl -i http://$remote_addr/path/to/form -XPOST --form 'name=clusterA'
}

http_head_useragent_curl()
{
	ip=$(docker_container_addr)
	port=${1-"80"}
	for number in {1..20}; do	
	    curl --user-agent "fake" -iv http://${ip}:${port}/get
	    # curl --user-agent "malicious" -iv http://${ip}:${port}/mnt/
	done
}

alert_http_useragent_wget()
{
	ip=$(docker_container_addr)
	port=${1-"48080"}
	for number in {1..80}; do	
	    wget --user-agent -iv http://${ip}:${port}/mnt/
	    curl --user-agent "fake" -iv http://${ip}:${port}/mnt/
	done
}

http_uri_pcre_curl()
{
	ip=$(docker_container_addr)
	port=${1-"80"}
	addr=${ip}:${port}
	for number in {1..2}; do	
	    curl -v http://${addr}/get?/pcre=$RANDOM
		# curl -iv http://$addr/post --form "/pcre=$RANDOM"
	done
}

http_url_buffer_lt_20()
{
	ip=$(docker_container_addr)
	port=${1-"48080"}
	for number in {1..80}; do	
	    curl -iv http://${ip}:${port}/mnt/?abc
	done
}

http_download_file()
{
	ip=$(docker_container_addr)
	port=${1-"48080"}
	addr=${ip}:${port}
	
	for number in {1..100}; do	
	    curl http://$addr/mnt/malicious.txt
	done
}

http_get_curl()
{
	ip=$(docker_container_addr)
	port=${1-"80"}
	addr=${ip}:${port}
	
	curl -i http://$addr/get
}

tcp_curl()
{
	ip=$(docker_container_addr)
	port=${1-"80"}
	addr=${ip}:${port}
	
	for number in {1..20}; do	
	    curl -iv http://$addr/anything/13701234567	&
	done
	wait
}

ip_curl()
{
	ip=$(docker_container_addr)
	port=${1-"80"}
	addr=${ip}:${port}
	
	for number in {1..12}; do	
		curl -iv http://$addr/anything/13801234567	&
		# curl -iv http://$addr/anything/user@example.com &
	done
	wait
}

ip_netcat()
{
	ip=$(docker_container_addr)
	port=${1-"80"}
	addr=${ip}:${port}
	
	echo -e "GET /anything/anything HTTP/1.1 \n
Host: ${ip} \n
\n\n
" | nc -v $ip $port
}


cmds=${1:="help"}
addr=${ip}:${port}

case $cmds in
    icmp)  icmp_ping
	    ;;
	ips.react)  http_react_to_inbound
	    ;;
	http.uri)  http_uri_curl
		;;
	http.post.form)
	    http_post_form
		;;
	http.get)
	    http_get_curl
		;;
	http.post.json)
	    http_post_json
		;;
	http.head.user-agent)
	    http_head_useragent_curl
		;;
	http.uri.pcre)
	    http_uri_pcre_curl
		;;
	alert.http-url.buffer)
	    http_url_buffer_lt_20
		;;
	alert/http.get.file)
	    http_download_file
		;;
    tcp)
	    tcp_curl
	    ;;
    ip)
	    ip_curl
	    ;;
    *)
	    echo "Execution: $(basename $0) <command>"
		;;
esac

