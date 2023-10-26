package templates

import (
	"github.com/onflow/flow-go-sdk"

	_ "github.com/kevinburke/go-bindata"

	"github.com/onflow/random-coin-toss/lib/go/templates/internal/assets"
)

const (
	filenameSetupPRG   = "transactions/pseudo-random-generator/setup_prg.cdc"
	filenameNextUInt64 = "transactions/pseudo-random-generator/next_uint64.cdc"
)

func GenerateSetupPRGScript(prgAddress flow.Address) []byte {
	code := assets.MustAssetString(filenameSetupPRG)
	return replaceAddresses(code,
		flow.EmptyAddress,
		flow.EmptyAddress,
		flow.EmptyAddress,
		flow.EmptyAddress,
		flow.EmptyAddress,
		prgAddress,
		flow.EmptyAddress)
}

func GenerateNextUInt64Script(prgAddress flow.Address) []byte {
	code := assets.MustAssetString(filenameSetupPRG)
	return replaceAddresses(code,
		flow.EmptyAddress,
		flow.EmptyAddress,
		flow.EmptyAddress,
		flow.EmptyAddress,
		flow.EmptyAddress,
		prgAddress,
		flow.EmptyAddress)
}
