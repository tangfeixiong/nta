package gopackets

import (
	"fmt"
	"log"
	"testing"

	"github.com/google/gopacket"
	"github.com/google/gopacket/pcap"
)

/*
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta$ \
go test -v -run Pcap_FindAllDevs ./pkg/utils/network/gopackets/
*/
func TestPcap_FindAllDevs(t *testing.T) {
	// Find all devices
	devices, err := pcap.FindAllDevs()
	if err != nil {
		log.Fatal(err)
	}

	// Print device information
	log.Println("Devices found:")
	for _, device := range devices {
		fmt.Println("\nName: ", device.Name)
		fmt.Println("Description: ", device.Description)
		fmt.Println("Devices addresses: ", device.Description)
		for _, address := range device.Addresses {
			fmt.Println("- IP address: ", address.IP)
			fmt.Println("- Subnet mask: ", address.Netmask)
		}
	}

}

/*
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta$ \
sudo /Users/fanhongling/Downloads/99-mirror/linux-bin/golang.org0x2Fdl/go1.13.6/bin/go \
test -v -run Pcap_OpenLive ./pkg/utils/network/gopackets/
PACKET: 1024 bytes, truncated, wire length 1084 cap length 1024 @ 2020-03-18 09:39:01.217704 +0000 UTC
- Layer 1 (16 bytes) = Linux SLL	{Contents=[..16..] Payload=[..1008..] PacketType=outgoing AddrLen=6 Addr=08:00:27:e5:e2:33 EthernetType=IPv4 AddrType=1}
- Layer 2 (20 bytes) = IPv4	{Contents=[..20..] Payload=[..988..] Version=4 IHL=5 TOS=16 Length=1068 Id=4566 Flags=DF FragOffset=0 TTL=64 Protocol=TCP Checksum=52391 SrcIP=172.28.128.4 DstIP=172.28.128.1 Options=[] Padding=[]}
- Layer 3 (32 bytes) = TCP	{Contents=[..32..] Payload=[..956..] SrcPort=22(ssh) DstPort=51236 Seq=1403324377 Ack=1904042463 DataOffset=8 FIN=false SYN=false RST=false PSH=true ACK=true URG=false ECE=false CWR=false NS=false Window=501 Checksum=23645 Urgent=0 Options=[TCPOption(NOP:), TCPOption(NOP:), TCPOption(Timestamps:1928884888/1321207024 0x72f872984ec004f0)] Padding=[]}
- Layer 4 (956 bytes) = Payload	956 byte(s)

link layer flow: MAC 08:00:27:e5:e2:33-> network layer flow: IPv4 172.28.128.4->172.28.128.1 transport layer flow: TCP 22->51236 cap meta: 2020-03-18 09:39:01.217704 +0000 UTC, 1024
*/
func TestPcap_OpenLive(t *testing.T) {
	device = devices[0]
	// Open device
	handle, err = pcap.OpenLive(device, snapshot_len, promiscuous, timeout)
	if err != nil {
		log.Fatal(err)
	}
	defer handle.Close()

	lnks, err := handle.ListDataLinks()
	if err != nil {
		t.Fatal(err)
	} else {
		fmt.Printf("list data links of %s: %d\n", device, len(lnks))
		for n, v := range lnks {
			fmt.Printf("index=%v link=%+v\n", n, v)
		}
	}

	// Use the handle as a packet source to process all packets
	packetSource := gopacket.NewPacketSource(handle, handle.LinkType())
	for packet := range packetSource.Packets() {
		// Process packet here
		fmt.Println(packet)

		linkLayer := packet.LinkLayer()
		linkFlow := linkLayer.LinkFlow()
		fmt.Printf("link layer flow: %s %s ", linkFlow.EndpointType(), linkFlow.String())

		networkLayer := packet.NetworkLayer()
		networkFlow := networkLayer.NetworkFlow()
		fmt.Printf("network layer flow: %s %s ", networkFlow.EndpointType(), networkFlow.String())

		transportLayer := packet.TransportLayer()
		transportFlow := transportLayer.TransportFlow()
		fmt.Printf("transport layer flow: %s %s ", transportFlow.EndpointType(), transportFlow.String())

		capinfo := packet.Metadata()
		fmt.Printf("cap meta: %v, %d \n", capinfo.Timestamp, capinfo.CaptureLength)
	}
}
