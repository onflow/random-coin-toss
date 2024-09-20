import Test
import BlockchainHelpers

import "test_helpers.cdc"

import "EVM"

access(all) let serviceAccount = Test.serviceAccount()
access(all) let user = Test.createAccount()
access(all) var userCOAAddress = ""
access(all) var coinTossAddress = ""

access(all)
fun setup() {
    // Create COA in service account
    var coaResult = executeTransaction(
        "../transactions/evm-coin-toss/0_create_coa.cdc",
        [100.0],
        serviceAccount
    )
    Test.expect(coaResult, Test.beSucceeded())

    // fund user account with FLOW
    mintFlow(to: user, amount: 1000.0)
    
    // create CadenceOwnedAccount
    coaResult = executeTransaction(
        "../transactions/evm-coin-toss/0_create_coa.cdc",
        [100.0],
        user
    )
    Test.expect(coaResult, Test.beSucceeded())

    // get the coa hex from the emitted event
    var evts = Test.eventsOfType(Type<EVM.CadenceOwnedAccountCreated>())
    Test.assertEqual(2, evts.length)
    var coaEvent = evts[1] as! EVM.CadenceOwnedAccountCreated
    userCOAAddress = coaEvent.address

    // deploy the CoinToss contract from the compiled bytecode
    let deployResult = executeTransaction(
        "../transactions/evm/deploy.cdc",
        [getCoinTossBytecode(), UInt64(1_000_000), 0.0],
        user
    )
    Test.expect(deployResult, Test.beSucceeded())

    // get the deployed contract address from the emitted event
    evts = Test.eventsOfType(Type<EVM.TransactionExecuted>())
    Test.assertEqual(5, evts.length)
    let deployEvent = evts[4] as! EVM.TransactionExecuted
    coinTossAddress = deployEvent.contractAddress

    // fund the CoinToss contract with FLOW
    let depositResult = executeTransaction(
        "../transactions/evm/deposit_flow.cdc",
        [coinTossAddress, 100.0],
        // [userCOAAddress, 100.0],
        serviceAccount
    )
    Test.expect(depositResult, Test.beSucceeded())

    // confirm starting EVM balances
    let coaBalance = getEVMBalance(userCOAAddress)
    Test.assertEqual(100.0, coaBalance)

    let contractBalance = getEVMBalance(coinTossAddress)
    Test.assertEqual(100.0, contractBalance)
}

access(all)
fun testFlipCoinSucceeds() {
    // flip the coin
    let flipResult = executeTransaction(
        "../transactions/evm-coin-toss/1_flip_coin.cdc",
        [coinTossAddress, 1.0],
        user
    )
    Test.expect(flipResult, Test.beSucceeded())
}

access(all)
fun testFlipCoinWithOpenBetFails() {
    // flip the coin
    let flipResult = executeTransaction(
        "../transactions/evm-coin-toss/1_flip_coin.cdc",
        [coinTossAddress, 1.0],
        user
    )
    Test.expect(flipResult, Test.beFailed())
}

access(all)
fun testRevealCoinSucceeds() {
    // reveal the coin flip
    let revealResult = executeTransaction(
        "../transactions/evm-coin-toss/2_reveal_coin.cdc",
        [coinTossAddress],
        user
    )
    Test.expect(revealResult, Test.beSucceeded())
}