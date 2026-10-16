# UTM Mart: cleanup, fixes and security rules

Date: 2026-10-08 · Branch: `cleanup/baseline`

Status: committed on `cleanup/baseline` in stages (see section 7). Deployed to Firebase: the Firestore **indexes** and the **Firestore rules**. The **Storage rules are not deployed**: Firebase Storage is not set up on the project yet. The app was run on an Android emulator and a Pixel 6 Pro. The new Firestore rules were tested on the local emulator and are live, but several flows have not been tested on device against them (see section 8).

`flutter analyze`: 312 infos at the start, 118 now. No errors or warnings.

---

## 1. Bug fixes

| Area | Problem | Fix |
|---|---|---|
| Auction bidding (`auction_firestore_service.dart`) | A failed outbid notification made a successful bid look failed. | The notification has its own `try/catch`. |
| `ShopCubit` (`login_form_section.dart`) | It is a GetIt singleton, but `BlocProvider(create:)` closed it on logout, so the next login reused a closed cubit. | Uses `BlocProvider.value`. |
| Screens closed mid-request | `BuildContext`/`setState` used after an `await` with no `mounted` check, in the order, cart, add-item, auction, profile, settings and notification screens. In `auction_detail_view.dart` the `finally { setState }` blocks had no check at all. | Added `mounted` / `context.mounted` guards. |
| Cubits (`login`, `register`, `logout`) | Could emit after being closed. | Added `if (isClosed) return;`. |
| Order screen | Showed raw exception text to the user. | Friendly message; the error is logged. |
| `cart_service.dart` | Every `catch` hid the cause. | Errors are logged; return values unchanged. |
| FCM (`firebase_service.dart`) | Subscriptions were never stored, so repeat `initialize()` stacked listeners. The FCM token was printed. | Subscriptions stored and cancelled first; token no longer printed. |
| Logout | The button only navigated to the login screen; the user stayed signed in to Firebase. | `AuthRepoImpl.logout()` clears the cache and always signs out of Firebase; the button calls `LogoutUsecase` first. |
| Seller dashboard orders (`shop/.../seller_dashboard_view.dart`) | Found on device. The merged orders stream was a single-subscription `StreamController`; reopening the Track Order tab threw `Bad state: Stream has already been listened to`. | Now a broadcast controller that resets its cached data on each listen. Confirmed on the phone after a full hot restart (a hot reload does not re-run `late final` initializers). |
| Cart (`cart_service.dart`) | Found on device. The cart was stored under one key (`cart_items`) in SharedPreferences, so every account on the phone shared one cart. | The key is now `cart_items_<uid>` (`guest` if signed out), read on every call. Carts saved under the old key are ignored (local only, nothing server-side). |
| Cart badge (`cart_counter_widget.dart`) | Found on device. The store-page badge read the count once in `initState`, so it only updated after leaving and re-entering the page. | `CartService` exposes a `ValueNotifier<int> itemCount`, updated on every save/clear. The badge listens to it. |
| Home cart button (`home_app_bar.dart`) | Found on device. It used `CartCounterIcon` with the default count of 0, so it never changed. | Wrapped in a `ValueListenableBuilder` on `CartService.itemCount` and refreshes the count on load. |
| Home grid (`home_view.dart`) | A product card overflowed by 14 px (title two lines + brand + price did not fit). | `childAspectRatio` 0.75 -> 0.56. |
| Auction expiry check | Found in the logs. The 30-second expired-auction query (`status == active`, `endTime < now`, ordered by `endTime`) failed every time with `FAILED_PRECONDITION: requires an index`. | Added the composite index to `firestore.indexes.json` and deployed it. |
| `firebase.json` | Had a stray extra `}` at the end, so the Firebase CLI could not parse it and every deploy failed. | Removed the extra brace. |

## 1b. UI fixes (light and dark mode)

- `THelperFunctions.mutedTextColor(context)` (`helper_functions.dart`) returns `#6C757D` in light mode and `#B0B0B0` in dark mode. `TColors.grey` (`#E0E0E0`) was nearly invisible on white and too close to white titles on dark.
- Used for descriptions, empty states, brand/quantity lines, "Required" labels and "Sold by" text in the store, auction, cart, order confirmation, profile picture, add item, create auction and product card screens.
- Home "Today's Pick" cards were a hardcoded white `Container` with theme (white) text in dark mode. They are now a `Card`, matching the store list.
- The item detail description hardcoded `TColors.dark` (black in dark mode). It now follows the theme.
- Left alone on purpose: the pale-grey greeting label on the purple home header, and decorative pale-grey icons.

## 2. Cleanup

- `dart fix --apply`: unused imports, redundant `.toList()`, missing `@override`, braces.
- About 120 `print()` calls became `debugPrint`.
- 4 `Image.network` calls became `CachedNetworkImage` (cart, order confirmation, both seller dashboards). 5 with custom loading indicators were left alone.
- 31 unreferenced files deleted after checking each by filename across `lib/`, `test/` and `pubspec.yaml`, all tracked in git (recoverable with `git checkout`).
- Dependencies: removed `lottie`, `google_sign_in`, `capped_progress_indicator`. Moved `flutter_native_splash` and `flutter_launcher_icons` to `dev_dependencies`. Declared `bloc`.
- Reverted an automatic `minSdk` change Flutter made in `android/app/build.gradle.kts`. Flutter re-applies it (`minSdk = flutter.minSdkVersion`) whenever the app is run, so check `git diff android/app/build.gradle.kts` before committing after a run.
- `macos/Flutter/GeneratedPluginRegistrant.swift` changed because `google_sign_in` was removed; that is generated output and expected.

## 3. Stock behavior

Stock is reduced only at checkout (`order_service.dart`). The decrements on seller approval (`seller_order_item.dart`) and on customer "received" (`order_list_item.dart`) were removed. Sellers can still edit their own stock up or down.

Orders placed before this change may have reduced stock more than once. Sellers should check their current counts.

## 4. Security rules (`firestore.rules`, `storage.rules`)

Firestore rules are deployed; Storage rules are not (see section 5). The old `firestore.rules` in the repo was shorter than the one that was live, so it was rewritten from the live version plus the code.

**Firestore**

| Collection | Rule |
|---|---|
| `orders` | Read by the customer or a seller of the order only. Update only by those parties and only `status`, `paymentStatus`, `updatedAt`. Create must be `pending`, either as the customer or as an auction order. |
| `store` | Create only with your own `sellerUid`. The owner can edit anything. Anyone else can only lower `itemStock` (needed for checkout). |
| `auctions` | A bid must be higher, before the end time, and touch only `currentBid`, `bids`, `updatedAt`, `status`. Anyone can end an auction after its end time. The seller manages their own. |
| `products`, `categories` | Create/update/delete only by the owner (`vendorId`). |
| `users`, `addresses`, `notifications` | Unchanged in intent. |

**Storage**: removed the catch-all that let any signed-in user read and write everything. Uploads must be images under 5 MB. Updates and deletes under `products/` and `auctions/` are denied. Profile images are writable only by the owner.

**App changes the rules required**
- The seller dashboard no longer streams every order. It merges two filtered queries: `sellerUid == me` and `sellerUids array-contains me`.
- `createOrder` also writes a `sellerUids` list (all sellers in the cart).
- The dashboard filter also checks the top-level `sellerUid`, which makes auction orders visible to sellers.

**Rules testing**: 66 cases run against the local Firestore emulator, all passing. The same tests fail 25 times against the original rules. Storage rules were only checked for syntax.

## 5. Deploy status and what is left

**Done:** `firebase deploy --only firestore:indexes` and `--only firestore:rules`.

**Storage:** `firebase deploy --only firestore:rules,storage` failed because Firebase Storage has not been set up. Set it up in the console (https://console.firebase.google.com/project/utmmart-13927/storage), then run `firebase deploy --only storage`. Until then `storage.rules` in the repo is not live.

Original checklist:

1. Still to test in the app: checkout (stock drops once), seller approve/ship/close, customer "received", ending an expired auction, logout and re-login. Bidding, login, the seller dashboard and the cart were tested (section 8).
2. The `auctions` index is already deployed. If another screen reports a missing index, create it from the link in the error or add it to `firestore.indexes.json`.
3. The Firebase CLI login must be current (`firebase login --reauth`). On this Windows machine PowerShell blocks `firebase.ps1`; use `firebase.cmd` or Command Prompt.
4. Deploy: `firebase deploy --only firestore:rules` (done) and `firebase deploy --only storage` (waiting on Storage setup).
5. After deploying, repeat the bid and seller-dashboard tests: they were run on device against the **old** live rules, so they do not prove the new rules allow those flows. Only the emulator tests (66 cases) cover the new rules.

**Known limits**
- Orders created before this change have no `sellerUids`. A second seller on an old multi-seller cart will not see them.
- The auction end check uses the server clock, so a client with a fast clock may wait a few seconds to close an expired auction.
- Any signed-in user can still create notifications for other users. Fixing that needs a server-side function.
- Any signed-in user can read any user profile (sellers need buyer contact info).

## 6. Not done

- 104 `withOpacity` deprecations, 12 `overridden_fields` in `product_model.dart`, 7 doc-comment warnings, 1 `avoid_types_as_parameter_names`, and 3 `use_build_context_synchronously` that already have a `mounted` check.
- Replacing the stale `test/widget_test.dart` with real tests (`CartService` and `AuctionModel` are good first targets).
- Splitting the 1,954-line `seller_dashboard_view.dart` and isolating its 30-second timer.
- The auction background service is never started, so auctions only end while someone has the dashboard or the auction open.
- Disposing the `TextEditingController`s in `profile_view.dart` and `user_addresses_view.dart`. Disposing right after `showDialog` can crash during the close animation, so this was skipped.
- Firebase major-version upgrades.

- Old carts under the `cart_items` key are left in SharedPreferences, unused.
- `CLAUDE.md` is untracked and was not included in these commits.

## 7. Reviewing or undoing

The work is committed on `cleanup/baseline` in stages, each commit message says what it contains. Files were grouped by area, so a commit can include small unrelated edits that live in the same file.

- Review: `git log --stat cleanup/baseline` or `git show <commit>`.
- Undo one commit: `git revert <commit>`.
- Undo one file: `git checkout <commit>^ -- <path>`.
- The rules commit is separate from the app code, so the rules can be reverted on their own.

## 8. Tested on device

Android emulator (API 36) and Pixel 6 Pro (API 37), `flutter run` via the Dart MCP tools, against the live `utmmart-13927` project with the old rules.

| Flow | Result |
|---|---|
| App start, Firebase init | OK, no runtime errors |
| Login | OK |
| Place a bid | OK, new amount shown on the auction screen |
| Seller dashboard, Track Order | Failed (stream bug), fixed, OK after restart |
| Cart per user, badge updates, product image | OK after the fixes above |
| Light/dark text colors, Today's Pick card, home cart badge | Hot reloaded on the phone; not yet confirmed visually by the user |
| Expired-auction check | Index error stopped repeating after the index finished building |
| Logout and re-login, checkout, seller approve/ship, customer "received", ending an expired auction | **Not tested yet** |
