# Future signed iOS build

This is a dormant template. GitHub Actions remains the primary test CI and
continues to produce an unsigned IPA. The template is not named
`codemagic.yaml`, so connecting this repository to Codemagic cannot launch it
without an explicit later setup step.

After the owner joins the Apple Developer Program:

1. Create an App Store Connect app and matching App ID for
   `com.xiaoxiaoming676.studyapp`.
2. In Codemagic, create a Developer Portal integration called
   `study-appstore` using an App Store Connect API key. Store the `.p8` key in
   Codemagic, never in this repository or chat. Codemagic recommends an
   App Manager key. Configure a matching App Store distribution certificate
   and provisioning profile in Codemagic's signing identities.
3. Copy `codemagic.template.yaml` to `codemagic.yaml`, confirm Codemagic's
   Flutter and Xcode versions against the pinned Saber source, and run the
   workflow manually. Inspect the signed IPA and TestFlight processing result.
4. Keep the App Store Connect app record, Apple team, certificates, profiles,
   and release decisions under the owner's account. GitHub Actions tests stay
   the gate before a signed build.

The template uses Codemagic's documented `ios_signing`,
`xcode-project use-profiles`, `flutter build ipa`, and App Store Connect
publishing flow. It has no Apple secret or private signing material.

Documentation: https://docs.codemagic.io/yaml-code-signing/signing-ios/ and
https://docs.codemagic.io/yaml-publishing/app-store-connect/ .
