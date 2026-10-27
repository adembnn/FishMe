# Spark Flash

Spark Flash is the entry-level tier of MWM's **Spark** family of SDKs. It provides analytics event tracking, purchase transactions recording, and session measurement in a lightweight, dependency-free package.

Current Version: ![Static Badge](https://img.shields.io/badge/MWM_Spark_Flash-0.5.7-FF5301)

## Requirements

- iOS 15.0+
- Swift 5.0+
- Xcode 26+

## Installation

### Xcode

Add the dependency as a local SPM package via Xcode's package manager [Xcode's package manager](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app). 

Then link the `Spark` product library to your app project in the `Frameworks and Libraries` panel in Xcode's `General` settings.

## Getting Started

### 1. Configure the SDK

Call `Spark.configure(_:)` as early as possible in your app's lifecycle, before accessing `Spark.shared`. It must be called on the main actor.

**SwiftUI**

```swift
import Spark

@main
struct MyApp: App {
    init() {
[ligne retirée : mention d'identifiants ou de secret, voir le fichier d'origine en local]
            .build()

        Spark.configure(
            configuration
        )
    }

    var body: some Scene {
        WindowGroup { ContentView() }
    }
}
```

**UIKit**

```swift
import Spark

@MainActor
func application(_ application: UIApplication, didFinishLaunchingWithOptions ...) -> Bool {
    Spark.configure(
[ligne retirée : mention d'identifiants ou de secret, voir le fichier d'origine en local]
            .build()
    )
    return true
}
```

> **Note:** Calling `Spark.shared` before `configure(_:)` will raise a fatal error.
> Calling `configure(_:)` more than once will also raise a fatal error.

### Configuration parameters

[ligne retirée : mention d'identifiants ou de secret, voir le fichier d'origine en local]

| Parameter | Description |
|---|---|
[ligne retirée : mention d'identifiants ou de secret, voir le fichier d'origine en local]
| `withDebugMode(_:)` | Enables debug mode. Defaults to `false`. |
| `withMwmAppId(_:)` | Legacy MWM internal identifier (e.g. `"my_app"`). Defaults to `""`. |
[ligne retirée : mention d'identifiants ou de secret, voir le fichier d'origine en local]

Those elements are available in the MWM Console Dashboard: `Product Analytics / Configuration`.

## API Reference

### `Spark`

The main entry point. Access the singleton via `Spark.shared` after configuration.

```swift
public final class Spark: SparkInterface {
    public static var shared: SparkInterface { get }

    @MainActor
    public static func configure(_ config: Configuration)
}
```

### `SparkInterface`

```swift
public protocol SparkInterface: Sendable {
    var analytics: Analytics { get }
    var monetization: Monetization { get }
}
```


### Analytics

To track custom events using `Spark.shared.analytics` —for example, when a user clicks a button— use the analytics feature provided by the SDK.

You can monitor custom events on the Spark dashboard, in the `Product Analytics / Events` page.

```swift
public protocol Analytics: Sendable {
    func logEvent(type: String, properties: [String: Any]?)
}
```

**Log a simple event**

```swift
Spark.shared.analytics.logEvent(type: "tutorial_completed", properties: nil)
```

**Log an event with additional data**

Dictionary values are recursively validated for JSON compatibility. Non-serialisable values (e.g. `Date`) are silently filtered out with a warning.

```swift
Spark.shared.analytics.logEvent(
    type: "level_completed",
    properties: [
        "level": 3,
        "score": 14200,
        "perfect": true
    ]
)
```

### Monetization

Record StoreKit 2 transactions using `Spark.shared.monetization`. This submits transaction data to MWM's backend for validation and tracking.

```swift
public protocol Monetization: Sendable {
    func recordTransactions(_ transactionJWSRepresentations: [String]) async throws
    func recordTransactions(_ verificationResult: [VerificationResult<Transaction>]) async throws
    func recordPurchase(_ purchaseResult: Product.PurchaseResult) async throws
}

public enum MonetizationError: Error {
    case incompletePayment      // Purchase is pending
    case unknownPurchaseResult  // Unexpected StoreKit result
}
```

**Record directly from a StoreKit purchase result**

```swift
let result = try await product.purchase()
try await Spark.shared.monetization.recordPurchase(result)
```

**Record from verification results** (e.g. on background transaction updates)

```swift
for await verificationResult in Transaction.updates {
    try await Spark.shared.monetization.recordTransactions([verificationResult])
}
```

**Record from raw JWS strings** (advanced)

```swift
try await Spark.shared.monetization.recordTransactions(jwsStrings)
```

**Record along with RevenueCat SDK** (advanced)

RevenueCat manages the purchase flow and does not expose a StoreKit `VerificationResult` directly. After a successful RevenueCat purchase, use StoreKit's `Transaction.latest(for:)` to retrieve the latest verified transaction for the product and pass its JWS representation to Spark.

```swift
import RevenueCat
import StoreKit
import Spark

func purchase(package: Package) async throws {
    // 1. Let RevenueCat handle the purchase
    let result = try await Purchases.shared.purchase(package: package)

    guard !result.userCancelled else { return }

    // 2. Retrieve the latest StoreKit transaction for this product
    let productID = package.storeProduct.productIdentifier
    guard let transaction = await Transaction.latest(for: productID) else { return }

    // 3. Forward the JWS representation to Spark
    try await Spark.shared.monetization.recordTransactions([transaction.jwsRepresentation])
}
```

> `Transaction.latest(for:)` returns the most recent verified transaction for a given product ID directly from StoreKit, independently of RevenueCat. It is safe to call immediately after a RevenueCat purchase completes.

**Disclaimer**: _RevenueCat is a trademark of RevenueCat, Inc. — MWM is not affiliated with or sponsored by RevenueCat._

### `SparkFlavor`

Metadata about the current Spark tier.

```swift
public enum SparkFlavor {
    public static let version: String  // e.g. "1.0.0"
    public static let name: String     // "Flash"
}
```
