package cmd

import (
	"github.com/spf13/cobra"

	"github.com/tangfeixiong/nta/cmd/option"
	"github.com/tangfeixiong/nta/pkg/network"
)

func newNetlinkCommand(copt option.Options) *cobra.Command {
	opt := option.DefaultNetlinkOptions(copt)
	command := &cobra.Command{
		Use:   "promisc-links",
		Short: "Bridging pormiscuous net device (eth0) with tap and re-assign IP address",
		RunE: func(cmd *cobra.Command, args []string) error {
			config, err := networkConfigFrom(opt)
			if err != nil {
				return err
			}
			return network.Main(config)
		},
	}

	command.Flags().StringVar(&opt.DevPromisc, "promisc-device", opt.DevPromisc, "Device interface its mode will be promisc")
	command.Flags().StringVar(&opt.AddrFrom, "addr-from", opt.AddrFrom, "Bridging device with tap and re-assign address")
	command.Flags().BoolVar(&opt.Verbose, "verbose", opt.Verbose, "Pretty output")

	return command
}

func networkConfigFrom(opt option.NetlinkOptions) (*network.Config, error) {
	conf, err := network.NewConfig(opt.DevPromisc, opt.AddrFrom, opt.Verbose)

	return conf, err
}
