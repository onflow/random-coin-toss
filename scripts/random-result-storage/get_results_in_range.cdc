import "RandomResultStorage"

/// This contract & script is intended for this project's statistical testing which needs persistent PRG state
/// across large numbers of random number generations.
///
/// Returns a slice of results from the storage contract - panics if out of bounds.
///
access(all) fun main(from: Int, upTo: Int): [UInt64] {
    return RandomResultStorage.results.slice(from: from, upTo: upTo)
}
