package test

import (
	"crypto/rand"
	"encoding/binary"
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/onflow/cadence"
	"github.com/stretchr/testify/require"
)

// calls a script which creates a new PRG resource from the given seed and
// random salt, gets the next uint64 and destroys the prg resource before
// returning the next uint64
func GetNextUInt64NewPRG(
	o *OverflowState,
	t *testing.T,
	seed []byte,
) (uint64, error) {

	randResult := o.Script(
		"pseudo-random-generator/next_uint64_new_prg",
		WithArg("seed", seed),
		WithArg("salt", GetRandomSalt(t)),
	)

	require.NoError(t, randResult.Err)

	return uint64(randResult.Result.(cadence.UInt64)), randResult.Err
}

// gets a random 32 byte array using crypto/rand
func GetRandomSeed(t *testing.T) []byte {
	buf := make([]byte, 32)

	_, err := rand.Read(buf)
	require.NoError(t, err)

	return buf
}

// gets a random uint64 using crypto/rand
func GetRandomSalt(t *testing.T) uint64 {
	var b [8]byte

	_, err := rand.Read(b[:])
	require.NoError(t, err)

	value := binary.BigEndian.Uint64(b[:])

	return value
}
