#!/bin/bash -e

docker_container_addr()
{
	c=${1-"gofileserver"}
	ip=$(docker inspect $c -f '{{.NetworkSettings.IPAddress}}')
	echo $ip
}

alert_icmp()
{
    ip=$(docker_container_addr)
    ping -c3 $ip
}

alert_http_uri()
{
	ip=$(docker_container_addr)
	port=${1-"48080"}
	addr=${ip}:${port}
	
	for number in {1..100}; do	
	    curl -iv http://$addr/?malicious=
	    curl -iv http://$addr/mnt/ --form 'vulnerability=malicious' --form 'sample=@snort3-docker.txt'
	done
}

alert_http_form()
{
	ip=$(docker_container_addr)
	port=${1-"48080"}
	addr=${ip}:${port}
	
	curl -iv http://$addr/malicious=/?abcde --form 'foo=abcdef'
}

alert_http_useragent_curl()
{
	ip=$(docker_container_addr)
	port=${1-"48080"}
	for number in {1..80}; do	
	    curl -iv http://${ip}:${port}/mnt/
	    curl --user-agent "fake" -iv http://${ip}:${port}/mnt/
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

alert_http_pcre()
{
	ip=$(docker_container_addr)
	port=${1-"48080"}
	addr=${ip}:${port}
	for number in {1..80}; do	
	    curl -iv http://${addr}/mnt/?/pcre=abc
		curl -iv http://$addr/mnt/?pcre --form 'pcre=123'
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


cmds=${1:="help"}

case $cmds in
    alert.icmp)
	    alert_icmp
		;;
	alert.http.uri)
	    alert_http_uri
		;;
	alert.http.post.form)
	    alert_http_form
		;;
	alert.http-head.user-agent.curl)
	    alert_http_useragent_curl
		;;
	alert.http.pcre)
	    alert_http_pcre
		;;
	alert.http-url.buffer)
	    http_url_buffer_lt_20
		;;
	alert/http.get.file)
	    http_download_file
		;;
    *)
	    echo "Execution: $(basename $0) <command>"
esac

