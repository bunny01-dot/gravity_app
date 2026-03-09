# 🔧 URGENT FIX REQUIRED: Remove Full-Screen Backgrounds from Notice Cards

## ❌ **Problem:**
User reports that notices appearing after login and when tapping Daily Tasks have **full-screen colored backgrounds** (orange, blue) which look bad.

## ✅ **Solution:**
Only the notice CARD should have color. The background should be:
1. **Transparent**, OR  
2. **Centered card with blur effect**

---

## 📍 **Where to Look:**

### **Notices that appear AFTER LOGIN:**
- Likely in: `lib/main.dart`, `lib/dashboard.dart`, or `lib/features/tutorial/onboarding_screen.dart`
- Keywords: "Build Streak", "Welcome", introductory dialogs
- Problem: Orange full-screen background

### **Notices when tapping DAILY TASK:**
- Likely in: Daily task screens, quiz intro screens, or task_intro screens
- Problem: Blue full-screen background

---

## 🛠️ **How to Fix:**

### **Option 1: Find and Remove Scaffold Background**
```dart
// ❌ WRONG - Full screen colored
Scaffold(
  backgroundColor: Colors.orange,  // REMOVE THIS!
  body: NoticeCard()
)

// ✅ CORRECT - Only card colored
Scaffold(
  backgroundColor: Colors.transparent, // Or const Color(0xFF030305)
  body: Center(
    child: Container(
      // Card with color
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.orange, Colors.deepOrange]),
      ),
    ),
  ),
)
```

### **Option 2: Use Dialog Instead of Full Screen**
```dart
// ✅ Use showDialog with transparent barrier
showDialog(
  context: context,
  barrierColor: Colors.black54, // Semi-transparent black
  builder: (context) => Dialog(
    backgroundColor: Colors.transparent,
    child: Container(
      // Colored card here
    ),
  ),
);
```

---

## 🔍 **Search Commands to Find Issues:**

```bash
# Find all Scaffold with colored backgrounds
grep -rn "backgroundColor.*orange" lib/
grep -rn "backgroundColor.*blue" lib/
grep -rn "backgroundColor.*Color(0xFF" lib/screens/

# Find notice/intro screens
find lib/ -name "*notice*.dart"
find lib/ -name "*intro*.dart"  
find lib/ -name "*welcome*.dart"
```

---

## ✏️ **Files to Check:**
1. Any screen shown after login
2. Any screen shown before daily tasks
3. Tutorial/onboarding screens
4. Task intro screens

**STATUS**: Need to identify exact files based on user feedback about WHEN notices appear.
