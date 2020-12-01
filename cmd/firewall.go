package cmd

import (
	"github.com/spf13/cobra"

	"github.com/tangfeixiong/nta/cmd/option"
	"github.com/tangfeixiong/nta/pkg/firewall"
	"github.com/tangfeixiong/nta/pkg/server"
)

func newServingFirewallCommand(opt option.Options) *cobra.Command {
	fwopt := option.DefaultFirewallOptions(opt)
	command := &cobra.Command{
		Use:   "firewall",
		Short: "Serving firewall with security group on top of Linux Server",
		//		RunE: func(cmd *cobra.Command, args []string) error {
		//			cfg := firewallConfigFrom(fwopt)
		//			return server.MainFirewall(cfg)
		//		},
		Run: func(cmd *cobra.Command, args []string) {
			cfg := firewallConfigFrom(fwopt)
			server.MainFirewall(cfg)
		},
	}

	command.Flags().StringVar(&fwopt.ServerAddress, "server-address", fwopt.ServerAddress, "HTTP server address")

	return command
}

func firewallConfigFrom(opt option.FirewallOptions) *firewall.Config {
	conf := firewall.NewConfig(opt.ServerAddress)
	conf.SecureHTTP = !opt.InsecureHTTP

	return conf
}
