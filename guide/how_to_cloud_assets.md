# How to Move Assets to the Cloud (OneDrive)

You want to make your app smaller by keeping big files (images/audio) in the cloud and downloading them only when needed. Here is the step-by-step guide.

## 1. OneDrive vs. Others?
**Yes, you can use OneDrive.**
However, standard OneDrive sharing links open a "preview" page. We need a **direct download link** (one that immediately starts the download).
*   **How to get it:**
    1.  Right-click the file in OneDrive website.
    2.  Select **"Embed"**.
    3.  Copy the URL inside the `src="..."` part of the code.
    4.  Change the word `embed` to `download` in that URL.
    *   *Example:* `https://onedrive.live.com/embed?cid=...` becomes `https://onedrive.live.com/download?cid=...`

## 2. One Big Zip vs. Many Small Zips?
**Do NOT zip the whole folder.**
If you zip the whole `assets` folder, the user has to wait for *everything* to download before they can start.

**Do this instead (The "Netflix" Strategy):**
Zip each lesson folder separately.
*   **Why?** When a user is playing "Lesson 1", we can quietly download "Lesson 2" in the background. By the time they finish Lesson 1, Lesson 2 is ready. This makes the app feel instant.

## 3. Your Step-by-Step Plan

### Step A: Prepare the Files (Do this on your computer)
1.  Go to your project folder: `assets/Lessons/`.
2.  Find the folder `Lesson_01_Subjects`.
3.  Right-click that folder and **Zip it**. Name it `lesson_1_subjects.zip`.
4.  Repeat this for `Lesson_02_PartsOfSpeech` -> `lesson_2_parts_of_speech.zip`.
5.  *Tip: You don't have to do all of them today. Start with just these two.*

### Step B: Upload to Cloud
1.  Upload `lesson_1_subjects.zip` and `lesson_2_parts_of_speech.zip` to your OneDrive.
2.  Get the **Direct Download Links** for both (using the "embed" trick above).

### Step C: Update the App (I will do this part)
Once you have the links, you just paste them into the "Manifest" list I created.
*   `lesson_1_subjects` -> "YOUR_ONEDRIVE_LINK_HERE"
*   `lesson_2_parts_of_speech` -> "YOUR_ONEDRIVE_LINK_HERE"

### Step D: Clean Up
Once we confirm it works, you can delete the `assets/Lessons/Lesson_01_Subjects` folder from your project. This is what actually shrinks the app size.

## Summary
1.  **Zip** individual lesson folders.
2.  **Upload** to OneDrive.
3.  **Get Links**.
4.  **Paste Links** in the code.
5.  **Delete** local files.
