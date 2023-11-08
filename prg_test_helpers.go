package test

import (
	"crypto/rand"
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/onflow/cadence"
	"github.com/stretchr/testify/require"
)

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

// gets a random byte array using crypto/rand
func GetRandomBytes(t *testing.T, len uint64) []byte {
	buf := make([]byte, len)

	_, err := rand.Read(buf)
	require.NoError(t, err)

	return buf
}
