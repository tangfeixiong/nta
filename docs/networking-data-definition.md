

  //  {
  //    "vnets": [
  //      {
  //        "name": "int-stage-0",
  //        "subnets": [
  //          {
  //            "name": "int-192-168-128-0-slash-24",
  //            "cidr": "192.168.128.0/24",
  //            "enabledhcp": true
  //          }
  //        ]
  //      },
  //      {
  //        "name": "int-stage-1",
  //        "subnets": [
  //          {
  //            "name": "int-192-168-129-0-slash-24",
  //            "cidr": "192.168.129.0/24",
  //            "enabledhcp": true
  //          }
  //        ]
  //      },
  //      {
  //        "name": "int-stage-2",
  //        "subnets": [
  //          {
  //            "name": "int-192-168-130-0-slash-24",
  //            "cidr": "192.168.130.0/24",
  //            "enabledhcp": true
  //          }
  //        ]
  //      },
  //      {
  //        "name": "int-stage-3",
  //        "subnets": [
  //          {
  //            "name": "int-192-168-131-0-slash-24",
  //            "cidr": "192.168.131.0/24",
  //            "enabledhcp": true
  //          }
  //        ]
  //      },
  //      {
  //        "name": "public",
  //        "admin_state_up": true,
  //        "subnets": [
  //          {
  //            "name": "10.100.151.0/24",
  //            "cidr": "10.100.151.0/24",
  //            "gateway_ip": "10.100.151.1",
  //            "allocation_pools": {
  //              "start": "10.100.151.50",
  //              "end": "10.100.151.240"
  //            },
  //            "enabledhcp": false
  //          }
  //        ],
  //        "shared": true
  //      }
  //    ],
  //    "vrouter": {
  //      "name": "hack",
  //      "admint_state_up": true
  //    },
  //    "secgroup": {
  //      "name": "hack",
  //      "rules": [
  //        {
  //          "direction": "ingress",
  //          "protocol": "tcp"
  //        },
  //        {
  //          "direction": "ingress",
  //          "protocol": "udp"
  //        },
  //        {
  //          "direction": "ingress",
  //          "protocol": "icmp"
  //        }
  //      ]
  //    },
  //    "ifaces_info": [
  //      {
  //        "router_name": "hack",
  //        "network_name": "int-stage-0",
  //        "subnet_name": "int-192-168-128-0-slash-24",
  //        "secgroups_info": [
  //          {
  //            "name": "hack"
  //          }
  //        ]
  //      },
  //      {
  //        "router_name": "hack",
  //        "network_name": "int-stage-1",
  //        "subnet_name": "int-192-168-129-0-slash-24",
  //        "secgroups_info": [
  //          {
  //            "name": "hack"
  //          }
  //        ]
  //      },
  //      {
  //        "router_name": "hack",
  //        "network_name": "int-stage-2",
  //        "subnet_name": "int-192-168-130-0-slash-24",
  //        "secgroups_info": [
  //          {
  //            "name": "hack"
  //          }
  //        ]
  //      },
  //      {
  //        "router_name": "hack",
  //        "network_name": "int-stage-3",
  //        "subnet_name": "int-192-168-131-0-slash-24",
  //        "secgroups_info": [
  //          {
  //            "name": "hack"
  //          }
  //        ]
  //      }
  //    ],
  //    "gateways_info": [
  //      {
  //        "network_name": "public",
  //        "router_name": "hack"
  //      }
  //    ]
  //  }
