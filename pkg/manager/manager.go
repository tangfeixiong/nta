package manager

import (
	"github.com/emicklei/go-restful"

	"gopkg.in/logex.v1"
)

type Manager struct {
	u               UserResource
	inHostNamespace bool
	//	*pbxxx.UnimplementedXXXServiceServer
	dataplanes map[string][]string
}

func NewOrErr() (*Manager, error) {
	userResource := UserResource{
		users: map[string]User{},
	}

	mgr := &Manager{
		u:          userResource,
		dataplanes: make(map[string][]string),
	}

	return mgr, nil
}

func (mgr *Manager) WebServices() []*restful.WebService {
	return []*restful.WebService{mgr.u.WebService(), mgr.WebService()}
}

func (mgr *Manager) UpdateRules(rules []string) error {
	ipt, err := NewIPTablesExecution()
	if err != nil {
		logex.Errorf("Unable to invoke iptables executor error: %v", err)
		return err
	}
	ipt.Run(rules)
	return nil
}
