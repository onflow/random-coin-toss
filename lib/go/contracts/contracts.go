package contracts

//go:generate go run github.com/kevinburke/go-bindata/go-bindata -prefix ../../../contracts -o internal/assets/assets.go -pkg assets -nometadata -nomemcopy ../../../contracts

import (
    "regexp"

    _ "github.com/kevinburke/go-bindata"

    "github.com/onflow/flow-go-sdk"

    "github.com/onflow/random-coin-toss/lib/go/contracts/internal/assets"   
)

var (
    placeholderNonFungibleToken   		= regexp.MustCompile(`"NonFungibleToken"`)
    placeholderFungibleToken			= regexp.MustCompile(`"FungibleToken"`)
    placeholderResolver					= regexp.MustCompile(`"ViewResolver"`)
    placeholderMetadataViews      		= regexp.MustCompile(`"MetadataViews"`)
    placeholderRandomBeaconHistory		= regexp.MustCompile(`"RandomBeaconHistory"`)
    placeholderPseudoRandomGenerator	= regexp.MustCompile(`"PseudoRandomGenerator"`)
    placeholderCoinToss			      	= regexp.MustCompile(`"CoinToss"`)
)

const (
    filenameNonFungibleToken    	= "utility/NonFungibleToken.cdc"
    filenameFungibleToken       	= "utility/FungibleToken.cdc"
    filenameResolver            	= "utility/ViewResolver.cdc"
    filenameMetadataViews       	= "utility/MetadataViews.cdc"
    filenameRandomBeaconHistory 	= "RandomBeaconHistory.cdc"
    filenamePseudoRandomGenerator	= "PseudoRandomGenerator.cdc"
    filenameCoinToss				= "CoinToss.cdc"
)

// NonFungibleToken returns the NonFungibleToken contract interface.
func NonFungibleToken() []byte {
    code := assets.MustAssetString(filenameNonFungibleToken)
    return []byte(code)
}

// FungibleToken returns the FungibleToken contract interface.
func FungibleToken() []byte {
    return assets.MustAsset(filenameFungibleToken)
}

func Resolver() []byte {
    code := assets.MustAssetString(filenameResolver)

    return []byte(code)
}

func MetadataViews(ftAddress, nftAddress, resolverAddress flow.Address) []byte {
    code := assets.MustAssetString(filenameMetadataViews)

    code = placeholderFungibleToken.ReplaceAllString(code, "0x"+ftAddress.String())
    code = placeholderNonFungibleToken.ReplaceAllString(code, "0x"+nftAddress.String())
    code = placeholderResolver.ReplaceAllString(code, "0x"+resolverAddress.String())

    return []byte(code)
}

func RandomBeaconHistory() []byte {
    return assets.MustAsset(filenameRandomBeaconHistory)
}

func PseudoRandomGenerator() []byte {
    return assets.MustAsset(filenamePseudoRandomGenerator)
}
