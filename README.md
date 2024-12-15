# Book Review and Recommendation App 📚✨

This is a feature-rich Flutter application designed to provide a seamless experience for book lovers. The app allows users to discover, review, rate, and manage books, while also offering personalized recommendations based on their preferences and activities.

---

## Presentation

YouTube Link:

---

## Features 🚀

### Core Pages

1. **Splash Page**

   - Animated logo with a 3-second delay before navigating to the login page.
   - Provides a polished first impression and smooth user experience.

2. **Login Page**

   - Firebase Authentication for secure user login.
   - Includes "Forget Password" functionality for account recovery.

3. **Sign-Up Page**

   - Clean bottom sheet UI for collecting user details like email, password, and username.
   - Users can select their preferred book genres for personalized recommendations.

4. **Home Page**

   - Grid-based layout showcasing books with title, author, and cover image.
   - Integrated search bar for easy book discovery.
   - Pagination support to load 20 books at a time with a loading animation.

5. **Book Details Page**

   - Comprehensive book information, including description, ratings, and reviews.
   - Users can leave reviews and rate books.

6. **Library Page**

   - Manage "Read," "Reading," and "Want to Read" book lists.
   - Real-time updates for adding, editing, or removing books.

7. **Profile Page**
   - Display and manage user information like username and preferences.
   - Features for changing passwords and logging out.

---

## Personalized Book Recommendations 📖✨

The app leverages two key strategies for recommendations:

1. **Ratings-Based Recommendations**  
   Books with ratings of 4 stars and above are prioritized, and recommendations are based on the genres of these high-rated books.
2. **Preference-Based Recommendations**  
   Suggestions are tailored to the genres selected by the user during the sign-up process.

---

## Tech Stack 💻

- **Frontend**: Flutter
- **Backend**: Firebase

  - Firestore for storing user data, reviews, and library information.
  - Firebase Authentication for secure user login and sign-up.
  - Firebase Cloud Functions for advanced operations.

- **APIs**:
  - Google Books API: Fetch book data, including metadata like title, author, and cover image.

---

## How to Run the Project 🛠️

1. Clone the repository:
   ```bash
   git clone https://github.com/KaozhiChen/book_review_app
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

---

## Screenshots 📸

![Demo GIF](assets/demo/splash.gif)
![Demo GIF](assets/demo/home.gif)
![Demo GIF](assets/demo/home2.gif)
![Demo GIF](assets/demo/library.gif)
![Demo GIF](assets/demo/profile.gif)
![Demo GIF](assets/demo/sign_up.gif)
![Demo GIF](assets/demo/untitled.gif)
