#!/bin/bash
set -e

iptables -F INPUT
iptables -A INPUT -j NFQUEUE --queue-num 0