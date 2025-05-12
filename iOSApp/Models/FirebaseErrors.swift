import Foundation

enum FirebaseError: LocalizedError {
    case authenticationError(String)
    case documentNotFound(String)
    case invalidData(String)
    case transactionFailed(String)
    case batchOperationFailed(String)
    case cacheError(String)
    case networkError(String)
    case permissionDenied(String)
    case quotaExceeded(String)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .authenticationError(let message):
            return "Authentication Error: \(message)"
        case .documentNotFound(let message):
            return "Document Not Found: \(message)"
        case .invalidData(let message):
            return "Invalid Data: \(message)"
        case .transactionFailed(let message):
            return "Transaction Failed: \(message)"
        case .batchOperationFailed(let message):
            return "Batch Operation Failed: \(message)"
        case .cacheError(let message):
            return "Cache Error: \(message)"
        case .networkError(let message):
            return "Network Error: \(message)"
        case .permissionDenied(let message):
            return "Permission Denied: \(message)"
        case .quotaExceeded(let message):
            return "Quota Exceeded: \(message)"
        case .unknown(let message):
            return "Unknown Error: \(message)"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .authenticationError:
            return "The user is not authenticated or the authentication token is invalid"
        case .documentNotFound:
            return "The requested document does not exist"
        case .invalidData:
            return "The data format is invalid or missing required fields"
        case .transactionFailed:
            return "The database transaction could not be completed"
        case .batchOperationFailed:
            return "The batch write operation failed"
        case .cacheError:
            return "There was an error accessing or updating the cache"
        case .networkError:
            return "There was a problem with the network connection"
        case .permissionDenied:
            return "The user does not have permission to perform this operation"
        case .quotaExceeded:
            return "The operation would exceed the allowed quota"
        case .unknown:
            return "An unexpected error occurred"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .authenticationError:
            return "Please sign in again or check your authentication status"
        case .documentNotFound:
            return "Verify the document ID and try again"
        case .invalidData:
            return "Check the data format and ensure all required fields are present"
        case .transactionFailed:
            return "Try the operation again or contact support if the problem persists"
        case .batchOperationFailed:
            return "Try the operation again with a smaller batch size"
        case .cacheError:
            return "Try clearing the cache and restarting the app"
        case .networkError:
            return "Check your internet connection and try again"
        case .permissionDenied:
            return "Contact your administrator for access"
        case .quotaExceeded:
            return "Try again later or contact support to increase your quota"
        case .unknown:
            return "Try again or contact support if the problem persists"
        }
    }
} 