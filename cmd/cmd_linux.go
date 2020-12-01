// +build linux

package cmd

import (
	"flag"
	"fmt"
	"io"
	"os"

	"github.com/spf13/cobra"
	"github.com/spf13/pflag"

	klog "k8s.io/klog/v2"
	kubeadmutil "k8s.io/kubernetes/cmd/kubeadm/app/util"

	"github.com/tangfeixiong/nta/cmd/option"
)

var (
	/*tmplLong = templates.LongDesc*/ tmplLong string = (`
		%[2]s

		The %[3]s helps you manage cyber security with Micro-Segmentaion and Net-Traffic-Analysis on top of
		Linux machines. To start with the default components, run:

		    $ %[1]s serve &`)
)

// Reference:
// - https://github.com/kubernetes/klog/tree/master/examples/coexist_glog
func New(name string) *cobra.Command {
	//	klogFlags := flag.NewFlagSet("klog", flag.ExitOnError)
	//	klog.InitFlags(klogFlags)
	//	defer klog.Flush()
	//	// Sync the glog and klog flags.
	//	flag.CommandLine.VisitAll(func(f1 *flag.Flag) {
	//		f2 := klogFlags.Lookup(f1.Name)
	//		if f2 != nil {
	//			value := f1.Value.String()
	//			f2.Value.Set(value)
	//		}
	//	})
	klog.InitFlags(nil)
	//	pflag.CommandLine.SetNormalizeFunc(cliflag.WordSepNormalizeFunc)
	pflag.CommandLine.AddGoFlagSet(flag.CommandLine)

	pflag.Set("logtostderr", "true")
	// We do not want these flags to show up in --help
	// These MarkHidden calls must be after the lines above
	pflag.CommandLine.MarkHidden("version")
	pflag.CommandLine.MarkHidden("log-flush-frequency")
	pflag.CommandLine.MarkHidden("alsologtostderr")
	pflag.CommandLine.MarkHidden("log-backtrace-at")
	pflag.CommandLine.MarkHidden("log-dir")
	pflag.CommandLine.MarkHidden("logtostderr")
	pflag.CommandLine.MarkHidden("stderrthreshold")
	pflag.CommandLine.MarkHidden("vmodule")

	return thisCommand(name, os.Stdin, os.Stdout, os.Stderr)
}

func thisCommand(name string, in io.Reader, out, err io.Writer) *cobra.Command {
	var rootfsPath string
	rootCommand := &cobra.Command{
		Use:           name,
		Short:         "Start up Linux firewall and IDS/IPS+waf",
		Long:          fmt.Sprintf(tmplLong, name, name, name),
		SilenceErrors: true,
		SilenceUsage:  true,
		PersistentPreRunE: func(cmd *cobra.Command, args []string) error {
			//			flag.Set("alsologtostderr", "true")
			//			flag.Set("v", opt.LogLevel)
			//			flag.Parse()
			if rootfsPath != "" {
				if err := kubeadmutil.Chroot(rootfsPath); err != nil {
					return err
				}
			}
			return nil
		},
	}
	rootCommand.ResetFlags()

	opt := option.DefaultOptions()
	rootCommand.Flags().BoolVar(&opt.DryRun, "dry-run", opt.DryRun, "dry run")
	rootCommand.Flags().StringVar(&opt.LogLevel, "loglevel", opt.LogLevel, "for glog")

	rootCommand.AddCommand(newServingCommand(opt))
	rootCommand.AddCommand(newNetlinkCommand(opt))

	return rootCommand
}

func newServingCommand(opt option.Options) *cobra.Command {

	command := &cobra.Command{
		Use:   "serve",
		Short: "Serving security manager",
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Println("Noop!")
		},
		Args: cobra.NoArgs,
	}

	command.AddCommand(newServingFirewallCommand(opt))

	return command
}
