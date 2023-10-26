package contracts_test

import (
	"testing"

	"github.com/stretchr/testify/assert"

	"github.com/onflow/random-coin-toss/lib/go/contracts"
)

func TestRandomBeaconHistory(t *testing.T) {
	contract := contracts.RandomBeaconHistory()
	assert.NotNil(t, contract)
}

func TestPseudoRandomGenerator(t *testing.T) {
	contract := contracts.PseudoRandomGenerator()
	assert.NotNil(t, contract)
}
