// Package db2 contains IBM DB2 driver registration for xk6-sql.
package db2

import (
	"github.com/grafana/xk6-sql/sql"

	// Blank import required for initialization of driver.
	_ "github.com/ibmdb/go_ibm_db"
	"go.k6.io/k6/js/modules"
)

func init() {
	sql.RegisterModule("go_ibm_db")
	modules.Register("k6/x/sql/driver/go_ibm_db", new(RootModule))
}

// RootModule is the global module instance that will create instances of the module.
type RootModule struct{}

// NewModuleInstance implements the modules.Module interface to return a new instance for each VU.
func (*RootModule) NewModuleInstance(_ modules.VU) modules.Instance {
	return &ModuleInstance{}
}

// ModuleInstance represents an instance of the module for each VU.
type ModuleInstance struct{}

// Exports returns the exports of the module.
func (mi *ModuleInstance) Exports() modules.Exports {
	return modules.Exports{
		Named: map[string]interface{}{
			"driver": "go_ibm_db",
		},
		Default: "go_ibm_db",
	}
}
