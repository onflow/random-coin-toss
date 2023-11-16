package test

import (
	"crypto/rand"
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/stretchr/testify/require"
)

/* --- Scripts helpers --- */

// calls a script which creates a new PRG struct from the given seed and
// random salt and gets the next uint64
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
	t.Helper()

	var value uint64
	err := o.Script(
		"test/next_uint64",
		WithArg("sourceOfRandomness", seed),
		WithArg("salt", salt),
	).MarshalAs(value)

	require.NoError(t, err)

	// TODO: why do you return err here?
	return value, err
}

// gets the results array from RandomResultStorage contract
func GetResultsFromRandomResultStorage(
	o *OverflowState,
	t *testing.T,
) []uint64 {
	t.Helper()
	var uint64Array []uint64
	err := o.Script("test/get_results").MarshalAs(uint64Array)
	require.NoError(t, err)
	return uint64Array
}

// gets the range of results from RandomResultStorage.results
func GetResultsInRangeFromRandomResultStorage(
	o *OverflowState,
	t *testing.T,
	from int,
	upTo int,
) []uint64 {
	t.Helper()

	var uint64Array []uint64
	err := o.Script(
		"test/get_results_in_range",
		WithArg("from", from),
		WithArg("upTo", upTo),
	).MarshalAs(uint64Array)
	require.NoError(t, err)

	return uint64Array
}

/* --- Transaction helpers --- */

// generates results and stores them in RandomResultStorage contract
func GenerateResultsAndStore(
	o *OverflowState,
	t *testing.T,
	length int,
) {
	t.Helper()
	o.Tx(
		"test/generate_results",
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
	t.Helper()
	o.Tx(
		"test/initialize_prg",
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
		batchSize := min(maxBatchSize, totalSize-startIdx)
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
