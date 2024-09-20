import "EVM"

access(all)
fun main(evmAddressHex: String): UFix64 {
    return EVM.addressFromString(evmAddressHex).balance().inFLOW()
}