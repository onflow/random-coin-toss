package templates_test

import (
	"testing"

	"github.com/onflow/flow-go-sdk/test"
	"github.com/stretchr/testify/assert"

	"github.com/onflow/random-coin-toss/lib/go/templates"
)

func TestGenerateSetupPRGScript(t *testing.T) {
	addresses := test.AddressGenerator()
	addressA := addresses.New()

	template := templates.GenerateSetupPRGScript(addressA)
	assert.NotNil(t, template)
}
