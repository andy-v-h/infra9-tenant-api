// Copyright 2023 The Infratographer Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// Code generated by entc, DO NOT EDIT.

package generated

import (
	"go.infratographer.com/x/gidx"
)

// CreateTenantInput represents a mutation input for creating tenants.
type CreateTenantInput struct {
	Name        string
	Description *string
	ParentID    *gidx.PrefixedID
}

// Mutate applies the CreateTenantInput on the TenantMutation builder.
func (i *CreateTenantInput) Mutate(m *TenantMutation) {
	m.SetName(i.Name)
	if v := i.Description; v != nil {
		m.SetDescription(*v)
	}
	if v := i.ParentID; v != nil {
		m.SetParentID(*v)
	}
}

// SetInput applies the change-set in the CreateTenantInput on the TenantCreate builder.
func (c *TenantCreate) SetInput(i CreateTenantInput) *TenantCreate {
	i.Mutate(c.Mutation())
	return c
}

// UpdateTenantInput represents a mutation input for updating tenants.
type UpdateTenantInput struct {
	Name             *string
	ClearDescription bool
	Description      *string
}

// Mutate applies the UpdateTenantInput on the TenantMutation builder.
func (i *UpdateTenantInput) Mutate(m *TenantMutation) {
	if v := i.Name; v != nil {
		m.SetName(*v)
	}
	if i.ClearDescription {
		m.ClearDescription()
	}
	if v := i.Description; v != nil {
		m.SetDescription(*v)
	}
}

// SetInput applies the change-set in the UpdateTenantInput on the TenantUpdate builder.
func (c *TenantUpdate) SetInput(i UpdateTenantInput) *TenantUpdate {
	i.Mutate(c.Mutation())
	return c
}

// SetInput applies the change-set in the UpdateTenantInput on the TenantUpdateOne builder.
func (c *TenantUpdateOne) SetInput(i UpdateTenantInput) *TenantUpdateOne {
	i.Mutate(c.Mutation())
	return c
}
