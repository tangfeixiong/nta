#!/bin/bash
set -e

/usr/sbin/iptables -F 
/usr/sbin/iptables -t nat -I PREROUTING -j NFQUEUE --queue-num 0
/usr/sbin/iptables -I FORWARD -j NFQUEUE --queue-num 0
/usr/sbin/iptables -I INPUT -j NFQUEUE --queue-num 0