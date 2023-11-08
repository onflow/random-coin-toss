import "RandomResultStorage"

access(all) fun main(from: Int, upTo: Int): [UInt64] {
    return RandomResultStorage.results.slice(from: from, upTo: upTo)
}
