package network

import (
	"strconv"
	"strings"

	"github.com/vishvananda/netlink"

	"gopkg.in/logex.v1"
)

func Main(config *Config) error {

	netop := &NetworkOperation{
		config:        config,
		bridgeNum:     0,
		bridgeVethNum: 0,
		vSwitchNum:    0,
		vEtherNum:     0,
	}

	linkList, err := netlink.LinkList()
	if err != nil {
		logex.Errorf("Unexpected to reap links error: %v", err)
		return err
	}

	netop.bridgeVethIface = &netlink.Veth{
		LinkAttrs: netlink.LinkAttrs{},
	}
	netop.bridgeVethIface.Name, netop.bridgeVethNum = getUnusedLinkName(linkList, "veth")

	netop.bridgeIface = &netlink.Bridge{
		LinkAttrs: netlink.LinkAttrs{},
	}
	netop.bridgeIface.Name, netop.bridgeNum = getUnusedLinkName(linkList, "veribr")

	netop.vSwitchIface = &netlink.Bridge{
		LinkAttrs: netlink.LinkAttrs{},
	}
	netop.vSwitchIface.Name, netop.vSwitchNum = getUnusedLinkName(linkList, "br")

	netop.vEtherIface = &netlink.Veth{
		LinkAttrs: netlink.LinkAttrs{},
	}
	netop.vEtherIface.Name, netop.vEtherNum = getUnusedLinkName(linkList, "veth")

	return netop.run()
}

type NetworkOperation struct {
	config          *Config
	bridgeNum       int
	bridgeIface     *netlink.Bridge
	bridgeVethNum   int
	bridgeVethIface *netlink.Veth
	vSwitchNum      int
	vSwitchIface    *netlink.Bridge
	vEtherNum       int
	vEtherIface     *netlink.Veth
	vSwitchAddrList []netlink.Addr
}

func getUnusedLinkName(linkList []netlink.Link, leading string) (linkName string, suffixNum int) {
	if len(leading) == 0 {
		leading = "linkiface"
	}
LOOP:
	for i := 0; len(linkName) == 0; i++ {
		name := leading + strconv.Itoa(i)
		for _, elem := range linkList {
			attrs := elem.Attrs()
			if attrs.Name == name || strings.ToLower(attrs.Name) == name {
				continue LOOP
			}
		}
		linkName = name
		suffixNum = i
	}
	return
}

func (netop *NetworkOperation) run() error {
	if err := netlink.LinkAdd(netop.bridgeVethIface); err != nil {
		logex.Errorf("Create veth error: %v", err)
		return err
	}
	if err := netlink.LinkAdd(netop.bridgeIface); err != nil {
		logex.Errorf("Create bridge error: %v", err)
		return err
	}

	return nil
}
