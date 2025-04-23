import "RandomConsumer"

/// Returns whether a particular Request can be fulfilled or not. If a Request is not found, `nil` is returned
///
/// @param requestAddress: The address where the Request is stored
/// @param requestStoragePath: The StoragePath where the Request is stored in the requestAddress account
///
/// @return Whether the request can be fulfilled or not, `nil` if the Request is not found
access(all)
fun main(requestAddress: Address, requestStoragePath: StoragePath): Bool? {
    if let request = getAuthAccount<auth(Storage) &Account>(requestAddress).storage
        .borrow<&RandomConsumer.Request>(from: requestStoragePath) {
        return request.canFullfill()
    }
    return nil
}
