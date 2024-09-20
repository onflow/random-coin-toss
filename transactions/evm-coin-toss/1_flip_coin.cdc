import "EVM"

/// Calls the CoinToss.flipCoin() method in the specified contract address, completing the commit step in the CoinToss
/// contract's two-step commit-reveal coin toss.
///
transaction(coinTossContractAddress: String, amount: UFix64) {
    /// The CadenceOwnedAccount reference used to call the flipCoin() method
    let coa: auth(EVM.Call) &EVM.CadenceOwnedAccount

    prepare(signer: auth(BorrowValue) &Account) {
        self.coa = signer.storage.borrow<auth(EVM.Call) &EVM.CadenceOwnedAccount>(from: /storage/evm)
            ?? panic("Missing or mis-typed CadenceOwnedAccount at /storage/evm")
    }

    execute {
        // Deserialize the contract address string into an Address object
        let contractAddress = EVM.addressFromString(coinTossContractAddress)

        // Encode the flipCoin() method signature and parameters as calldata
        let calldata = EVM.encodeABIWithSignature("flipCoin()", [])

        // The value sent with the call to flipCoin() is the amount of FLOW tokens to wager
        let value = EVM.Balance(attoflow: 0)
        value.setFLOW(flow: amount)

        // Call the flipCoin() method in the CoinToss contract
        let callResult = self.coa.call(
            to: contractAddress,
            data: calldata,
            gasLimit: 15_000_000,
            value: value
        )

        assert(
            callResult.status == EVM.Status.successful,
            message: "Call to ".concat(coinTossContractAddress).concat(" failed with error code=")
                .concat(callResult.errorCode.toString())
        )
    }
}
