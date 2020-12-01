package manager

import (
	"bytes"
	"fmt"
	"io"
	"os"
	"os/exec"
	"sync"
	"syscall"
	"time"

	"github.com/coreos/go-iptables/iptables"

	"gopkg.in/logex.v1"
)

type IPTablesExecution struct {
	*iptables.IPTables
}

func NewIPTablesExecution() (*IPTablesExecution, error) {
	ipt, err := iptables.New()
	if err != nil {
		return nil, err
	}
	return &IPTablesExecution{
		IPTables: ipt,
	}, nil
}

func (iptex *IPTablesExecution) Run(commandRules []string) {
	for _, item := range commandRules {
		time.Sleep(1 * time.Second)
		if err := iptex.run(item); err != nil {
			logex.Errorf("error: %s", err.Error())
		}
	}
}

// run runs an iptables command with the given arguments, ignoring
// any stdout output
func (ipt *IPTablesExecution) run(args ...string) error {
	return ipt.runWithOutput(args, nil)
}

// runWithOutput runs an iptables command with the given arguments,
// writing any stdout output to the given writer
func (ipt *IPTablesExecution) runWithOutput(args []string, stdout io.Writer) error {
	sh := "/bin/sh"
	args = append([]string{sh, "-c"}, args...)
	//	args = append([]string{ipt.path}, args...)
	//	if ipt.hasWait {
	//		args = append(args, "--wait")
	//	} else {
	//		fmu, err := newXtablesFileLock()
	//		if err != nil {
	//			return err
	//		}
	//		ul, err := fmu.tryLock()
	//		if err != nil {
	//			syscall.Close(fmu.fd)
	//			return err
	//		}
	//		defer ul.Unlock()
	//	}

	var stderr bytes.Buffer
	cmd := exec.Cmd{
		Path:/* ipt.path */ sh,
		Args:   args,
		Stdout: stdout,
		Stderr: &stderr,
	}

	if err := cmd.Run(); err != nil {
		switch e := err.(type) {
		case *exec.ExitError:
			//			return &Error{*e, cmd, stderr.String(), nil}
			status := (*e).Sys().(syscall.WaitStatus).ExitStatus()
			return fmt.Errorf("running %v: exit status %v: %v", cmd.Args, status, stderr.String())
		default:
			return err
		}
	}

	return nil
}

const (
	// In earlier versions of iptables, the xtables lock was implemented
	// via a Unix socket, but now flock is used via this lockfile:
	// http://git.netfilter.org/iptables/commit/?id=aa562a660d1555b13cffbac1e744033e91f82707
	// Note the LSB-conforming "/run" directory does not exist on old
	// distributions, so assume "/var" is symlinked
	xtablesLockFilePath = "/var/run/xtables.lock"

	defaultFilePerm = 0600
)

type Unlocker interface {
	Unlock() error
}

type nopUnlocker struct{}

func (_ nopUnlocker) Unlock() error { return nil }

type fileLock struct {
	// mu is used to protect against concurrent invocations from within this process
	mu sync.Mutex
	fd int
}

// tryLock takes an exclusive lock on the xtables lock file without blocking.
// This is best-effort only: if the exclusive lock would block (i.e. because
// another process already holds it), no error is returned. Otherwise, any
// error encountered during the locking operation is returned.
// The returned Unlocker should be used to release the lock when the caller is
// done invoking iptables commands.
func (l *fileLock) tryLock() (Unlocker, error) {
	l.mu.Lock()
	err := syscall.Flock(l.fd, syscall.LOCK_EX|syscall.LOCK_NB)
	switch err {
	case syscall.EWOULDBLOCK:
		l.mu.Unlock()
		return nopUnlocker{}, nil
	case nil:
		return l, nil
	default:
		l.mu.Unlock()
		return nil, err
	}
}

// Unlock closes the underlying file, which implicitly unlocks it as well. It
// also unlocks the associated mutex.
func (l *fileLock) Unlock() error {
	defer l.mu.Unlock()
	return syscall.Close(l.fd)
}

// newXtablesFileLock opens a new lock on the xtables lockfile without
// acquiring the lock
func newXtablesFileLock() (*fileLock, error) {
	fd, err := syscall.Open(xtablesLockFilePath, os.O_CREATE, defaultFilePerm)
	if err != nil {
		return nil, err
	}
	return &fileLock{fd: fd}, nil
}
