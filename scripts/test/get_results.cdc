import "RandomResultStorage"

/// This contract & script is intended for this project's statistical testing which needs persistent PRG state
/// across large numbers of random number generations.
///
/// Returns result array from the storage contract
///
access(all) fun main(): [UInt64] {
    return *RandomResultStorage.results
}