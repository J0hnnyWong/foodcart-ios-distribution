# Foodcart iOS Distribution

This public repository contains only the iOS test distribution workflow and generated Pages output. The Unity source remains in the private `foodcart` repository.

Create a release with an Ad Hoc signed IPA from the private repository:

```sh
gh release create v0.1.0 Foodcart.ipa --repo J0hnnyWong/foodcart-ios-distribution --title 'Foodcart iOS v0.1.0' --generate-notes
```

The release workflow publishes an HTTPS installation page. Test devices must already be included in the Ad Hoc provisioning profile.
