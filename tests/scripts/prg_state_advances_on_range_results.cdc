import "RandomBeaconHistory"
import "RandomConsumer"
import "Xorshift128plus"

/// Test script to ensure PRG state advances across calls to
access(all)
fun main(): Bool {
    // Instantiate PRG
    let sor = RandomBeaconHistory.sourceOfRandomness(atBlockHeight: getCurrentBlock().height - 1)
    let salt = UInt64.max
    let prg = Xorshift128plus.PRG(sourceOfRandomness: sor.value, salt: salt.toBigEndianBytes())
    // Reference new PRG
    let prgRef: &Xorshift128plus.PRG = &prg

    // Call params
    let min: UInt64 = 0
    let max: UInt64 = 100

    // Ensure PRG state changes between calls
    let preState0 = prg.state0
    let preState1 = prg.state1

    RandomConsumer.getNumberInRange(prg: prgRef, min: min, max: max)

    let postState0 = prg.state0
    let postState1 = prg.state1

    // Ensure state on the PRG struct changed as a result of the getNumberInRange() call
    return preState0 != postState0 && preState1 != postState1
}
