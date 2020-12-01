package option

type Options struct {
	InsecureHTTP bool
	ServingIP    string
	ServingPort  int
	LogLevel     string
	DryRun       bool
}

func DefaultOptions() Options {
	return Options{
		InsecureHTTP: true,
		ServingIP:    "",
		ServingPort:  8099,

		DryRun:   false,
		LogLevel: "2",
	}
}

type FirewallOptions struct {
	Options
	ServerAddress     string
	RootFs            string
	ControllerManager string
}

func DefaultFirewallOptions(opt Options) FirewallOptions {
	return FirewallOptions{
		Options:           opt,
		ServerAddress:     ":8099",
		ControllerManager: "127.0.0.1:8088",
	}
}

type NetlinkOptions struct {
	Options
	DevPromisc string
	AddrFrom   string
	Verbose    bool
}

func DefaultNetlinkOptions(opt Options) NetlinkOptions {
	return NetlinkOptions{
		Options:  opt,
		AddrFrom: "dhcp",
	}
}
