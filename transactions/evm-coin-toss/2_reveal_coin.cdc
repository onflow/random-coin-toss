import "EVM"

/// Calls the CoinToss.revealCoin() method in the specified contract address, completing the reveal step in the CoinToss
/// contract's two-step commit-reveal coin toss. If the random result is heads (0), the caller wins a prize double the
/// value they submitted in the flipCoin() transaction.
///
transaction(coinTossContractAddress: String) {
    /// The CadenceOwnedAccount reference used to call the flipCoin() method
    let coa: auth(EVM.Call) &EVM.CadenceOwnedAccount

    prepare(signer: auth(BorrowValue) &Account) {
        self.coa = signer.storage.borrow<auth(EVM.Call) &EVM.CadenceOwnedAccount>(from: /storage/evm)
            ?? panic("Missing or mis-typed CadenceOwnedAccount at /storage/evm")
    }

    execute {
        // Deserialize the contract address string into an Address object
        let contractAddress = EVM.addressFromString(coinTossContractAddress)
        // Encode the revealCoin() method signature and parameters as calldata
        let calldata = EVM.encodeABIWithSignature("revealCoin()", [])
        // The value sent with the call to revealCoin() is zero
        let value = EVM.Balance(attoflow: 0)

        // Call the revealCoin() method in the CoinToss contract
        let callResult = self.coa.call(
            to: contractAddress,
            data: calldata,
            gasLimit: 15_000_000,
            value: value
        )

        assert(
            callResult.status == EVM.Status.successful,
            message: "Call to ".concat(coinTossContractAddress).concat(" failed with error code=")
                .concat(callResult.errorCode.toString()).concat(" and message=").concat(callResult.errorMessage)
        )
    }
}
