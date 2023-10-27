package test

import (
	"math"
	mrand "math/rand"
	"testing"

	"github.com/onflow/flow-go/crypto/random"
)

func TestNextUInt64NewPRG(t *testing.T) {
	b, adapter, accountKeys := newTestSetup(t)

	prgAccountKey, _ := accountKeys.NewWithSigner()
	prgAddress := deployPRGContract(t, b, adapter, prgAccountKey)

	t.Run("Should generate uniform distribution", func(t *testing.T) {
		// make sure n is a power of 2 so that there is no bias in the last class
		// n is a random power of 2 (from 2 to 2^10)
		n := 1 << (1 + mrand.Intn(10))
		classWidth := (math.MaxUint64 / uint64(n)) + 1

		uintf := func() (uint64, error) {
			return getNextUInt64(t, b, adapter, prgAddress)
		}

		random.BasicDistributionTest(t, uint64(n), uint64(classWidth), uintf)
	})
}
