package network

import (
	"fmt"

	"github.com/vishvananda/netlink"

	"gopkg.in/logex.v1"
)

type Config struct {
	Device      *netlink.Device
	DevAddrList []netlink.Addr
	AddressFrom string
	Verbose     bool
}

func NewConfig(devPromisc string, addrFrom string, verbose bool) (*Config, error) {
	lnk, err := netlink.LinkByName(devPromisc)
	if err != nil {
		logex.Errorf("Not exists net interface error: %s", devPromisc)
		return nil, err
	}
	if linkType := lnk.Type(); linkType != "device" {
		logex.Errorf("Require interface with %q type, but got %q", "device", linkType)
		return nil, fmt.Errorf("Require interface with %q type, but got %q", "device", linkType)
	}
	dev, ok := lnk.(*netlink.Device)
	if !ok {
		logex.Errorf("Unexpected with %s", lnk.Attrs().Name)
		return nil, fmt.Errorf("Unexpected with %s", lnk.Attrs().Name)
	}
	addrs, err := netlink.AddrList(lnk, netlink.FAMILY_ALL)
	if err != nil {
		logex.Errorf("Reap addresses error: v%", err)
		return nil, err
	}

	return &Config{
		Device:      dev,
		DevAddrList: addrs,
		AddressFrom: addrFrom,
		Verbose:     verbose,
	}, nil
}
