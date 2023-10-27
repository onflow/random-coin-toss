package contracts_test

import (
	"testing"

	"github.com/onflow/flow-go-sdk/test"
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

func TestCoinToss(t *testing.T) {
	addresses := test.AddressGenerator()
	addressA := addresses.New()
	addressB := addresses.New()
	addressC := addresses.New()
	addressD := addresses.New()

	contract := contracts.CoinToss(addressA, addressB, addressC, addressD)
	assert.NotNil(t, contract)

	assert.Contains(t, string(contract), addressA.String())
	assert.Contains(t, string(contract), addressB.String())
	assert.Contains(t, string(contract), addressC.String())
	assert.Contains(t, string(contract), addressD.String())
}
