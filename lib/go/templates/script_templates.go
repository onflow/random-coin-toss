package templates

import (
	"github.com/onflow/flow-go-sdk"

	"github.com/onflow/random-coin-toss/lib/go/templates/internal/assets"
)

const (
	filenameNextUInt64NewPRG      = "scripts/pseudo-random-generator/next_uint64_new_prg.cdc"
	filenameNextUInt64FromAddress = "scripts/pseudo-random-generator/next_uint64_from_address.cdc"
)

func GenerateNextUInt64NewPRG(prgAddress flow.Address) []byte {
	code := assets.MustAssetString(filenameNextUInt64NewPRG)
	return replaceAddresses(code, flow.EmptyAddress, flow.EmptyAddress, flow.EmptyAddress, flow.EmptyAddress, flow.EmptyAddress, prgAddress, flow.EmptyAddress)
}

func GenerateNextUInt64FromAddress(prgAddress flow.Address) []byte {
	code := assets.MustAssetString(filenameNextUInt64FromAddress)
	return replaceAddresses(code, flow.EmptyAddress, flow.EmptyAddress, flow.EmptyAddress, flow.EmptyAddress, flow.EmptyAddress, prgAddress, flow.EmptyAddress)
}
