import "RandomConsumer"

/// Returns the block beyond which a given Request can be fulfilled
///
/// @param requestAddress: The address where the Request is stored
/// @param requestStoragePath: The StoragePath where the Request is stored in the requestAddress account
///
/// @return The block beyond which a given Request can be fulfilled, `nil` if the Request is not found
access(all)
fun main(requestAddress: Address, requestStoragePath: StoragePath): Bool? {
    if let request = getAuthAccount<auth(Storage) &Account>(requestAddress).storage
        .borrow<&RandomConsumer.Request>(from: requestStoragePath) {
        return request.canFullfill()
    }
    return nil
}
