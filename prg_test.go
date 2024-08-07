package test

import (
	"math"
	mrand "math/rand"
	"testing"

	. "github.com/bjartek/overflow/v2"
	"github.com/onflow/flow-go/crypto/random"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestNextUInt64NewPRG(t *testing.T) {
	o, err := OverflowTesting()
	assert.NoError(t, err)

	t.Run("Should generate uniform distribution", func(t *testing.T) {
		// make sure n is a power of 2 so that there is no bias in the last class
		// n is a random power of 2 (from 2 to 2^10)
		n := 1 << (1 + mrand.Intn(10))
		classWidth := (math.MaxUint64 / uint64(n)) + 1
		var sampleSize int

		// taken from BasicDistributionTest constants - hardcoding here is
		/// fragile, but it's determined within flow-go/crypto/rand_utils
		if n < 80 {
			// but if `n` is too small, we use a "high enough" sample size
			// If n is small, use a sample size just under 85000
			sampleSize = (85000 / n) * n // highest multiple of n less than 80000
		} else {
			// If n is 80 or larger, use a sample size that is n * 1000
			sampleSize = n * 1000
		}

		// initialize PRG object in RandomResultStorage helper contract
		seed := GetRandomBytes(t, 32)
		salt := GetRandomBytes(t, 8)
		InitializePRG(o, t, seed, salt)

		maxBatchSize := 5000
		// generate results in batches due to transaction computational limit
		ProcessBatches(sampleSize, maxBatchSize, func(startIdx, batchSize int) {
			GenerateResultsAndStore(o, t, batchSize)
		})

		// get the results in batches again due to query computational limit
		results := make([]uint64, sampleSize)
		ProcessBatches(sampleSize, maxBatchSize, func(startIdx, batchSize int) {
			tmpResults := GetResultsInRangeFromRandomResultStorage(o, t,
				startIdx, startIdx+batchSize,
			)
			copy(results[startIdx:], tmpResults)
		})

		assert.Equal(t, sampleSize, len(results))

		// define a function that returns the next result within BasicDistributionTest
		i := 0
		uintf := func() (uint64, error) {
			assert.Less(t, i, len(results))
			result := results[i]
			i++
			return result, nil
		}

		// assertion of uniform distribution is done in BasicDistributionTest
		random.BasicDistributionTest(t, uint64(n), uint64(classWidth), uintf)
	})

	t.Run("Should generate different results given different seeds & same salt", func(t *testing.T) {

		seed1 := GetRandomBytes(t, 32)
		seed2 := GetRandomBytes(t, 32)
		salt := GetRandomBytes(t, 8)

		assert.NotEqual(t, seed1, seed2)

		rand1, err1 := GetNextUInt64NewPRGWithSalt(o, t, seed1, salt)
		rand2, err2 := GetNextUInt64NewPRGWithSalt(o, t, seed2, salt)

		require.NoError(t, err1)
		require.NoError(t, err2)

		// assert that the results are different
		assert.NotEqual(t, rand1, rand2)
	})

	t.Run("Should generate different results given same seed & different salt", func(t *testing.T) {

		seed := GetRandomBytes(t, 32)
		salt1 := GetRandomBytes(t, 8)
		salt2 := GetRandomBytes(t, 8)

		assert.NotEqual(t, salt1, salt2)

		rand1, err1 := GetNextUInt64NewPRGWithSalt(o, t, seed, salt1)
		rand2, err2 := GetNextUInt64NewPRGWithSalt(o, t, seed, salt2)

		require.NoError(t, err1)
		require.NoError(t, err2)

		// assert that the results are different
		assert.NotEqual(t, rand1, rand2)
	})

	t.Run("Should fail PRG init with array.length < 16", func(t *testing.T) {

		_, err := GetNextUInt64NewPRGRandSalt(o, t, GetRandomBytes(t, 15))

		assert.Error(t, err)
	})
}
