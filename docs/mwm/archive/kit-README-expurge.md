# Build Challenge - Starter kit

Welcome to Build Challenge #2, team **Frétille**! 🚀

Hi Adem, Sullyvan and Titouan, we're thrilled to have you here. You have been assigned team number
**01** for the duration of the event. Your team will turn an idea into a real iOS app, ready for the App
Store. The setup is done: a SwiftUI Xcode project already wired to the **MWM Spark SDK** (analytics
and purchase tracking) and to your team's in-app subscriptions. MWM's tools and the MWM team are
here to help you go further, faster.

Be bold, test often, and have fun!

> [!WARNING]
> **Don't underestimate the App Store submission.** A first submission asks for a lot of
> information in App Store Connect: texts, screenshots, legal URLs, privacy and age rating
> questionnaires, subscription details… It always takes longer than expected. Start on day one, in
> parallel with code, design and product. The [MWM MCP](#mwm-mcp) can help with several of these
> steps.

## Contact

Questions about iOS, App Store Connect, the MWM Spark SDK or the MWM MCP? Email
[build-challenge@mwm.ai](mailto:build-challenge@mwm.ai).

## Your MWM account

[ligne retirée : mention d'identifiants ou de secret, voir le fichier d'origine en local]
the [MWM MCP](#mwm-mcp):

[ligne retirée : mention d'identifiants ou de secret, voir le fichier d'origine en local]
|----------------------------------|-----------------------|
| [identifiant de l'équipe retiré] | [mot de passe retiré, voir le README d'origine en local] |
> Keep these credentials within your team.

## What's inside

| Path                                     | Content                                                                                    |
|------------------------------------------|--------------------------------------------------------------------------------------------|
| `xcode-project/BuildChallenge.xcodeproj` | SwiftUI app: your starting point                                                           |
| `xcode-project/TestConfig.storekit`      | Local StoreKit configuration with your subscriptions                                       |
| `mwm-spark-flash-sdk/`                   | MWM Spark SDK (local Swift package) and its [documentation](mwm-spark-flash-sdk/README.md) |
| `mwm-ai-mcp-plugin-0.30.5.zip`           | MWM MCP plugin for desktop clients (see [MWM MCP](#mwm-mcp))                               |

> [!NOTE]
> **Already have your own Xcode project?** You can add the MWM Spark SDK to it instead: add
> `mwm-spark-flash-sdk/local-spm-repo` as a local Swift package and follow its
> [documentation](mwm-spark-flash-sdk/README.md). Then:
>
> - set the bundle ID to `ai.mwm.build.challenge.team.01`: your subscriptions are tied to it;
> - configure Spark with [your team's keys](#mwm-spark-sdk), sandbox in Debug and production in
    > Release (see `xcode-project/BuildChallenge/BuildChallengeApp.swift`);
> - copy `xcode-project/TestConfig.storekit` and select it in **Edit Scheme ▸ Run ▸ Options ▸
    > StoreKit Configuration**.

## Get started

Requires **Xcode 27** (the app targets iOS 27).

1. Open `xcode-project/BuildChallenge.xcodeproj`.
2. Run the `BuildChallenge` scheme on a simulator.
3. Tap **Send event**: the event shows up in the
   [MWM AI Console](https://console.mwm.ai/sign-in?next=home-redirect), under
   `Product Analytics / Events`.

> Keep the bundle ID `ai.mwm.build.challenge.team.01`: your subscriptions are tied to it.
>
> Keep the folder layout: the project references the SDK by relative path.

## MWM Spark SDK

Spark is already configured in `xcode-project/BuildChallenge/BuildChallengeApp.swift` with your
team's keys (sandbox in Debug, production in Release). Don't call `Spark.configure` again.

**Track an event**

```swift
// Example
Spark.shared.analytics.logEvent(type: "paywall_shown", properties: ["placement": "onboarding"])
```

**Record every purchase**

`try?` keeps a Spark failure (offline…) from failing a purchase the user has paid for.

```swift
let result = try await product.purchase()
try? await Spark.shared.monetization.recordPurchase(result)
```

**Record transactions made outside the app flow** (renewals, purchases from another device…)

Start listening at launch, at the end of `BuildChallengeApp.init()`. `try?` keeps the loop running
when a call fails (offline…).

```swift
Task {
    for await verificationResult in Transaction.updates {
        try? await Spark.shared.monetization.recordTransactions([verificationResult])
    }
}
```

Full API: [mwm-spark-flash-sdk/README.md](mwm-spark-flash-sdk/README.md).

Dashboard: [MWM AI Console](https://console.mwm.ai/sign-in?next=home-redirect).

**Your team's public keys**

| Environment          | Public key       |
|----------------------|------------------|
| Sandbox (Debug)      | `[clé SDK retirée : voir le README d'origine en local]` |
| Production (Release) | `[clé SDK retirée : voir le README d'origine en local]` |

Already set in the project, listed here in case you need them.

## Subscriptions

6 auto-renewable subscriptions are ready in the **Premium Plan** group. Pick the ones that fit your
business model, or [contact us](#contact) if you need others.

| Product ID                                           | Period  | Price (USD) | Free trial |
|------------------------------------------------------|---------|-------------|------------|
| `ai.mwm.build.challenge.team.01.monthly.07.ft.04.99` | 1 month | 4.99        | 1 week     |
| `ai.mwm.build.challenge.team.01.monthly.07.ft.06.99` | 1 month | 6.99        | 1 week     |
| `ai.mwm.build.challenge.team.01.monthly.07.ft.09.99` | 1 month | 9.99        | 1 week     |
| `ai.mwm.build.challenge.team.01.yearly.00.ft.34.99`  | 1 year  | 34.99       | None       |
| `ai.mwm.build.challenge.team.01.yearly.00.ft.49.99`  | 1 year  | 49.99       | None       |
| `ai.mwm.build.challenge.team.01.yearly.00.ft.69.99`  | 1 year  | 69.99       | None       |

Load them with StoreKit 2's `Product.products(for:)`.

When you run from Xcode, purchases go through `TestConfig.storekit`: they are simulated locally and
need no Apple account. To inspect, refund or expire them, use **Debug ▸ StoreKit ▸ Manage
Transactions**.

Once you've picked yours, set their display name and description in App Store Connect.

## MWM MCP

A remote MCP server to plug into your AI client (Claude, ChatGPT, Codex, Cursor…). Authentication
goes through the MWM AI Console, with [your MWM account](#your-mwm-account).

Your agent gets access to MWM's market data and to your App Store Connect account:

| Area                | What your agent can do                                                                                         |
|---------------------|----------------------------------------------------------------------------------------------------------------|
| Market intelligence | Competitors, keywords (demand, difficulty, rankings), top charts history, iOS review themes, observed Meta ads |
| Store listing / ASO | Audit, rewrite, check against store limits, then push to App Store Connect                                     |
| Visuals             | Icons, screenshots generated from your real screens, App Store headers                                         |
| Localization        | Texts and screenshot series adapted to each market                                                             |
| Campaigns           | Custom Product Pages (from keyword opportunity to submission) and In-App Events                                |
| Reviews             | Analysis by version, country and theme, queue of unanswered reviews, developer replies                         |
| Website & legal     | App landing page, privacy policy and terms of service published on stable URLs                                 |

Endpoint: `https://mcp.mwm.ai/mcp`

**Desktop clients** (Claude Desktop, ChatGPT Desktop, Codex app)

Fastest way: **Plugins ▸ Add ▸ Upload**, then pick `mwm-ai-mcp-plugin-0.30.5.zip`. It bundles the MCP
connection and MWM's skills.

Or, in Claude Desktop: **Settings ▸ Connectors ▸ Add custom connector**, paste the endpoint, then
sign in with [your MWM account](#your-mwm-account).

**Claude Code**

```bash
claude mcp add --transport http mwm https://mcp.mwm.ai/mcp
```

Then start `claude` and run the `/mcp` command to authenticate.

**Codex CLI**

```bash
codex mcp add mwm --url https://mcp.mwm.ai/mcp
[ligne retirée : mention d'identifiants ou de secret, voir le fichier d'origine en local]
```

**Other clients** (Cursor…)

Add the endpoint as a remote (HTTP) MCP server, then sign in with
[your MWM account](#your-mwm-account).

## Useful links

### Consoles

- [App Store Connect](https://appstoreconnect.apple.com)
- [MWM AI Console](https://console.mwm.ai/sign-in?next=home-redirect)
- [Apple Developer](https://developer.apple.com/)

### Learn Swift and SwiftUI

- [SwiftUI Pathway](https://developer.apple.com/swiftui/get-started/)
- [SwiftUI tutorials](https://developer.apple.com/tutorials/swiftui)
- [Develop in Swift](https://developer.apple.com/tutorials/develop-in-swift)
- [The Swift Programming Language](https://docs.swift.org/swift-book/)
- [100 Days of SwiftUI](https://www.hackingwithswift.com/100/swiftui) (Hacking with Swift)
- [WWDC videos](https://developer.apple.com/videos/)

### Design

- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [SF Symbols](https://developer.apple.com/sf-symbols/)
- [Apple Design Resources](https://developer.apple.com/design/resources/): iOS UI kits for Figma and
  Sketch

### Subscriptions and paywall

- [Implementing a store in your app using the StoreKit API](https://developer.apple.com/documentation/StoreKit/implementing-a-store-in-your-app-using-the-storekit-api):
  sample code
- [`SubscriptionStoreView`](https://developer.apple.com/documentation/storekit/subscriptionstoreview):
  a ready-made SwiftUI paywall for a subscription group
- [Setting up StoreKit testing in Xcode](https://developer.apple.com/documentation/xcode/setting-up-storekit-testing-in-xcode):
  how `TestConfig.storekit` works
- [Auto-renewable subscriptions](https://developer.apple.com/app-store/subscriptions/): Apple's
  guidance on offers and free trials

### AI

- [Foundation Models](https://developer.apple.com/documentation/foundationmodels): Apple's on-device
[ligne retirée : mention d'identifiants ou de secret, voir le fichier d'origine en local]

### Ship to the App Store

- [TestFlight](https://developer.apple.com/testflight/): share your builds with testers
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [App privacy details](https://developer.apple.com/app-store/app-privacy-details/): required for
  every submission
- [Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications)
