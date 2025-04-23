import "RandomConsumer"

/// Simple data struct representing Request state
access(all) struct RandomRequestInfo {
    /// The block height at which the request was made
    access(all) let block: UInt64
    /// Whether the request has been fulfilled
    access(all) var fulfilled: Bool

    init(_ blockHeight: UInt64, _ fulfilled: Bool) {
        self.block = blockHeight
        self.fulfilled = fulfilled
    }
}

/// Returns the Request's block and whether it can be fulfilled. `nil` is returned if no Request was found
///
/// @param requestAddress: The address where the Request is stored
/// @param requestStoragePath: The StoragePath where the Request is stored in the requestAddress account
///
/// @return A RandomRequestInfo struct containing the Request's state or `nil` if no Request was found
access(all)
fun main(requestAddress: Address, requestStoragePath: StoragePath): RandomRequestInfo? {
    if let request = getAuthAccount<auth(Storage) &Account>(requestAddress).storage
        .borrow<&RandomConsumer.Request>(from: requestStoragePath) {
        return RandomRequestInfo(request.block, request.canFullfill())
    }
    return nil
}
