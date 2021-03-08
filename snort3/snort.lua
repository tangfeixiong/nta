---------------------------------------------------------------------------
-- Snort++ configuration
---------------------------------------------------------------------------

-- there are over 200 modules available to tune your policy.
-- many can be used with defaults w/o any explicit configuration.
-- use this conf as a template for your specific configuration.

-- 1. configure defaults
-- 2. configure inspection
-- 3. configure bindings
-- 4. configure performance
-- 5. configure detection
-- 6. configure filters
-- 7. configure outputs
-- 8. configure tweaks

---------------------------------------------------------------------------
-- 1. configure defaults
---------------------------------------------------------------------------

-- HOME_NET and EXTERNAL_NET must be set now
-- setup the network addresses you are protecting
----HOME_NET = 'any'
HOME_NET = 'any'

-- set up the external network addresses.
-- (leave as "any" in most situations)
EXTERNAL_NET = 'any'

include 'snort_defaults.lua'
include 'file_magic.lua'

---------------------------------------------------------------------------
-- 2. configure inspection
---------------------------------------------------------------------------

-- mod = { } uses internal defaults
-- you can see them with snort --help-module mod

-- mod = default_mod uses external defaults
-- you can see them in snort_defaults.lua

-- the following are quite capable with defaults:

stream = { }
stream_ip = { }
stream_icmp = { }
stream_tcp = { }
stream_udp = { }
stream_user = { }
stream_file = { }

arp_spoof = { }
back_orifice = { }
dnp3 = { }
dns = { }
http_inspect = { }
http2_inspect = { }
imap = { }
modbus = { }
normalizer = { }
pop = { }
rpc_decode = { }
sip = { }
ssh = { }
ssl = { }
telnet = { }

dce_smb = { }
dce_tcp = { }
dce_udp = { }
dce_http_proxy = { }
dce_http_server = { }

-- see snort_defaults.lua for default_*
gtp_inspect = default_gtp
port_scan = default_med_port_scan
smtp = default_smtp

ftp_server = default_ftp_server
ftp_client = { }
ftp_data = { }

-- see file_magic.lua for file id rules
file_id = { file_rules = file_magic }

-- the following require additional configuration to be fully effective:

appid =
{
    -- appid requires this to use appids in rules
    --app_detector_dir = 'directory to load appid detectors from'
}

--[[
reputation =
{
    -- configure one or both of these, then uncomment reputation
    --blacklist = 'blacklist file name with ip lists'
    --whitelist = 'whitelist file name with ip lists'
}
--]]

---------------------------------------------------------------------------
-- 3. configure bindings
---------------------------------------------------------------------------

wizard = default_wizard

binder =
{
    -- port bindings required for protocols without wizard support
    { when = { proto = 'udp', ports = '53', role='server' },  use = { type = 'dns' } },
    { when = { proto = 'tcp', ports = '53', role='server' },  use = { type = 'dns' } },
    { when = { proto = 'tcp', ports = '111', role='server' }, use = { type = 'rpc_decode' } },
    { when = { proto = 'tcp', ports = '502', role='server' }, use = { type = 'modbus' } },
    { when = { proto = 'tcp', ports = '2123 2152 3386', role='server' }, use = { type = 'gtp_inspect' } },

    { when = { proto = 'tcp', service = 'dcerpc' }, use = { type = 'dce_tcp' } },
    { when = { proto = 'udp', service = 'dcerpc' }, use = { type = 'dce_udp' } },

    { when = { service = 'netbios-ssn' },      use = { type = 'dce_smb' } },
    { when = { service = 'dce_http_server' },  use = { type = 'dce_http_server' } },
    { when = { service = 'dce_http_proxy' },   use = { type = 'dce_http_proxy' } },

    { when = { service = 'dnp3' },             use = { type = 'dnp3' } },
    { when = { service = 'dns' },              use = { type = 'dns' } },
    { when = { service = 'ftp' },              use = { type = 'ftp_server' } },
    { when = { service = 'ftp-data' },         use = { type = 'ftp_data' } },
    { when = { service = 'gtp' },              use = { type = 'gtp_inspect' } },
    { when = { service = 'imap' },             use = { type = 'imap' } },
    { when = { service = 'http' },             use = { type = 'http_inspect' } },
    { when = { service = 'http2' },            use = { type = 'http2_inspect' } },
    { when = { service = 'modbus' },           use = { type = 'modbus' } },
    { when = { service = 'pop3' },             use = { type = 'pop' } },
    { when = { service = 'ssh' },              use = { type = 'ssh' } },
    { when = { service = 'sip' },              use = { type = 'sip' } },
    { when = { service = 'smtp' },             use = { type = 'smtp' } },
    { when = { service = 'ssl' },              use = { type = 'ssl' } },
    { when = { service = 'sunrpc' },           use = { type = 'rpc_decode' } },
    { when = { service = 'telnet' },           use = { type = 'telnet' } },

    { use = { type = 'wizard' } }
}

---------------------------------------------------------------------------
-- 4. configure performance
---------------------------------------------------------------------------

-- use latency to monitor / enforce packet and rule thresholds
--latency = {
--    packet = {
--	      max_time = 100,
--		  fastpath = false,
--    },
--    rule = {
--	      max_time = 100,
--		  suspend = false,
--        suspend_threshold = 1,
--        max_suspend_time = 6000,
--	  }
--}

-- use these to capture perf data for analysis and tuning
profiler = { }
perf_monitor = { }

---------------------------------------------------------------------------
-- 5. configure detection
---------------------------------------------------------------------------
--inspection = { mode = 'inline' }

--alerts = { stateful = true }

--event_queue = { }

-------------
-- hyperscan
-------------
search_engine = {
	-- show_fast_patterns = true,
    search_method = "hyperscan"
} 
detection = {
    hyperscan_literals = true,
	pcre_to_regex = true
} 

-- Issue
-- NFQ inline mode error (FATAL: Active response: can't open) #142 (https://github.com/snort3/snort3/issues/142)
active = {
	attempts = 2,
    device = 'ip',
--    device = 'enp0s8',
--	dst_mac = '',
--	max_responses = 255,
--	min_interval = 64
}

daq =
{
    module_dirs =
	{
	    path = '/usr/local/lib/daq'
	},
    modules =
    {
        {
            name = 'nfq',
            mode = 'inline',
            --variables = {
            --    'debug',
            --    'fail_open',
            --    'queue_maxlen = 1024'
            --}
			variables = {
				'fail_open',
				'queue_maxlen = 4096'
			}
        },
        --{
        --    name = 'dump',
        --    variables = { 'output=none' }
        --},
    },
	inputs =
	{
	    '1'
        --'enp0s8'
	},
	snaplen = 65535,
	batch_size = 1024
}

references = default_references
classifications = default_classifications

ips =
{
    -- use this to enable decoder and inspector alerts
    --enable_builtin_rules = true,

    -- use include for rules files; be sure to set your path
    -- note that rules files can include other rules files
    --include = 'snort3-community.rules'

	-- The following include syntax is only valid for ...
	-- RULE_PATH is typically set in snort_defaults.lua
	rules = [[
	    # include $BUILTIN_RULE_PATH/builtins.rules
	
	    # include $RULE_PATH/snort3-app-detect.rules
	    # include $RULE_PATH/snort3-browser-chrome.rules
		
		# include $RULE_PATH/local.rules
    ]],
	
	-- ISSUE:
	-- https://github.com/snort3/snort3/issues/147
	-- https://github.com/snort3/snort3/commit/75ec38edbfe6865a9cdcf308f3a68078378024d2
    variables =
    {
        nets =
        {
	        HOME_NET = HOME_NET,
	        EXTERNAL_NET = EXTERNAL_NET,
	        DNS_SERVERS = DNS_SERVERS,
	        FTP_SERVERS = FTP_SERVERS,
	        HTTP_SERVERS = HTTP_SERVERS,
	        SIP_SERVERS = SIP_SERVERS,
	        SMTP_SERVERS = SMTP_SERVERS,
	        SQL_SERVERS = SQL_SERVERS,
	        SSH_SERVERS = SSH_SERVERS,
	        TELNET_SERVERS = TELNET_SERVERS,
        },
	    paths = {
	        RULE_PATH = RULE_PATH,
	        BUILTIN_RULE_PATH = BUILTIN_RULE_PATH,
	        PLUGIN_RULE_PATH = PLUGIN_RULE_PATH,
	        WHITE_LIST_PATH = WHITE_LIST_PATH,
	        BLACK_LIST_PATH = BLACK_LIST_PATH,
	    },
        ports =
        {
	        FTP_PORTS = FTP_PORTS,
	        HTTP_PORTS = HTTP_PORTS,
	        MAIL_PORTS = MAIL_PORTS,
	        ORACLE_PORTS = ORACLE_PORTS,
	        SIP_PORTS = SIP_PORTS,
	        SSH_PORTS = SSH_PORTS,
	        FILE_DATA_PORTS = FILE_DATA_PORTS,
        }
    }	
}

--rewrite = {
  -- disable_replace = true,
--}

-- use these to configure additional rule actions
-- react = { }
--react = { 
  -- page = '/tmp/block.html',
--}
--payload_injector = { }
--normalizer = { }

-- reject = { }
reject = { reset = "both", control = "all" }

---------------------------------------------------------------------------
-- 6. configure filters
---------------------------------------------------------------------------

-- below are examples of filters
-- each table is a list of records

--[[
suppress =
{
    -- don't want to any of see these
    { gid = 1, sid = 1 },

    -- don't want to see these for a given server
    { gid = 1, sid = 2, track = 'by_dst', ip = '1.2.3.4' },
}
--]]

--[[
event_filter =
{
    -- reduce the number of events logged for some rules
    { gid = 1, sid = 1, type = 'limit', track = 'by_src', count = 2, seconds = 10 },
    { gid = 1, sid = 2, type = 'both',  track = 'by_dst', count = 5, seconds = 60 },
}
--]]

--[[
rate_filter =
{
    -- alert on connection attempts from clients in SOME_NET
    { gid = 135, sid = 1, track = 'by_src', count = 5, seconds = 1,
      new_action = 'alert', timeout = 4, apply_to = '[$SOME_NET]' },

    -- alert on connections to servers over threshold
    { gid = 135, sid = 2, track = 'by_dst', count = 29, seconds = 3,
      new_action = 'alert', timeout = 1 },
}
--]]

---------------------------------------------------------------------------
-- 7. configure outputs
---------------------------------------------------------------------------

output = {
	dump_payload = false,
	logdir = '/var/log/snort',
	verbose = true,
}

-- event logging
-- you can enable with defaults from the command line with -A <alert_type>
-- uncomment below to set non-default configs
alert_csv = { }
--alert_fast = { }
--alert_full = { }
--alert_json = { }
alert_json = {
	-- Output into file or STDOUT
	file = true, 
--	limit = 10, 
--	fields = 'seconds action class b64_data dir dst_addr \
--	    dst_ap dst_port eth_dst eth_len eth_src eth_type gid icmp_code \
--		icmp_id icmp_seq icmp_type iface ip_id ip_len msg mpls pkt_gen \
--		pkt_len pkt_num priority proto rev rule service sid src_addr \
--	    src_ap src_port target tcp_ack tcp_flags tcp_len tcp_seq \
--		tcp_win tos ttl udp_len vlan timestamp',
    --fields = 'timestamp pkt_num pkt_len pkt_gen src_ap dst_ap proto action rule msg'
}
--alert_sfsocket = 
--{
	-- file = '/run/systemd/journal/syslog',
	-- When run as Docker container, mount Systemd syslog socket first
	--file = '/tmp/syslog'
--}
--alert_syslog = { }
--alert_syslog = {
	-- facility = 'auth | authpriv | daemon | user | local0 | local1 | local2 | local3 | local4 | local5 | local6 | local7',
	-- level = 'emerg | alert | crit | err | warning | notice | info | debug',
	--facility = 'user',
	--level = 'info',
--}
--alert_unixsocket = { }
--unified2 = { }

-- packet logging
-- you can enable with defaults from the command line with -L <log_type>
log_codecs = { }
log_hext = { }
--log_pcap = { }

-- additional logs
--packet_capture = { }
--file_log = { }

---------------------------------------------------------------------------
-- 8. configure tweaks
---------------------------------------------------------------------------

if ( tweaks ~= nil ) then
    include(tweaks .. '.lua')
end

