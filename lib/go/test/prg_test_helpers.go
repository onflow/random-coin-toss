package test

import (
	"crypto/rand"
	"encoding/binary"
	"testing"

	"github.com/onflow/cadence"
	jsoncdc "github.com/onflow/cadence/encoding/json"
	"github.com/onflow/flow-emulator/adapters"
	"github.com/onflow/flow-emulator/emulator"
	"github.com/onflow/flow-go-sdk"
	"github.com/onflow/random-coin-toss/lib/go/contracts"
	"github.com/onflow/random-coin-toss/lib/go/templates"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func deployPRGContract(
	t *testing.T,
	b emulator.Emulator,
	adapter *adapters.SDKAdapter,
	prgAccountKey *flow.AccountKey,
) flow.Address {

	prgAddress := deploy(t, b, adapter, "PseudoRandomGenerator", contracts.PseudoRandomGenerator())

	return prgAddress
}

// calls a script which creates a new PRG resource from the given seed and
// random salt, gets the next uint64 and destroys the prg resource before
// returning the next uint64
func GetNextUInt64NewPRG(
	t *testing.T,
	b emulator.Emulator,
	adapter *adapters.SDKAdapter,
	prgAddress flow.Address,
	seed []byte,
) (uint64, error) {

	script := templates.GenerateNextUInt64NewPRG(prgAddress)
	result, err := b.ExecuteScript(
		script,
		[][]byte{
			jsoncdc.MustEncode(bytesToCadenceArray(seed)),
			jsoncdc.MustEncode(cadence.NewUInt64(GetRandomSalt(t))),
		},
	)

	if !assert.True(t, result.Succeeded()) {
		t.Log(result.Error.Error())
	}

	return CadenceUInt64ToUInt64(result.Value), err
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

func CadenceUInt64ToUInt64(value cadence.Value) uint64 {
	return uint64(value.(cadence.UInt64))
}
