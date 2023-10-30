package test

import (
	"math"
	mrand "math/rand"
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/onflow/flow-go/crypto/random"
	"github.com/stretchr/testify/assert"
)

func TestNextUInt64NewPRGOverflow(t *testing.T) {
	o, err := OverflowTesting()
	assert.NoError(t, err)

	t.Run("Should generate uniform distribution", func(t *testing.T) {
		// make sure n is a power of 2 so that there is no bias in the last class
		// n is a random power of 2 (from 2 to 2^10)
		n := 1 << (1 + mrand.Intn(10))
		classWidth := (math.MaxUint64 / uint64(n)) + 1

		// using the same seed, the salt varies in getNextUInt64()
		seed := GetRandomSeed(t)

		uintf := func() (uint64, error) {
			return GetNextUInt64NewPRG(o, t, seed)
		}

		random.BasicDistributionTest(t, uint64(n), uint64(classWidth), uintf)
	})
}
