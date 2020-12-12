
### POD

Create POD
```
[cloud@develop3 snort3]$ kubectl apply -f snort-lab.yaml 
pod/snort-lab created
```

Delete POD
```
[cloud@develop3 snort3]$ kubectl delete -f snort-lab.yaml
pod/snort-lab created
```

Get POD
```
[cloud@develop3 snort3]$ kubectl get pod snort-lab -o wide --show-labels
NAME        READY   STATUS    RESTARTS   AGE   IP              NODE       NOMINATED NODE   READINESS GATES   LABELS
snort-lab   2/2     Running   0          91s   192.168.0.146   develop3   <none>           <none>            app=snort-lab
```


### Snort

Enter Snort container
```
[cloud@develop3 snort3]$ kubectl exec -ti snort-lab -c snort -- bash
root@snort-lab:/# exit
exit
```


### Network namespace

tcpdump
```
[cloud@develop3 snort3]$ docker ps -f label='app=snort-lab'
CONTAINER ID        IMAGE                  COMMAND             CREATED             STATUS              PORTS               NAMES
6a2a66cc7bab        k8s.gcr.io/pause:3.1   "/pause"            About an hour ago   Up About an hour                        k8s_POD_snort-lab_default_e9a83ad5-208f-4430-ab5b-d170f69a96d6_0

[cloud@develop3 snort3]$ dockerContainerID=$(docker ps -f label='app=snort-lab' -q)

[cloud@develop3 snort3]$ targetPID=$(docker inspect $dockerContainerID -f '{{.State.Pid}}')

[cloud@develop3 snort3]$ sudo nsenter --target $targetPID --net

[root@develop3 snort3]# ethtool -k eth0
Features for eth0:
rx-checksumming: on
tx-checksumming: on
	tx-checksum-ipv4: off [fixed]
	tx-checksum-ip-generic: on
	tx-checksum-ipv6: off [fixed]
	tx-checksum-fcoe-crc: off [fixed]
	tx-checksum-sctp: on
scatter-gather: on
	tx-scatter-gather: on
	tx-scatter-gather-fraglist: on
tcp-segmentation-offload: on
	tx-tcp-segmentation: on
	tx-tcp-ecn-segmentation: on
	tx-tcp6-segmentation: on
	tx-tcp-mangleid-segmentation: on
udp-fragmentation-offload: on
generic-segmentation-offload: on
generic-receive-offload: on
large-receive-offload: off [fixed]


[root@develop3 snort3]# tcpdump -nnn -vvv -i eth0
tcpdump: listening on eth0, link-type EN10MB (Ethernet), capture size 262144 bytes


[root@develop3 snort3]# exit
登出
[cloud@develop3 snort3]$
```



### Log

attach tty
```
[cloud@develop3 snort3]$ kubectl attach snort-lab -c snort -t
```

follow stdout
```
[cloud@develop3 snort3]$ kubectl logs snort-lab -c snort --follow
--------------------------------------------------
o")~   Snort++ 3.0.3-5
--------------------------------------------------
Loading /etc/snort/snort.lua:
Loading snort_defaults.lua:
Finished snort_defaults.lua:
Loading file_magic.lua:
Finished file_magic.lua:
	Lua Whitelist Keywords for /etc/snort/snort.lua:
		default_classifications, default_ftp_server, default_gtp,
		default_hi_port_scan, default_low_port_scan, default_med_port_scan,
		default_references, default_smtp, default_variables, default_wizard,
		file_magic, ftp_command_specs, gtp_v0_info, gtp_v0_msg, gtp_v1_info,
		gtp_v1_msg, gtp_v2_info, gtp_v2_msg, http_methods, icmp_hi_sweep,
		icmp_low_sweep, icmp_med_sweep, ip_hi_decoy, ip_hi_dist, ip_hi_proto,
		ip_hi_sweep, ip_low_decoy, ip_low_dist, ip_low_proto, ip_low_sweep,
		ip_med_decoy, ip_med_dist, ip_med_proto, ip_med_sweep, netflow_versions,
		sip_methods, smtp_default_alt_max_command_lines, tcp_hi_decoy, tcp_hi_dist,
		tcp_hi_ports, tcp_hi_sweep, tcp_low_decoy, tcp_low_dist, tcp_low_ports,
		tcp_low_sweep, tcp_med_decoy, tcp_med_dist, tcp_med_ports, tcp_med_sweep,
		telnet_commands, udp_hi_decoy, udp_hi_dist, udp_hi_ports, udp_hi_sweep,
		udp_low_decoy, udp_low_dist, udp_low_ports, udp_low_sweep, udp_med_decoy,
		udp_med_dist, udp_med_ports, udp_med_sweep
	ips
	active
	alerts
	daq
	decode
	host_cache
	host_tracker
	hosts
	network
	packets
	process
	search_engine
	so_proxy
	stream
	stream_ip
	stream_icmp
	stream_tcp
	stream_udp
	stream_user
	stream_file
	arp_spoof
	back_orifice
	dnp3
	http_inspect
	imap
	normalizer
	rpc_decode
	ssh
	telnet
	dce_udp
	dce_http_proxy
	gtp_inspect
	port_scan
	smtp
	ftp_server
	ftp_client
	binder
	trace
	unified2
	log_codecs
	alert_syslog
	alert_sfsocket
	alert_json
	rewrite
	classifications
	references
	perf_monitor
	profiler
	latency
	wizard
	appid
	file_id
	ftp_data
	dce_http_server
	dce_tcp
	dce_smb
	ssl
	sip
	pop
	modbus
	http2_inspect
	dns
	output
Finished /etc/snort/snort.lua:
Loading rule args:
Loading /usr/local/etc/snort/rules/local.rules:
Finished /usr/local/etc/snort/rules/local.rules:
Finished rule args:
--------------------------------------------------
rule counts
       total rules loaded: 1
               text rules: 1
            option chains: 1
            chain headers: 1
--------------------------------------------------
port rule counts
             tcp     udp    icmp      ip
     any       0       0       1       0
   total       0       0       1       0
--------------------------------------------------
ips policies rule stats
              id  loaded  shared enabled    file
               0       1       0       1    /etc/snort/snort.lua
--------------------------------------------------
Inspection Policy : policy id 0 : /etc/snort/snort.lua
--------------------------------------------------
appid:
         app_stats_period: 300
  app_stats_rollover_size: 20971520
       list_odp_detectors: disabled
    tp_appid_stats_enable: disabled
     tp_appid_config_dump: disabled
         log_all_sessions: disabled
                log_stats: disabled
                   memcap: 1048576
--------------------------------------------------
arp_spoof:
--------------------------------------------------
back_orifice:
--------------------------------------------------
binder:
                 bindings:
                           { when = { role = server, proto = udp, ports = 53 },
                             use = { type = dns } }
                           { when = { role = server, proto = tcp, ports = 53 },
                             use = { type = dns } }
                           { when = { role = server, proto = tcp, ports = 111 },
                             use = { type = rpc_decode } }
                           { when = { role = server, proto = tcp, ports = 502 },
                             use = { type = modbus } }
                           { when = { role = server, proto = tcp, ports = 2123 2152 3386 },
                             use = { type = gtp_inspect } }
                           { when = { service = dcerpc, proto = tcp },
                             use = { type = dce_tcp } }
                           { when = { service = dcerpc, proto = udp },
                             use = { type = dce_udp } }
                           { when = { service = netbios-ssn },
                             use = { type = dce_smb } }
                           { when = { service = dce_http_server },
                             use = { type = dce_http_server } }
                           { when = { service = dce_http_proxy },
                             use = { type = dce_http_proxy } }
                           { when = { service = dnp3 },
                             use = { type = dnp3 } }
                           { when = { service = dns },
                             use = { type = dns } }
                           { when = { service = ftp },
                             use = { type = ftp_server } }
                           { when = { service = ftp-data },
                             use = { type = ftp_data } }
                           { when = { service = gtp },
                             use = { type = gtp_inspect } }
                           { when = { service = imap },
                             use = { type = imap } }
                           { when = { service = http },
                             use = { type = http_inspect } }
                           { when = { service = http2 },
                             use = { type = http2_inspect } }
                           { when = { service = modbus },
                             use = { type = modbus } }
                           { when = { service = pop3 },
                             use = { type = pop } }
                           { when = { service = ssh },
                             use = { type = ssh } }
                           { when = { service = sip },
                             use = { type = sip } }
                           { when = { service = smtp },
                             use = { type = smtp } }
                           { when = { service = ssl },
                             use = { type = ssl } }
                           { when = { service = sunrpc },
                             use = { type = rpc_decode } }
                           { when = { service = telnet },
                             use = { type = telnet } }
                           { when = { },
                             use = { type = wizard } }
--------------------------------------------------
dce_http_proxy:
--------------------------------------------------
dce_http_server:
--------------------------------------------------
dce_smb:
             limit_alerts: enabled
           disable_defrag: disabled
             max_frag_len: 65535
                   policy: WinXP
     reassemble_threshold: 0
   smb_fingerprint_policy: disabled
            smb_max_chain: 3
         smb_max_compound: 3
       valid_smb_versions: all
           smb_file_depth: 16384
       smb_invalid_shares: none
          smb_legacy_mode: disabled
           smb_max_credit: 8192
--------------------------------------------------
dce_tcp:
             limit_alerts: enabled
           disable_defrag: disabled
             max_frag_len: 65535
                   policy: WinXP
     reassemble_threshold: 0
--------------------------------------------------
dce_udp:
             limit_alerts: enabled
           disable_defrag: disabled
             max_frag_len: 65535
--------------------------------------------------
dnp3:
                check_crc: disabled
--------------------------------------------------
dns:
--------------------------------------------------
file_id:
              enable_type: enabled
               type_depth: 1460
         enable_signature: disabled
     block_timeout_lookup: disabled
           enable_capture: disabled
           lookup_timeout: 2
         max_files_cached: 65536
       max_files_per_flow: 128
          show_data_depth: 100
               trace_type: disabled
          trace_signature: disabled
             trace_stream: disabled
            verdict_delay: 0
--------------------------------------------------
ftp_client:
                   bounce: disabled
 ignore_telnet_erase_cmds: disabled
             max_resp_len: 4294967295
              telnet_cmds: disabled
--------------------------------------------------
ftp_data:
--------------------------------------------------
ftp_server:
          check_encrypted: disabled
        def_max_param_len: 100
        encrypted_traffic: disabled
         ignore_data_chan: disabled
 ignore_telnet_erase_cmds: disabled
              telnet_cmds: disabled
               print_cmds: disabled
--------------------------------------------------
gtp_inspect:
--------------------------------------------------
http2_inspect:
--------------------------------------------------
http_inspect:
            request_depth: -1 (unlimited)
           response_depth: -1 (unlimited)
                    unzip: enabled
            normalize_utf: enabled
           decompress_pdf: disabled
           decompress_swf: disabled
           decompress_zip: disabled
      detained_inspection: disabled
         script_detection: disabled
     normalize_javascript: disabled
max_javascript_whitespaces: 200
                percent_u: disabled
                     utf8: enabled
           utf8_bare_byte: disabled
              iis_unicode: disabled
    iis_unicode_code_page: 1252
        iis_double_decode: enabled
      oversize_dir_length: 300
       backslash_to_slash: enabled
            plus_to_space: enabled
            simplify_path: enabled
              xff_headers: x-forwarded-for true-client-ip
--------------------------------------------------
imap:
         b64_decode_depth: -1 (unlimited)
          qp_decode_depth: -1 (unlimited)
          uu_decode_depth: -1 (unlimited)
      bitenc_decode_depth: -1 (unlimited)
           decompress_pdf: disabled
           decompress_swf: disabled
           decompress_zip: disabled
--------------------------------------------------
modbus:
--------------------------------------------------
normalizer:
                      ip4: disabled
                      ip6: disabled
                    icmp4: disabled
                    icmp6: disabled
                      tcp: enabled
                      tcp: { ecn = disabled, block = disabled, rsv = disabled, pad = disabled, req_urg
                           = disabled, req_pay = disabled, req_urp = disabled, urp = disabled, ips =
                           enabled, trim = disabled }
--------------------------------------------------
perf_monitor:
                     base: enabled
                      cpu: disabled
                  summary: disabled
                     flow: disabled
                  flow_ip: disabled
                  packets: 10000
                  seconds: 60
            max_file_size: 1073741312
                   output: file
                   format: csv
--------------------------------------------------
pop:
         b64_decode_depth: -1 (unlimited)
          qp_decode_depth: -1 (unlimited)
          uu_decode_depth: -1 (unlimited)
      bitenc_decode_depth: -1 (unlimited)
           decompress_pdf: disabled
           decompress_swf: disabled
           decompress_zip: disabled
--------------------------------------------------
port_scan:
                   memcap: 10485760
                   protos: all
               scan_types: all
                alert_all: disabled
        include_midstream: disabled
               tcp_window: 90
               udp_window: 90
                ip_window: 90
              icmp_window: 90
--------------------------------------------------
rpc_decode:
--------------------------------------------------
sip:
      ignore_call_channel: disabled
          max_call_id_len: 256
          max_contact_len: 256
          max_content_len: 1024
              max_dialogs: 4
             max_from_len: 256
      max_requestName_len: 20
               max_to_len: 256
              max_uri_len: 256
              max_via_len: 1024
                  methods: invite cancel ack bye register options
--------------------------------------------------
smtp:
                normalize: none
           normalize_cmds: ATRN AUTH BDAT DATA DEBUG EHLO EMAL ESAM ESND ESOM ETRN EVFY EXPN HELO HELP
                           IDENT MAIL NOOP ONEX QUEU QUIT RCPT RSET SAML SEND STARTTLS SOML TICK TIME
                           TURN TURNME VERB VRFY X-EXPS XADR XAUTH XCIR XEXCH50 XGEN XLICENSE
                           X-LINK2STATE XQUE XSTA XTRN XUSR CHUNKING X-ADAT X-DRCP X-ERCP X-EXCH50
          ignore_tls_data: disabled
     max_command_line_len: 512
 alt_max_command_line_len: { {ATRN, 255}, {AUTH, 246}, {BDAT, 255}, {DATA, 246}, {DEBUG, 255}, {EHLO,
                           500}, {EMAL, 255}, {ESAM, 255}, {ESND, 255}, {ESOM, 255}, {ETRN, 500},
                           {EVFY, 255}, {EXPN, 255}, {HELO, 500}, {HELP, 500}, {IDENT, 255}, {MAIL,
                           260}, {NOOP, 255}, {ONEX, 246}, {QUEU, 246}, {QUIT, 246}, {RCPT, 300},
                           {RSET, 255}, {SAML, 246}, {SEND, 246}, {SIZE, 255}, {STARTTLS, 246}, {SOML,
                           246}, {TICK, 246}, {TIME, 246}, {TURN, 246}, {TURNME, 246}, {VERB, 246},
                           {VRFY, 255}, {X-EXPS, 246}, {XADR, 246}, {XAUTH, 246}, {XCIR, 246},
                           {XEXCH50, 246}, {XGEN, 246}, {XLICENSE, 246}, {X-LINK2STATE, 246}, {XQUE,
                           246}, {XSTA, 246}, {XTRN, 246}, {XUSR, 246} }
      max_header_line_len: 1000
max_auth_command_line_len: 1000
 max_response_line_length: 512
              xlink2state: alert
             invalid_cmds: none
                auth_cmds: AUTH X-EXPS XAUTH
         binary_data_cmds: BDAT XEXCH50
                data_cmds: DATA
               valid_cmds: ATRN AUTH BDAT DATA DEBUG EHLO EMAL ESAM ESND ESOM ETRN EVFY EXPN HELO HELP
                           IDENT MAIL NOOP ONEX QUEU QUIT RCPT RSET SAML SEND SIZE STARTTLS SOML TICK
                           TIME TURN TURNME VERB VRFY X-EXPS XADR XAUTH XCIR XEXCH50 XGEN XLICENSE
                           X-LINK2STATE XQUE XSTA XTRN XUSR * CHUNKING X-ADAT X-DRCP X-ERCP X-EXCH50
         b64_decode_depth: -1 (unlimited)
          qp_decode_depth: -1 (unlimited)
          uu_decode_depth: -1 (unlimited)
      bitenc_decode_depth: -1 (unlimited)
              ignore_data: disabled
           decompress_pdf: disabled
           decompress_swf: disabled
           decompress_zip: disabled
             log_mailfrom: disabled
               log_rcptto: disabled
             log_filename: enabled
           log_email_hdrs: disabled
--------------------------------------------------
so_proxy:
--------------------------------------------------
ssh:
    max_encrypted_packets: 25
         max_client_bytes: 19600
   max_server_version_len: 80
--------------------------------------------------
ssl:
            trust_servers: disabled
     max_heartbeat_length: 0
--------------------------------------------------
stream:
            ip_frags_only: disabled
                max_flows: 476288
          pruning_timeout: 30
                 ip_cache: { idle_timeout = 180, cap_weight = 0 }
                tcp_cache: { idle_timeout = 3600, cap_weight = 11000 }
                udp_cache: { idle_timeout = 180, cap_weight = 0 }
               icmp_cache: { idle_timeout = 180, cap_weight = 0 }
               user_cache: { idle_timeout = 180, cap_weight = 0 }
               file_cache: { idle_timeout = 180, cap_weight = 32 }
--------------------------------------------------
stream_file:
                   upload: disabled
--------------------------------------------------
stream_icmp:
          session_timeout: 30
--------------------------------------------------
stream_ip:
                max_frags: 8192
             max_overlaps: 0
          min_frag_length: 0
                  min_ttl: 1
                   policy: linux
          session_timeout: 30
--------------------------------------------------
stream_tcp:
             flush_factor: 0
                  max_pdu: 16384
               max_window: 0
                   no_ack: disabled
            overlap_limit: 0
                   policy: bsd
              queue_limit: { max_bytes = 1048576, max_segments = 2621 }
         reassemble_async: enabled
             require_3whs: -1 (disabled)
          session_timeout: 30
           small_segments: { count = 0, maximum_size = 0 }
               track_only: disabled
--------------------------------------------------
stream_udp:
          session_timeout: 30
--------------------------------------------------
stream_user:
          session_timeout: 30
--------------------------------------------------
telnet:
        ayt_attack_thresh: -1
          check_encrypted: disabled
        encrypted_traffic: disabled
                normalize: disabled
--------------------------------------------------
wizard:
--------------------------------------------------
pcap DAQ configured to passive.
--------------------------------------------------
host_cache
    memcap: 8388608 bytes
Commencing packet processing
++ [0] eth0
Instance 0 daq pool size: 256
Instance 0 daq batch size: 64
{ "timestamp" : "12/11-06:23:51.078597", "pkt_num" : 3, "proto" : "ICMP", "pkt_gen" : "raw", "pkt_len" : 84, "dir" : "C2S", "src_ap" : "10.0.1.21:0", "dst_ap" : "192.168.0.170:0", "rule" : "1:10000002:0", "action" : "allow" }
{ "timestamp" : "12/11-06:23:51.078630", "pkt_num" : 6, "proto" : "ICMP", "pkt_gen" : "raw", "pkt_len" : 84, "dir" : "S2C", "src_ap" : "192.168.0.170:0", "dst_ap" : "10.0.1.21:0", "rule" : "1:10000002:0", "action" : "allow" }
{ "timestamp" : "12/11-06:23:52.077968", "pkt_num" : 7, "proto" : "ICMP", "pkt_gen" : "raw", "pkt_len" : 84, "dir" : "C2S", "src_ap" : "10.0.1.21:0", "dst_ap" : "192.168.0.170:0", "rule" : "1:10000002:0", "action" : "allow" }
{ "timestamp" : "12/11-06:23:52.077985", "pkt_num" : 8, "proto" : "ICMP", "pkt_gen" : "raw", "pkt_len" : 84, "dir" : "S2C", "src_ap" : "192.168.0.170:0", "dst_ap" : "10.0.1.21:0", "rule" : "1:10000002:0", "action" : "allow" }
{ "timestamp" : "12/11-06:23:53.077986", "pkt_num" : 9, "proto" : "ICMP", "pkt_gen" : "raw", "pkt_len" : 84, "dir" : "C2S", "src_ap" : "10.0.1.21:0", "dst_ap" : "192.168.0.170:0", "rule" : "1:10000002:0", "action" : "allow" }
{ "timestamp" : "12/11-06:23:53.078005", "pkt_num" : 10, "proto" : "ICMP", "pkt_gen" : "raw", "pkt_len" : 84, "dir" : "S2C", "src_ap" : "192.168.0.170:0", "dst_ap" : "10.0.1.21:0", "rule" : "1:10000002:0", "action" : "allow" }
{ "timestamp" : "12/11-06:31:46.442773", "pkt_num" : 11, "proto" : "ICMP", "pkt_gen" : "raw", "pkt_len" : 84, "dir" : "C2S", "src_ap" : "10.0.1.21:0", "dst_ap" : "192.168.0.170:0", "rule" : "1:10000002:0", "action" : "allow" }
pkt:3	    gid:1    sid:10000002    rev:0	
eth(DLT):  EE:EE:EE:EE:EE:EE -> B2:FD:83:0A:B4:6C  type:0x0800
ipv4(0x0800):  10.0.1.21 -> 192.168.0.170
	Next:0x01 TTL:64 TOS:0x0 ID:3841 IpLen:20 DgmLen:84 DF
icmp4(0x01):  Type:8  Code:0  
	ID:10398   Seq:1  ECHO

snort.raw[56]:
- - - - - - - - - - - -  - - - - - - - - - - - -  - - - - - - - - -
77 10 D3 5F 00 00 00 00  D9 32 01 00 00 00 00 00  w.._.... .2......
10 11 12 13 14 15 16 17  18 19 1A 1B 1C 1D 1E 1F  ........ ........
20 21 22 23 24 25 26 27  28 29 2A 2B 2C 2D 2E 2F   !"#$%&' ()*+,-./
30 31 32 33 34 35 36 37                           01234567 
- - - - - - - - - - - -  - - - - - - - - - - - -  - - - - - - - - -

pkt:6	    gid:1    sid:10000002    rev:0	
eth(DLT):  B2:FD:83:0A:B4:6C -> EE:EE:EE:EE:EE:EE  type:0x0800
ipv4(0x0800):  192.168.0.170 -> 10.0.1.21
	Next:0x01 TTL:64 TOS:0x0 ID:758 IpLen:20 DgmLen:84
icmp4(0x01):  Type:0  Code:0  
	ID:10398  Seq:1  ECHO REPLY

snort.raw[56]:
- - - - - - - - - - - -  - - - - - - - - - - - -  - - - - - - - - -
77 10 D3 5F 00 00 00 00  D9 32 01 00 00 00 00 00  w.._.... .2......
10 11 12 13 14 15 16 17  18 19 1A 1B 1C 1D 1E 1F  ........ ........
20 21 22 23 24 25 26 27  28 29 2A 2B 2C 2D 2E 2F   !"#$%&' ()*+,-./
30 31 32 33 34 35 36 37                           01234567 
- - - - - - - - - - - -  - - - - - - - - - - - -  - - - - - - - - -

pkt:7	    gid:1    sid:10000002    rev:0	
eth(DLT):  EE:EE:EE:EE:EE:EE -> B2:FD:83:0A:B4:6C  type:0x0800
ipv4(0x0800):  10.0.1.21 -> 192.168.0.170
^C

```
