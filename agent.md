# Analog Gate (App Usage Limiter)

## Overview
**Analog Gate** is a Flutter-based mobile application designed to limit social media and generic app usage by introducing intentional friction. Instead of merely blocking an app, Analog Gate interrupts the user with "quests" (such as taking specific photos using ML Kit image labeling or solving math/English problems) when usage thresholds are met. The user must complete these challenges before they can continue using the target application.

## Key Features
*   **Usage Tracking & Monitoring:** Tracks the time spent on specific applications.
*   **Draw-Over-Other-Apps Overlay:** Implements a system-level overlay to interrupt the user when usage limits are exceeded, effectively blocking them from scrolling further.
*   **Interactive Quests:** 
    *   **Photo Quests:** Requires users to take a picture of a specific object (verified via `google_mlkit_image_labeling`).
    *   **Quiz Quests:** Requires users to solve math or English problems to proceed.
*   **Customizable Settings:** Allows users to configure usage thresholds, types of quests, and the frequency of interruptions.

## Tech Stack
*   **Framework:** Flutter
*   **State Management:** Riverpod (`flutter_riverpod`, `riverpod`)
*   **Key Plugins:**
    *   `camera` / `image_picker`: For photo-based quests.
    *   `google_mlkit_image_labeling`: To verify objects in photo quests.
    *   `permission_handler`: For managing necessary system permissions (like overlay and usage access).
    *   `shared_preferences`: For local storage of settings and usage data.
    *   `flutter_animate`: For UI animations.

## Current Focus & Architecture
The project currently focuses on refining the background monitoring system, ensuring the overlay reliably triggers on top of target apps (like social media), and verifying quest completions seamlessly.
