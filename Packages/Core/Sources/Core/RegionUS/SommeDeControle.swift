import Foundation
import CryptoKit

/// SHA-256 en hexadécimal minuscule, pour comparer un fichier à la somme de l'index.
enum SommeDeControle {
    static func sha256(_ donnees: Data) -> String {
        SHA256.hash(data: donnees).map { String(format: "%02x", $0) }.joined()
    }
}
