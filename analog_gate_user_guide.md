# Analog Gate - English User Guide
*A gamified, AI-powered app blocker and screen-time management application.*

---

## 1. Introduction
**Analog Gate** is a unique mobile application designed to curb digital distractions. Instead of simply blocking apps or showing plain timers, Analog Gate acts as an **interactive gatekeeper**. When you reach your screen time limit on restricted apps (such as TikTok, Instagram, or YouTube), the app locks down your access. 

To unlock your screen time, you must complete an **active mission** in the physical world (e.g., take a walk, read a book, find a plant). Your mission completion is photographed and verified in real-time by **Gemini AI**, ensuring you engage with the offline world before returning to your phone.

---

## 2. Onboarding & App Permissions Screen

### Purpose
To request critical Android system permissions necessary for background screen-time tracking and overlay app blocking.

### Layout & Elements
- **Header Section**: Shield icon with the title "App Permissions" and description.
- **Permission Cards**: Five detailed toggles with custom status indicators showing whether they are granted or pending:
  1. **Camera Access**: Required to take verification photographs for active missions.
  2. **Display Over Other Apps (Overlay)**: Required to draw the full-screen blocking overlay when a limit is exceeded.
  3. **Usage Access**: Required to calculate screen-time usage on other installed apps (e.g., YouTube, TikTok).
  4. **Notifications**: Required to send instant alerts when usage limits are breached.
  5. **Battery Optimization Exemption**: Prevents the background tracking service from being put to sleep by the Android operating system.
- **Action Buttons**:
  - `Grant`: Triggers the system permission request or redirects to the appropriate Android Settings page.
  - `All Set! Continue →` (Active when all are granted) or `Skip for Now →` (To configure permissions later in Settings).

---

## 3. Authentication Screens

### Login Screen
- **Purpose**: Allows registered users to securely log in to their profile and sync their progress with the remote database (Supabase).
- **Layout & Elements**:
  - Lock icon and "Welcome Back" greeting.
  - Form Fields: **Email** and **Password** inputs.
  - Buttons: 
    - `Login` button to execute sign-in.
    - `Don't have an account? Sign Up` text button to navigate to registration.

### Register Screen
- **Purpose**: Enables new users to create an account.
- **Layout & Elements**:
  - "Create Account" header with the subtitle "Sign up to get started".
  - Form Fields: **Full Name**, **Email**, **Password**, and **Confirm Password**.
  - Buttons:
    - `Sign Up` button. Completing registration shows a success pop-up and navigates back to the Login Screen.

---

## 4. Home Screen (Main Dashboard)

### Purpose
The primary landing hub of the application, showing current restricted app usage, active streaks, and the selected active mission.

### Layout & Elements
- **Header Bar**:
  - Greeting text (e.g., "Good morning") followed by "Analog Gate".
  - **XP Badge**: Displays total earned XP (e.g., `120 XP`).
  - **Settings Gear Button**: Opens the Profile & Settings screen.
- **Streak Bar**: Displays a visual indicator of consecutive active days and a weekly completion dot grid (Monday to Sunday).
- **Blocked Apps Usage Card**:
  - **Usage Timer**: Nicely formatted timer showing accumulated usage (e.g., `12m 30s`).
  - **Current Limit**: Based on the active mission difficulty (Easy = 10 min, Medium = 20 min, Hard = 30 min).
  - **Progress Bar**: Premium gradient bar (neon violet to pink) representing usage vs. limit. Glows red if the limit is exceeded.
  - **Testing Mode Indicators**: Displays a yellow lightning icon if Testing Mode is active. Also includes a quick `Reset` button to clear time for testing.
  - **Restricted App List**: Displays the packages currently being restricted.
  - **Setup Warning Link**: If no apps are blocked, a warning prompt appears: *"No apps selected to block. Tap here to set up."*
- **Active Gate Mission Card**:
  - Highlights a selected real-world activity to complete.
  - **Difficulty & Reward Tag**: Displays difficulty (e.g., `Easy`) and XP reward (e.g., `+30 XP`).
  - **Mission Details**: Title (e.g., *Take a short walk*), description, and verification photo instructions.
  - Action Buttons:
    - `Complete` button (gradient fill): Opens the Gate Screen to submit verification.
    - `Reroll` button (outline): Alternates the active mission for a different one.

---

## 5. Gate Screen (Mission Verification)

### Purpose
The screen where users fulfill their active mission by submitting photographic proof to Gemini AI for verification.

### Layout & Elements
1. **Prompt View (Initial)**:
   - Displays the mission icon, title, description, and photo prompt requirement.
   - Action Buttons:
     - `Take a photo`: Opens the device camera.
     - `Choose from gallery`: Opens the device photo library.
2. **Verifying View**:
   - Displays the captured photo.
   - Shows a circular progress loader with the message *"Verifying your photo..."* while calling Gemini AI.
3. **Success View (AI Verified)**:
   - Displays the verified photo with a bright green "AI Verified" badge.
   - Giant checkmark icon and congratulatory messages.
   - **XP Earned** and **Difficulty** stats widgets.
   - `Back to Home` button to return to the dashboard.
4. **Failed View (AI Rejected)**:
   - Displays a red failure icon and message explaining why it failed (e.g., *"No sky detected"* or *"Face does not match profile"*).
   - Shows the labels the AI detected (e.g., *"couch, wall, light"*).
   - `Try again` button to restart the photo submission process.

---

## 6. Progress Screen (User Statistics & History)

### Purpose
A gamified statistics tracker showing the user's historical performance, current level progress, and earned achievements.

### Layout & Elements
- **Header**: "Progress" title.
- **Top Stats Cards**:
  - **Total XP Card**: Displays cumulative experience points earned with a bolt icon.
  - **Day Streak Card**: Displays consecutive active days with a fire icon.
- **Weekly Calendar Grid**: A beautiful circular indicator for each day of the week (M, T, W, T, F, S, S) filled with a checkmark if a mission was successfully verified on that day.
- **Level Progress Card**:
  - Shows the user's level title based on XP milestones (e.g., *Seed, Sprout, Sapling, Tree, Forest, Ancient Oak*) along with matching forest icons.
  - Displays a visual level progress bar and dynamic subtext showing remaining XP to rank up (e.g., *"50 XP to next level"*).
- **Completed Today List**:
  - Shows a list of missions completed on the current day, complete with icons, difficulty, and XP rewards.
  - Displays a peaceful empty-state graphic if no missions are completed yet today (*"No missions completed yet today. Go outside and earn your scroll time!"*).
- **Achievements Grid**:
  - A grid of custom badges which are highlighted in color if earned, or faded gray if locked:
    - **First Step**: Complete 1 mission.
    - **Bookworm**: Reach 50 XP.
    - **Week Warrior**: Achieve a 7-day streak.
    - **Century**: Reach 100 XP.
    - **Nature Lover**: Reach 200 XP.
    - **Mindful**: Complete 10 missions.

---

## 7. Manage Blocked Apps Screen

### Purpose
Allows users to specify which applications are restricted and counted towards the screen-time limit.

### Layout & Elements
- **Instructions Banner**: Info box detailing how app blocking works.
- **Popular Distractions List**:
  - A scrollable list of pre-configured popular apps with custom icons (YouTube, TikTok, Instagram, Facebook, X/Twitter, Reddit, Netflix).
  - Tapping an item triggers a checkbox to add or remove it from the restrictions list.
- **Custom App Package Form**:
  - A text input field to manually type in any Android package name (e.g., `com.tencent.ig` for PUBG Mobile).
  - An add button (`+`) to inject custom apps into the restriction list.
- **Custom Blocked Packages List**: Displays manually added custom package names with a trash can delete icon next to each for quick removal.

---

## 8. Profile & Settings Screen

### Purpose
Enables users to manage their personal profile, modify behavior timers, and configure systemic controls.

### Layout & Elements
- **Profile Photo Section**:
  - Interactive circular avatar. Tapping it opens the camera with the front-facing lens active to snap a profile photo/selfie.
  - Subtext: *"This photo is used by AI to verify it is really you doing the missions."*
- **Username Section**: Displays the display name with an edit icon. Tapping it opens an overlay dialogue box to save a new name.
- **App Blocking Controls**:
  - **Manage Blocked Apps**: Quick access tile leading to the Blocked Apps Screen.
  - **Testing Mode (Fast Triggers)**: Toggle switch. When enabled, it shortens the restriction limits to 15–45 seconds, making it easy to test or demonstrate the application's blocking capabilities.
- **System Permissions Card**: Direct link to request system-level permissions.
- **Log Out Button**: Safely terminates the user session and returns the user to the Login screen.

---

## 9. App Blocking Overlay (Limit Reached Alert)

### Purpose
A full-screen, system-level lock screen that draws over other apps to lock the user out when their screen-time limit has expired.

### Layout & Elements
- **Locked Icon**: Large gold padlock.
- **Title Alert**: "Time Limit Reached!"
- **Description**: *"You must complete a mission in Analog Gate to unlock this app again."*
- **Action Buttons**:
  - `Go to Analog Gate`: Programmatically launches the main Analog Gate app so the user can complete a mission, and closes the blocking overlay.
  - `Bypass (Testing Only)`: (Visible only in testing mode) Allows the developer/user to reset the usage timer and close the overlay immediately without doing a mission.
