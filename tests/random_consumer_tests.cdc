import Test
import BlockchainHelpers
import "test_helpers.cdc"

import "RandomConsumer"

access(all) let serviceAccount = Test.serviceAccount()
access(all) let randomConsumer = Test.getAccount(0x0000000000000007)

access(all)
fun setup() {
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

    let initRes = executeTransaction("../transactions/random-consumer/initialize_consumer.cdc", [], randomConsumer)
    Test.expect(initRes, Test.beSucceeded())
}

access(all)
fun testRequestRandomnessSucceeds() {
    let signer = Test.createAccount()

    let consumerSetup = executeTransaction("./transactions/create_consumer.cdc", [], signer)
    Test.expect(consumerSetup, Test.beSucceeded())

    let requestStoragePath = /storage/RandomConsumerRequest
    let requestRes = executeTransaction("./transactions/request_randomness.cdc", [requestStoragePath], signer)
    Test.expect(requestRes, Test.beSucceeded())

    let expectedHeight = getCurrentBlockHeight()

    let requestHeightRes = executeScript("./scripts/get_request_blockheight.cdc", [signer.address, requestStoragePath])
    let requestCanFulfillRes = executeScript("./scripts/request_can_fulfill.cdc", [signer.address, requestStoragePath])
    Test.expect(requestHeightRes, Test.beSucceeded())
    Test.expect(requestCanFulfillRes, Test.beSucceeded())
    let requestHeight = requestHeightRes.returnValue! as! UInt64
    let requestCanFulfill = requestCanFulfillRes.returnValue! as! Bool

    Test.assertEqual(expectedHeight, requestHeight)
    Test.assertEqual(false, requestCanFulfill)

}

access(all)
fun testFulfillRandomnessSucceeds() {
    let signer = Test.createAccount()

    let consumerSetup = executeTransaction("./transactions/create_consumer.cdc", [], signer)
    Test.expect(consumerSetup, Test.beSucceeded())

    let requestStoragePath = /storage/RandomConsumerRequest
    let requestRes = executeTransaction("./transactions/request_randomness.cdc", [requestStoragePath], signer)
    Test.expect(requestRes, Test.beSucceeded())

    let fulfillRes = executeTransaction("./transactions/fulfill_random_request.cdc", [requestStoragePath], signer)
    Test.expect(fulfillRes, Test.beSucceeded())
}

access(all)
fun testGetNumberInRangeUpdatesStateSucceeds() {
    let diffPRGRes = executeScript("./scripts/prg_state_advances_on_range_results.cdc", [])
    Test.expect(diffPRGRes, Test.beSucceeded())

    let diff = diffPRGRes.returnValue! as! Bool
    Test.assertEqual(true, diff)
}

access(all)
fun testRequestAndFulfillRandomnessFromContractSucceeds() {
    let signer = Test.createAccount()
    
    let requestRes = executeTransaction(
        "../transactions/random-consumer/request_future_randomness.cdc",
        [nil, /storage/TestRequest],
        signer
    )
    Test.expect(requestRes, Test.beSucceeded())
    let requestedEvts = Test.eventsOfType(Type<RandomConsumer.RandomnessRequested>())
    let requestedEvt = requestedEvts[requestedEvts.length - 1] as! RandomConsumer.RandomnessRequested

    let fulfilledRes = executeTransaction(
        "../transactions/random-consumer/fulfill_random_request.cdc",
        [/storage/TestRequest],
        signer
    )
    Test.expect(fulfilledRes, Test.beSucceeded())
    let fulfilledEvts = Test.eventsOfType(Type<RandomConsumer.RandomnessFulfilled>())
    let fulfilledEvt = fulfilledEvts[fulfilledEvts.length - 1] as! RandomConsumer.RandomnessFulfilled

    Test.assertEqual(requestedEvt.requestUUID, fulfilledEvt.requestUUID)
}

access(all)
fun testRequestAndFulfillRandomnessInRangeFromContractSucceeds() {
    let signer = Test.createAccount()
    let min: UInt64 = 0
    let max: UInt64 = 5
    
    let requestRes = executeTransaction(
        "../transactions/random-consumer/request_future_randomness.cdc",
        [nil, /storage/TestRequest],
        signer
    )
    Test.expect(requestRes, Test.beSucceeded())
    let requestedEvts = Test.eventsOfType(Type<RandomConsumer.RandomnessRequested>())
    let requestedEvt = requestedEvts[requestedEvts.length - 1] as! RandomConsumer.RandomnessRequested

    let fulfilledRes = executeTransaction(
        "../transactions/random-consumer/fulfill_random_request_in_range.cdc",
        [/storage/TestRequest, min, max],
        signer
    )
    Test.expect(fulfilledRes, Test.beSucceeded())
    let fulfilledEvts = Test.eventsOfType(Type<RandomConsumer.RandomnessFulfilled>())
    let fulfilledEvt = fulfilledEvts[fulfilledEvts.length - 1] as! RandomConsumer.RandomnessFulfilled

    Test.assertEqual(requestedEvt.requestUUID, fulfilledEvt.requestUUID)
    Test.assert(min <= fulfilledEvt.randomResult && fulfilledEvt.randomResult <= max)
}