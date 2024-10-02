import Test
import BlockchainHelpers
import "test_helpers.cdc"

import "CoinToss"
import "RandomConsumer"

access(all) let serviceAccount = Test.serviceAccount()
access(all) let coinToss = Test.getAccount(0x0000000000000007)

access(all) let multiplier = 2.0

access(all)
fun setup() {

    mintFlow(to: coinToss, amount: 20_000_000.0)

    var err = Test.deployContract(
        name: "Xorshift128plus",
        path: "../contracts/Xorshift128plus.cdc",
        arguments: []
    )
    Test.expect(err, Test.beNil())
    err = Test.deployContract(
        name: "RandomConsumer",
        path: "../contracts/RandomConsumer.cdc",
        arguments: []
    )
    Test.expect(err, Test.beNil())
    err = Test.deployContract(
        name: "CoinToss",
        path: "../contracts/CoinToss.cdc",
        arguments: [multiplier]
    )
    Test.expect(err, Test.beNil())
}

access(all)
fun testCommitSucceeds() {
    let user = Test.createAccount()
    mintFlow(to: user, amount: 1000.0)

    let betAmount: UFix64 = 100.0

    let commitRes = executeTransaction(
        "../transactions/coin-toss/0_flip_coin.cdc",
        [betAmount],
        user
    )
    Test.expect(commitRes, Test.beSucceeded())

    let requestedEvts = Test.eventsOfType(Type<RandomConsumer.RandomnessRequested>())
    Test.assertEqual(1, requestedEvts.length)
    let flippedEvts = Test.eventsOfType(Type<CoinToss.CoinFlipped>())
    Test.assertEqual(1, flippedEvts.length)

    let balance = getCadenceBalance(user.address)
    Test.assertEqual(900.0, balance)
}

access(all)
fun testCommitAndRevealSucceeds() {
    let user = Test.createAccount()
    mintFlow(to: user, amount: 1000.0)

    let betAmount: UFix64 = 100.0

    let commitRes = executeTransaction(
        "../transactions/coin-toss/0_flip_coin.cdc",
        [betAmount],
        user
    )
    Test.expect(commitRes, Test.beSucceeded())

    let requestedEvts = Test.eventsOfType(Type<RandomConsumer.RandomnessRequested>())
    Test.assertEqual(2, requestedEvts.length)
    let flippedEvts = Test.eventsOfType(Type<CoinToss.CoinFlipped>())
    Test.assertEqual(2, flippedEvts.length)

    let balance = getCadenceBalance(user.address)
    Test.assertEqual(900.0, balance)

    let revealRes = executeTransaction(
        "../transactions/coin-toss/1_reveal_coin.cdc",
        [],
        user
    )
    Test.expect(revealRes, Test.beSucceeded())

    let sourcedEvts = Test.eventsOfType(Type<RandomConsumer.RandomnessSourced>())
    let fulfilledEvts = Test.eventsOfType(Type<RandomConsumer.RandomnessFulfilled>())
    let revealedEvts = Test.eventsOfType(Type<CoinToss.CoinRevealed>())
    Test.assertEqual(1, sourcedEvts.length)
    Test.assertEqual(1, fulfilledEvts.length)
    Test.assertEqual(1, revealedEvts.length)
}