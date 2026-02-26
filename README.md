# TaskFlow 🚀

TaskFlow is a modern, high-performance task management application built with Flutter. It features a clean, intuitive UI with support for user authentication, real-time task tracking, and statistical overviews.

## 📱 App Links

- **GitHub Repository:** [https://github.com/yourusername/taskflow](https://github.com/yourusername/taskflow) _(Replace with actual link)_
- **APK Download:** [Download APK](https://github.com/yourusername/taskflow/releases/latest) _(Replace with actual release link)_

## ✨ Features

- **Authentication:** Secure login and registration using JWT tokens.
- **Task Management:** Create, read, update, and delete tasks with ease.
- **Real-time Filtering:** Filter tasks by status (All, To Do, In Progress, Done).
- **Search:** Instant search across all your local and remote tasks.
- **Statistics:** Visual progress tracking via the "Task Overview" dashboard.
- **Dark Mode Support:** Fully responsive theme system.
- **Smooth Animations:** Integrated with `flutter_staggered_animations` for a premium feel.

## 🏗️ Architecture & State Management

### Feature-First Clean Architecture

The project follows a **Feature-First Clean Architecture** pattern. This ensures the codebase is scalable, maintainable, and testable by separating concerns into independent modules.

- **Data Layer:** Handles API calls, local storage (Flutter Secure Storage), and data modeling.
- **Domain Layer:** Contains the business logic and repository interfaces (Failures, Failures cases).
- **Presentation Layer:** Contains UI components, screens, and Riverpod providers.

### Why Riverpod?

We chose **Riverpod** for state management because of its:

1. **Compile-time Safety:** Catches provider errors before the app even runs.
2. **Dependency Injection:** Seamlessly manages dependencies without the complexity of `Provider` or `get_it`.
3. **Performance:** Efficiently rebuilds only the widgets that depend on a specific slice of state.
4. **Testability:** Makes it incredibly easy to mock data and test business logic in isolation.

## 🛠️ Setup Instructions

### Prerequisites

- Flutter SDK (Latest Stable)
- Android Studio / VS Code
- Java Development Kit (JDK) 17+

### Steps to Run

1. **Clone the repository:**

   ```bash
   git clone https://github.com/K-hashmi9065/my-raid-.git
   cd taskflow
   ```

2. **Install dependencies:**

   ```bash
   flutter pub get
   ```

3. **Run the application:**

   ```bash
   flutter run
   ```

4. **Build APK (Release):**
   ```bash
   flutter build apk --release
   ```

## 🌐 API Documentation

This app integrates with the [DummyJSON API](https://dummyjson.com/docs/auth) for demonstration purposes.

### Authentication

- `POST /auth/login`: Authenticates user and returns a JWT token.
- `GET /auth/me`: Fetches the currently authenticated user profile.

### Tasks

- `GET /todos`: Fetches a paginated list of tasks.
- `POST /todos/add`: Creates a new task.
- `PUT /todos/{id}`: Updates an existing task.
- `DELETE /todos/{id}`: Removes a task.

---

Built with ❤️ using Flutter and Riverpod. 🚀
