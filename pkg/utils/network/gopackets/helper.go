package gopackets

import (
	"io"
	"time"

	"k8s.io/klog"

	"github.com/google/gopacket"
	"github.com/google/gopacket/layers"
	"github.com/google/gopacket/pcap"
	"github.com/google/gopacket/pcapgo"
)

var (
	device       string = "lo"
	snapshot_len int32  = 1024
	promiscuous  bool   = false
	err          error
	timeout      time.Duration = 30 * time.Second
	handle       *pcap.Handle
)

var devices []string = []string{"any", device, "eth1", "enp0s8", "docker0", "cni0", "flannel.1", "tunl0", "virbr0", "cbr0"}

func OpenLiveToPcap(dev string, snaplen int32, promisc bool, timeOut time.Duration) ([]gopacket.Packet, error) {
	if len(dev) > 0 {
		devList, err := pcap.FindAllDevs()
		if err != nil {
			return nil, err
		}
		for _, el := range devList {
			if el.Name == dev {
				device = dev
				break
			}
		}
	}
	if device != "lo" {
		device = devices[0]
	}
	if snaplen >= 1024 {
		snapshot_len = snaplen
	} else {
		snapshot_len = 1600
	}
	promiscuous = promisc
	if timeOut >= 3*time.Second {
		timeout = timeOut
	} else if timeOut <= 0 {
		timeout = pcap.BlockForever
	}
	// Open device
	handle, err = pcap.OpenLive(device, snapshot_len, promiscuous, timeout)
	if err != nil {
		return nil, err
	}
	defer handle.Close()

	// Use the handle as a packet source to process all packets
	packetSource := gopacket.NewPacketSource(handle, handle.LinkType())
	packets := make([]gopacket.Packet, len(packetSource.Packets()))
	for packet := range packetSource.Packets() {
		// Process packet here
		packets = append(packets, packet)
	}
	return packets, nil
}

func OpenLiveToPcapPipe(dev string, snaplen int32, promisc bool, timeOut time.Duration) (*io.PipeReader, error) {
	if len(dev) > 0 {
		devList, err := pcap.FindAllDevs()
		if err != nil {
			return nil, err
		}
		for _, el := range devList {
			if el.Name == dev {
				device = dev
				break
			}
		}
	}
	if device != "lo" {
		device = devices[0]
	}
	if snaplen >= 1024 {
		snapshot_len = snaplen
	} else {
		snapshot_len = 1600
	}
	promiscuous = promisc
	if timeOut >= 3*time.Second {
		timeout = timeOut
	} else if timeOut <= 0 {
		timeout = pcap.BlockForever
	}

	// Open output pcap file and write header
	pr, pw := io.Pipe()
	//	f, _ := os.Create("test.pcap")
	//	w := pcapgo.NewWriter(f)
	w := pcapgo.NewWriter(pw)
	snapshotLen := uint32(snapshot_len)
	w.WriteFileHeader(snapshotLen, layers.LinkTypeEthernet)
	//	defer f.Close()

	// Open device
	handle, err = pcap.OpenLive(device, snapshot_len, promiscuous, timeout)
	if err != nil {
		return nil, err
	}
	defer handle.Close()

	// Use the handle as a packet source to process all packets
	packetSource := gopacket.NewPacketSource(handle, handle.LinkType())
	for packet := range packetSource.Packets() {
		// Process packet here
		klog.V(5).Infoln(packet)
		w.WritePacket(packet.Metadata().CaptureInfo, packet.Data())
	}
	return pr, nil
}
