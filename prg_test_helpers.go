package test

import (
	"crypto/rand"
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/onflow/cadence"
	"github.com/stretchr/testify/require"
)

/* --- Scripts helpers --- */

// calls a script which creates a new PRG struct from the given seed and
// random salt, gets the next uint64 and destroys the prg resource before
// returning the next uint64
func GetNextUInt64NewPRGRandSalt(
	o *OverflowState,
	t *testing.T,
	seed []byte,
) (uint64, error) {

	return GetNextUInt64NewPRGWithSalt(
		o,
		t,
		seed,
		GetRandomBytes(t, 8),
	)
}

// gets a random uint64 from a newly instantiated PRG struct
func GetNextUInt64NewPRGWithSalt(
	o *OverflowState,
	t *testing.T,
	seed []byte,
	salt []byte,
) (uint64, error) {

	randResult := o.Script(
		"xorshift128plus/next_uint64",
		WithArg("sourceOfRandomness", seed),
		WithArg("salt", salt),
	)

	require.NoError(t, randResult.Err)

	return uint64(randResult.Result.(cadence.UInt64)), randResult.Err
}

// gets the results array from RandomResultStorage contract
func GetResultsFromRandomResultStorage(
	o *OverflowState,
	t *testing.T,
) []uint64 {

	results := o.Script("random-result-storage/get_results")

	require.NoError(t, results.Err)

	var uint64Array []uint64
	for _, value := range results.Result.(cadence.Array).Values {
		uint64Array = append(uint64Array, uint64(value.(cadence.UInt64)))
	}
	return uint64Array
}

// gets the range of results from RandomResultStorage.results
func GetResultsInRangeFromRandomResultStorage(
	o *OverflowState,
	t *testing.T,
	from int,
	upTo int,
) []uint64 {

	results := o.Script(
		"random-result-storage/get_results_in_range",
		WithArg("from", from),
		WithArg("upTo", upTo),
	)

	require.NoError(t, results.Err)

	var uint64Array []uint64
	for _, value := range results.Result.(cadence.Array).Values {
		uint64Array = append(uint64Array, uint64(value.(cadence.UInt64)))
	}
	return uint64Array
}

/* --- Transaction helpers --- */

// generates results and stores them in RandomResultStorage contract
func GenerateResultsAndStore(
	o *OverflowState,
	t *testing.T,
	length int,
) {

	o.Tx(
		"random-result-storage/generate_results",
		WithSignerServiceAccount(),
		WithArg("generationLength", length),
	).AssertSuccess(t)
}

// initializes PRG object in RandomResultStorage helper contract
func InitializePRG(
	o *OverflowState,
	t *testing.T,
	seed []byte,
	salt []byte,
) {

	o.Tx(
		"random-result-storage/initialize_prg",
		WithSignerServiceAccount(),
		WithArg("sourceOfRandomness", seed),
		WithArg("salt", salt),
	).AssertSuccess(t)
}

/* --- Utils --- */

// gets a random byte array using crypto/rand
func GetRandomBytes(t *testing.T, len uint64) []byte {
	buf := make([]byte, len)

	_, err := rand.Read(buf)
	require.NoError(t, err)

	return buf
}

// processes a task in batches
func ProcessBatches(totalSize, maxBatchSize int, processFunc func(startIdx, batchSize int)) {
	for startIdx := 0; startIdx < totalSize; startIdx += maxBatchSize {
		batchSize := Min(maxBatchSize, totalSize-startIdx)
		processFunc(startIdx, batchSize)
	}
}

// returns the minimum of two integers
func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
