package contracts_test

import (
	"testing"

	"github.com/stretchr/testify/assert"

	"github.com/onflow/flow-go-sdk/test"

	"github.com/onflow/random-coin-toss/lib/go/contracts"
)

const addrA = "0x0A"

func TestNonFungibleTokenContract(t *testing.T) {
	contract := contracts.NonFungibleToken()
	assert.NotNil(t, contract)
}

func TestFungibleTokenContract(t *testing.T) {
	contract := contracts.FungibleToken()
	assert.NotNil(t, contract)
}

func TestViewResolver(t *testing.T) {
	addresses := test.AddressGenerator()
	contract := contracts.ViewResolver()
	assert.NotNil(t, contract)
}

func TestMetadataViewsContract(t *testing.T) {
	addresses := test.AddressGenerator()
	addressA := addresses.New()
	addressB := addresses.New()
	addressC := addresses.New()
	contract := contracts.MetadataViews(addressA, addressB, addressC)
	assert.NotNil(t, contract)
}

func TestRandomBeaconHistory(t *testing.T) {
	addresses := test.AddressGenerator()
	contract := contracts.RandomBeaconHistory()
	assert.NotNil(t, contract)
}

func TestRandomBeaconHistory(t *testing.T) {
	addresses := test.AddressGenerator()
	contract := contracts.PseudoRandomGenerator()
	assert.NotNil(t, contract)
}
