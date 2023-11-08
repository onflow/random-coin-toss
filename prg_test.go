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
		seed := GetRandomBytes(t, 32)

		uintf := func() (uint64, error) {
			return GetNextUInt64NewPRGRandSalt(o, t, seed)
		}

		random.BasicDistributionTest(t, uint64(n), uint64(classWidth), uintf)
	})

	t.Run("Should generate different results given different seeds & same salt", func(t *testing.T) {

		seed1 := GetRandomBytes(t, 32)
		seed2 := GetRandomBytes(t, 32)
		salt := GetRandomBytes(t, 8)

		assert.NotEqual(t, seed1, seed2)

		rand1, _ := GetNextUInt64NewPRGWithSalt(o, t, seed1, salt)
		rand2, _ := GetNextUInt64NewPRGWithSalt(o, t, seed2, salt)

		// assert that the results are different
		assert.NotEqual(t, rand1, rand2)
	})

	t.Run("Should generate different results given same seed & different salt", func(t *testing.T) {

		seed := GetRandomBytes(t, 32)
		salt1 := GetRandomBytes(t, 8)
		salt2 := GetRandomBytes(t, 8)

		assert.NotEqual(t, salt1, salt2)

		rand1, _ := GetNextUInt64NewPRGWithSalt(o, t, seed, salt1)
		rand2, _ := GetNextUInt64NewPRGWithSalt(o, t, seed, salt2)

		// assert that the results are different
		assert.NotEqual(t, rand1, rand2)
	})
}
