package templates

import (
	"regexp"

	"github.com/onflow/flow-go-sdk"
)

//go:generate go run github.com/kevinburke/go-bindata/go-bindata -prefix ../../../ -o internal/assets/assets.go -pkg assets -nometadata -nomemcopy ../../../scripts/... ../../../transactions/...

var (
	placeholderNonFungibleToken      = regexp.MustCompile(`"NonFungibleToken"`)
	placeholderFungibleToken         = regexp.MustCompile(`"FungibleToken"`)
	placeholderViewResolver          = regexp.MustCompile(`"ViewResolver"`)
	placeholderMetadataViews         = regexp.MustCompile(`"MetadataViews"`)
	placeholderPseudoRandomGenerator = regexp.MustCompile(`"PseudoRandomGenerator"`)
	placeholderRandomBeaconHistory   = regexp.MustCompile(`"RandomBeaconHistory"`)
	placeholderCoinToss              = regexp.MustCompile(`"CoinToss"`)
)

func replaceAddresses(code string, nftAddr, metadataAddr, ftAddr, resolverAddr, randHistoryAddr, prgAddr, coinTossAddr flow.Address) []byte {
	code = placeholderNonFungibleToken.ReplaceAllString(code, "0x"+nftAddr.String())
	code = placeholderMetadataViews.ReplaceAllString(code, "0x"+metadataAddr.String())
	code = placeholderFungibleToken.ReplaceAllString(code, "0x"+ftAddr.String())
	code = placeholderViewResolver.ReplaceAllString(code, "0x"+resolverAddr.String())
	code = placeholderRandomBeaconHistory.ReplaceAllString(code, "0x"+randHistoryAddr.String())
	code = placeholderPseudoRandomGenerator.ReplaceAllString(code, "0x"+prgAddr.String())
	code = placeholderCoinToss.ReplaceAllString(code, "0x"+coinTossAddr.String())
	return []byte(code)
}
