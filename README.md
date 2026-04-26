# UTM Mart

UTM Mart is a Flutter C2C marketplace application (student/community marketplace model) that combines modern shopping flows with seller tooling and a real-time auction module. The project is built to demonstrate production-minded Android/Flutter engineering practices: layered architecture, predictable state management, Firebase integration, and clean modular feature boundaries.

UTM Mart serves as an integrated marketplace tailored to the UTM campus ecosystem, designed with a focus on community needs such as product discovery, secure communication, trust-building mechanisms, and streamlined, low-friction transactions. The app is engineered for real-world usage within the university, providing a reliable and scalable foundation for peer-to-peer commerce.

## Core Features

- Firebase email/password authentication with onboarding, sign-in/sign-up, password recovery, and profile flows
- Product browsing, search, sorting, wishlist, cart, and order tracking
- Seller-side item creation and management with image upload and inventory metadata
- Real-time auction workflows with bid handling and expiry processing
- FCM-based notifications and in-app notification streams
- Address, location, geocoding, and permission-based device features
- Trust-first transaction model: inspect physically, then confirm purchase with cash on delivery; payment gateway is intentionally out of scope for this use case

## Architecture and Engineering Approach

The project follows a feature-first layered structure aligned with Clean Architecture ideas:

- **Presentation layer** for UI, Cubits, and view state handling
- **Domain layer** for use cases and business contracts
- **Data layer** for repositories, remote/local data sources, and services

State management is handled using `flutter_bloc` with Cubits, while dependency injection is managed using `get_it`.  
The codebase uses repository and use-case abstractions to keep business logic testable and decoupled from framework details.

## Backend and Data

UTM Mart uses Firebase as the primary backend platform for:

- Authentication
- Firestore database
- Storage
- Cloud Messaging
- Analytics

The shopping flow also integrates REST APIs through Dio, demonstrating hybrid backend integration. Local persistence is used where it improves responsiveness, such as cart and session-related data.

## Tech Stack and Libraries

### Framework and Language
`Flutter`, `Dart`
### Architecture and State
`flutter_bloc`, `get_it`, `dartz`, `equatable`
### Backend and Data
`firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `firebase_messaging`, `firebase_analytics`, `dio`, `http`, `shared_preferences`
### UI and Experience
`cached_network_image`, `carousel_slider`, `shimmer`, `lottie`, `smooth_page_indicator`, `flutter_rating_bar`, `readmore`
### Device and Utilities
`image_picker`, `geolocator`, `geocoding`, `permission_handler`, `url_launcher`, `intl`, `logger`, `flutter_dotenv`, `mailer`

## Getting Started

1. Install Flutter SDK and platform toolchains (Android Studio/Xcode as needed).
2. Run `flutter pub get`.
3. Add Firebase config files for your environment.
4. Run `flutter run`.

## Screenshots

Screenshots and GIF demos will be added here.