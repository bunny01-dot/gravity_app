/**
 * Cloud Functions for Gravity App (English Learning App)
 * 
 * ✅ CRITICAL FIX: All FCM messages now use HYBRID PAYLOAD (notification + data)
 * This ensures delivery even when app is terminated on real devices.
 */

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
const fs = require("fs");
const path = require("path");

admin.initializeApp();


/**
 * ✅ OPTIONAL: Lightweight Delivery Logging Helper
 * Logs notification attempts to Firestore for monitoring
 * Non-blocking, fire-and-forget
 */
async function logNotificationDelivery(type, success, details = {}) {
    try {
        await admin.firestore().collection('notification_logs').add({
            type: type,
            success: success,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            ...details,
        });
    } catch (error) {
        // Don't let logging errors break notification flow
        console.error('Logging error (non-critical):', error);
    }
}

const AWARDS_LEADERBOARD_SIZE = 20;
const AWARDS_SCAN_LIMIT = 120;
const AWARDS_TIMEZONE_OFFSET_MINUTES = 330; // Asia/Kolkata (UTC+5:30)

function toSafeInt(value) {
    if (typeof value === "number" && Number.isFinite(value)) {
        return Math.round(value);
    }
    if (typeof value === "string") {
        const parsed = Number.parseInt(value, 10);
        return Number.isFinite(parsed) ? parsed : 0;
    }
    return 0;
}

function getCurrentWeekWindow(now = new Date()) {
    const utcMs = now.getTime() + (now.getTimezoneOffset() * 60000);
    const localMs = utcMs + (AWARDS_TIMEZONE_OFFSET_MINUTES * 60000);
    const localDate = new Date(localMs);

    const dayOfWeek = localDate.getUTCDay(); // 0=Sun ... 6=Sat
    const diffToMonday = (dayOfWeek + 6) % 7;

    const weekStartLocal = new Date(Date.UTC(
        localDate.getUTCFullYear(),
        localDate.getUTCMonth(),
        localDate.getUTCDate(),
    ));
    weekStartLocal.setUTCDate(weekStartLocal.getUTCDate() - diffToMonday);
    weekStartLocal.setUTCHours(0, 0, 0, 0);

    const weekEndLocal = new Date(weekStartLocal.getTime());
    weekEndLocal.setUTCDate(weekEndLocal.getUTCDate() + 6);
    weekEndLocal.setUTCHours(23, 59, 59, 999);

    const weekStartUtc = new Date(
        weekStartLocal.getTime() - (AWARDS_TIMEZONE_OFFSET_MINUTES * 60000),
    );
    const weekEndUtc = new Date(
        weekEndLocal.getTime() - (AWARDS_TIMEZONE_OFFSET_MINUTES * 60000),
    );

    const y = weekStartLocal.getUTCFullYear();
    const m = String(weekStartLocal.getUTCMonth() + 1).padStart(2, "0");
    const d = String(weekStartLocal.getUTCDate()).padStart(2, "0");

    return {
        weekKey: `${y}-${m}-${d}`,
        weekStartUtc,
        weekEndUtc,
    };
}

function medalForRank(rank) {
    if (rank === 1) return "gold";
    if (rank === 2) return "silver";
    if (rank === 3) return "bronze";
    return "";
}

async function buildAwardRankings() {
    const db = admin.firestore();

    const [topXpSnap, recentActiveSnap] = await Promise.all([
        db.collection("users")
            .orderBy("xp", "desc")
            .limit(AWARDS_SCAN_LIMIT)
            .get(),
        db.collection("users")
            .orderBy("lastActive", "desc")
            .limit(AWARDS_SCAN_LIMIT)
            .get(),
    ]);

    const usersById = new Map();
    const mergeUsers = (snapshot) => {
        snapshot.forEach((doc) => {
            if (!usersById.has(doc.id)) {
                usersById.set(doc.id, { uid: doc.id, ...doc.data() });
            }
        });
    };
    mergeUsers(topXpSnap);
    mergeUsers(recentActiveSnap);

    const users = Array.from(usersById.values()).filter((user) => {
        if (user.role === "teacher") return false;
        if (user.isBlocked === true) return false;
        return true;
    });

    if (users.length === 0) return [];

    const progressRefs = users.map((user) =>
        db.collection("users").doc(user.uid).collection("progress").doc("all_data"),
    );
    const progressSnaps = progressRefs.length > 0 ? await db.getAll(...progressRefs) : [];

    const progressByUid = new Map();
    progressSnaps.forEach((snap) => {
        const uid = snap.ref.parent.parent?.id;
        if (!uid) return;
        progressByUid.set(uid, snap.exists ? (snap.data() || {}) : {});
    });

    const ranked = [];
    for (const user of users) {
        const progress = progressByUid.get(user.uid) || {};

        const currentStage = toSafeInt(progress.current_learning_stage);
        const completedStages = currentStage > 1 ? currentStage - 1 : 0;
        const totalXp = toSafeInt(progress.user_total_xp) || toSafeInt(user.xp);
        const streak = Math.max(
            toSafeInt(progress.user_stage_streak),
            toSafeInt(progress.user_streak_days),
            completedStages,
        );
        const activity = streak;
        const score = Number(((activity * 2.0) + (totalXp / 1000.0)).toFixed(3));

        ranked.push({
            uid: user.uid,
            name: user.name || user.displayName || "Student",
            photo_url:
                user.photo_url ||
                user.photoUrl ||
                user.photoURL ||
                user.profile_photo ||
                user.profilePhoto ||
                "",
            score,
            activity,
            current_streak: streak,
            completed_stages: completedStages,
            total_xp: totalXp,
        });
    }

    ranked.sort((a, b) => {
        if (b.score !== a.score) return b.score - a.score;
        if (b.total_xp !== a.total_xp) return b.total_xp - a.total_xp;
        return b.current_streak - a.current_streak;
    });

    const top = ranked.slice(0, AWARDS_LEADERBOARD_SIZE);
    return top.map((entry, index) => {
        const rank = index + 1;
        return {
            ...entry,
            rank,
            medal: medalForRank(rank),
        };
    });
}

async function refreshAwardsLeaderboardInternal() {
    const db = admin.firestore();
    const awardsRef = db.collection("system").doc("awards");

    const [leaderboard, awardsSnap] = await Promise.all([
        buildAwardRankings(),
        awardsRef.get(),
    ]);

    const now = new Date();
    const { weekKey, weekStartUtc, weekEndUtc } = getCurrentWeekWindow(now);
    const existing = awardsSnap.exists ? (awardsSnap.data() || {}) : {};
    const existingWeekKey = (existing.week_key || "").toString();
    const shouldRotate = existingWeekKey !== weekKey;
    const streakWinner = leaderboard.length > 0
        ? [...leaderboard].sort((a, b) => {
            if (b.current_streak !== a.current_streak) {
                return b.current_streak - a.current_streak;
            }
            if (b.total_xp !== a.total_xp) return b.total_xp - a.total_xp;
            return (a.name || "").localeCompare(b.name || "");
        })[0]
        : null;
    const xpWinner = leaderboard.length > 0
        ? [...leaderboard].sort((a, b) => {
            if (b.total_xp !== a.total_xp) return b.total_xp - a.total_xp;
            if (b.current_streak !== a.current_streak) {
                return b.current_streak - a.current_streak;
            }
            return (a.name || "").localeCompare(b.name || "");
        })[0]
        : null;

    const payload = {
        leaderboard_top: leaderboard,
        leaderboard_updated_at: admin.firestore.FieldValue.serverTimestamp(),
        week_key: weekKey,
        week_start: weekStartUtc,
        week_end: weekEndUtc,
        ranking_formula: "score=(streak*2)+(xp/1000), streak=max(user_stage_streak,user_streak_days,completed_stages)",
        streak_winner_uid: streakWinner?.uid || "",
        streak_winner_name: streakWinner?.name || "",
        streak_winner_photo: streakWinner?.photo_url || "",
        streak_winner_streak: streakWinner?.current_streak || 0,
        xp_winner_uid: xpWinner?.uid || "",
        xp_winner_name: xpWinner?.name || "",
        xp_winner_photo: xpWinner?.photo_url || "",
        xp_winner_total_xp: xpWinner?.total_xp || 0,
    };

    if (shouldRotate) {
        const winner = streakWinner;
        if (winner) {
            payload.current_winner_uid = winner.uid;
            payload.current_winner_name = winner.name;
            payload.current_winner_photo =
                winner.photo_url || winner.photoUrl || winner.photoURL || "";
            payload.reason = `Highest level streak (${winner.current_streak || 0})`;
            payload.awarded_at = admin.firestore.FieldValue.serverTimestamp();
        } else {
            payload.current_winner_uid = "";
            payload.current_winner_name = "No eligible student yet";
            payload.current_winner_photo = "";
            payload.reason = "Waiting for streak data";
            payload.awarded_at = admin.firestore.FieldValue.serverTimestamp();
        }
    }

    await awardsRef.set(payload, { merge: true });
    return {
        leaderboardCount: leaderboard.length,
        rotated: shouldRotate,
        weekKey,
    };
}

/**
 * sendAnnouncement
 *
 * ✅ FIXED: Now sends HYBRID payload (notification + data)
 * - notification → guarantees system tray delivery (even when app killed)
 * - data → used when app is foreground for custom handling
 *
 * Parameters:
 *  - topic: String (e.g. "student_announcements")
 *  - title: String
 *  - body: String
 *  - important: Boolean (default: true)
 */
exports.sendAnnouncement = onCall(async (request) => {
    // 1. Auth Check
    if (!request.auth) {
        throw new HttpsError(
            "unauthenticated",
            "The function must be called while authenticated.",
        );
    }

    const { topic, title, body, important } = request.data;
    const uid = request.auth.uid;

    // 2. Role Check
    const userDoc = await admin.firestore().collection("users").doc(uid).get();
    if (!userDoc.exists || userDoc.data().role !== "teacher") {
        throw new HttpsError(
            "permission-denied",
            "Only teachers can send announcements.",
        );
    }

    // 3. Construct HYBRID Message (CRITICAL FIX)
    const androidChannel = important
        ? "announcements_channel_v3"
        : "announcements_channel_normal_v3";

    const message = {
        topic: topic || "student_announcements",
        // ✅ notification field ensures system delivery
        notification: {
            title: title || "New Announcement",
            body: body || "Tap to read",
        },
        // ✅ data field for foreground custom handling
        data: {
            announcement_type: important ? "important" : "normal",
            screen: "announcements",
            click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
            priority: "high", // Always high for announcements
            notification: {
                channelId: androidChannel,
                sound: "default",
                priority: important ? "high" : "default",
            },
        },
    };

    // 4. Send
    try {
        const response = await admin.messaging().send(message);
        console.log("✅ Successfully sent announcement:", response);

        // ✅ Log success (non-blocking)
        logNotificationDelivery('announcement', true, {
            topic: topic || "student_announcements",
            messageId: response,
            sentBy: uid,
            important: important,
        });

        return { success: true, messageId: response };
    } catch (error) {
        console.error("❌ Error sending announcement:", error);

        // ✅ Log failure (non-blocking)
        logNotificationDelivery('announcement', false, {
            topic: topic || "student_announcements",
            error: error.message,
            sentBy: uid,
        });

        throw new HttpsError("internal", "Error sending notification", error);
    }
});

/**
 * dailyStudentReminder
 *
 * DEPRECATED:
 * We no longer send a global 9:00 AM broadcast reminder because reminders
 * are now user-specific via dispatchCustomReminders.
 *
 * Keeping this scheduled function as a no-op avoids accidental duplicate
 * reminders for users who also receive the custom-time notification.
 */
exports.dailyStudentReminder = onSchedule(
    {
        schedule: "0 9 * * *", // 9:00 AM daily (cron format)
        timeZone: "Asia/Kolkata", // Student timezone
    },
    async () => {
        console.log(
            "[dailyStudentReminder] skipped (deprecated; using dispatchCustomReminders only).",
        );
        return;
    }
);

/**
 * dailyBugDigest
 * 
 * ✅ NEW: Daily bug report for teachers at 8 PM
 * Sends detailed summary of all unresolved app errors
 * 
 * Schedule: Every day at 8:00 PM IST (Asia/Kolkata)
 * Purpose: Consolidated error report for nighttime debugging
 */
exports.dailyBugDigest = onSchedule(
    {
        schedule: "0 20 * * *", // 8:00 PM daily (20:00 in 24-hour format)
        timeZone: "Asia/Kolkata", // India timezone
    },
    async (event) => {
        console.log("🐛 Daily Bug Digest triggered at 8:00 PM");

        try {
            // Query all unresolved errors from today and last 7 days
            const sevenDaysAgo = new Date();
            sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

            const errorsSnapshot = await admin.firestore()
                .collection('app_errors')
                .where('resolved', '==', false)
                .where('timestamp', '>=', sevenDaysAgo)
                .orderBy('timestamp', 'desc')
                .limit(50) // Max 50 errors in digest
                .get();

            if (errorsSnapshot.empty) {
                console.log("✅ No unresolved errors to report");

                // Optional: Send "all clear" notification
                const allClearMessage = {
                    topic: "teachers",
                    notification: {
                        title: "✅ Daily Bug Report",
                        body: "No unresolved app errors today. All systems running smoothly!",
                    },
                    data: {
                        type: "bug_digest",
                        errorCount: "0",
                    },
                    android: {
                        priority: "default",
                        notification: {
                            channelId: "announcements_channel_normal_v3",
                        },
                    },
                };

                await admin.messaging().send(allClearMessage);
                return;
            }

            // Group errors by severity and category
            const errorStats = {
                high: [],
                medium: [],
                low: [],
            };

            errorsSnapshot.forEach(doc => {
                const error = doc.data();
                const severity = error.severity || 'medium';

                const errorInfo = {
                    id: doc.id,
                    category: error.category,
                    student: error.studentName,
                    message: error.errorMessage,
                    time: error.timestamp?.toDate()?.toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' }) || 'Unknown',
                };

                if (errorStats[severity]) {
                    errorStats[severity].push(errorInfo);
                }
            });

            const totalErrors = errorsSnapshot.size;
            const highCount = errorStats.high.length;
            const mediumCount = errorStats.medium.length;
            const lowCount = errorStats.low.length;

            // Create detailed message body
            let detailedBody = `📊 Bug Summary (Last 7 Days)\n`;
            detailedBody += `Total: ${totalErrors} unresolved errors\n`;
            detailedBody += `🚨 High: ${highCount} | ⚠️ Medium: ${mediumCount} | 🔧 Low: ${lowCount}\n\n`;

            // Add detailed error list
            if (highCount > 0) {
                detailedBody += `🚨 CRITICAL ERRORS (${highCount}):\n`;
                errorStats.high.slice(0, 5).forEach((err, i) => {
                    detailedBody += `${i + 1}. [${err.category}] ${err.student}\n`;
                    detailedBody += `   ${err.message.substring(0, 80)}...\n`;
                    detailedBody += `   Time: ${err.time}\n`;
                });
                if (highCount > 5) detailedBody += `   ...and ${highCount - 5} more\n`;
                detailedBody += `\n`;
            }

            if (mediumCount > 0) {
                detailedBody += `⚠️ MEDIUM PRIORITY (${mediumCount}):\n`;
                errorStats.medium.slice(0, 3).forEach((err, i) => {
                    detailedBody += `${i + 1}. [${err.category}] ${err.student}\n`;
                    detailedBody += `   ${err.message.substring(0, 60)}...\n`;
                });
                if (mediumCount > 3) detailedBody += `   ...and ${mediumCount - 3} more\n`;
                detailedBody += `\n`;
            }

            if (lowCount > 0) {
                detailedBody += `🔧 LOW PRIORITY (${lowCount}):\n`;
                detailedBody += `UI/Layout issues and minor bugs\n\n`;
            }

            detailedBody += `📝 Full details: Firestore > app_errors collection\n`;
            detailedBody += `✅ Mark errors as resolved after fixing`;

            // Create notification title based on severity
            let title = "🐛 Daily Bug Report";
            if (highCount > 0) {
                title = `🚨 ${highCount} Critical Bug${highCount > 1 ? 's' : ''} Need Attention`;
            } else if (totalErrors > 5) {
                title = `🐛 ${totalErrors} Bugs to Review Tonight`;
            }

            const message = {
                topic: "teachers",
                notification: {
                    title: title,
                    body: `${totalErrors} unresolved errors. 🚨${highCount} critical, ⚠️${mediumCount} medium, 🔧${lowCount} minor. Tap for details.`,
                },
                data: {
                    type: "bug_digest",
                    errorCount: totalErrors.toString(),
                    highSeverity: highCount.toString(),
                    mediumSeverity: mediumCount.toString(),
                    lowSeverity: lowCount.toString(),
                    detailedReport: detailedBody,
                },
                android: {
                    priority: highCount > 0 ? "high" : "default",
                    notification: {
                        channelId: highCount > 0 ? "announcements_channel_v3" : "announcements_channel_normal_v3",
                        sound: "default",
                        style: "bigtext",
                        bigText: detailedBody,
                    },
                },
            };

            const response = await admin.messaging().send(message);
            console.log(`✅ Daily bug digest sent: ${totalErrors} errors reported`);

            // Log the digest send
            logNotificationDelivery('bug_digest', true, {
                messageId: response,
                totalErrors: totalErrors,
                highCount: highCount,
                mediumCount: mediumCount,
                lowCount: lowCount,
            });

        } catch (error) {
            console.error("❌ Error generating bug digest:", error);
            logNotificationDelivery('bug_digest', false, {
                error: error.message,
            });
        }
    }
);

/**
 * refreshStudentOfWeekLeaderboard
 *
 * Cheap ranking architecture:
 * - Runs once daily
 * - Precomputes top ranks and medals
 * - Stores leaderboard in system/awards
 * - Rotates winner only when week changes
 */
exports.refreshStudentOfWeekLeaderboard = onSchedule(
    {
        schedule: "15 0 * * *", // 12:15 AM daily
        timeZone: "Asia/Kolkata",
    },
    async () => {
        try {
            const result = await refreshAwardsLeaderboardInternal();
            console.log(
                `✅ refreshStudentOfWeekLeaderboard: ${result.leaderboardCount} ranked, rotated=${result.rotated}, week=${result.weekKey}`,
            );
        } catch (error) {
            console.error("❌ refreshStudentOfWeekLeaderboard failed:", error);
        }
    },
);

/**
 * refreshStudentOfWeekLeaderboardNow
 *
 * Manual trigger for teachers/admins.
 */
exports.refreshStudentOfWeekLeaderboardNow = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError(
            "unauthenticated",
            "The function must be called while authenticated.",
        );
    }

    const uid = request.auth.uid;
    const userDoc = await admin.firestore().collection("users").doc(uid).get();
    const role = userDoc.exists ? userDoc.data()?.role : null;
    if (role !== "teacher") {
        throw new HttpsError(
            "permission-denied",
            "Only teachers can refresh weekly awards.",
        );
    }

    const result = await refreshAwardsLeaderboardInternal();
    return {
        success: true,
        leaderboardCount: result.leaderboardCount,
        rotated: result.rotated,
        weekKey: result.weekKey,
    };
});

/**
 * notifyTeachersOnFeedback
 * 
 * ✅ FIXED: Now uses HYBRID payload
 */
exports.notifyTeachersOnFeedback = onDocumentCreated("feedback/{docId}", async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
        console.log("No data associated with the event");
        return;
    }
    const data = snapshot.data();

    const message = {
        topic: "teachers",
        // ✅ Hybrid payload
        notification: {
            title: "New Feedback Received",
            body: `${data.userName || 'Student'}: ${data.content?.substring(0, 50) || ''}`,
        },
        data: {
            type: "feedback",
            screen: "feedback_list",
            announcement_type: "normal",
        },
        android: {
            priority: "high",
            notification: {
                channelId: "announcements_channel_normal_v3",
            },
        },
    };

    try {
        await admin.messaging().send(message);
        console.log("✅ Feedback notification sent to teachers");
    } catch (error) {
        console.error("❌ Error sending feedback notification:", error);
    }
});

/**
 * notifyTeachersOnBugReport
 * 
 * ✅ FIXED: Now uses HYBRID payload
 */
exports.notifyTeachersOnBugReport = onDocumentCreated("bug_reports/{docId}", async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;
    const data = snapshot.data();

    const message = {
        topic: "teachers",
        // ✅ Hybrid payload
        notification: {
            title: "🐛 New Bug Report",
            body: `${data.userName || 'Student'}: ${data.content?.substring(0, 50) || ''}`,
        },
        data: {
            type: "bug_report",
            screen: "bug_reports",
            announcement_type: "important",
        },
        android: {
            priority: "high",
            notification: {
                channelId: "announcements_channel_v3",
            },
        },
    };

    try {
        await admin.messaging().send(message);
        console.log("✅ Bug report notification sent to teachers");
    } catch (error) {
        console.error("❌ Error sending bug report notification:", error);
    }
});

/**
 * notifyTeachersOnStudentActivity
 * 
 * ✅ ENHANCED: Validates all required fields before processing
 * Triggered when documents are created in teacher_notifications collection
 * 
 * Notification types:
 * - daily_tasks_completed
 * - level_complete
 * - needs_help
 * - streak_milestone
 */
exports.notifyTeachersOnStudentActivity = onDocumentCreated("teacher_notifications/{docId}", async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
        console.log("No data associated with teacher notification event");
        return;
    }

    const data = snapshot.data();

    // ✅ VALIDATION: Check if all required fields exist and are non-empty
    const studentId = data.studentId?.trim();
    const studentName = data.studentName?.trim();
    const activityType = data.activityType?.trim();
    const details = data.details?.trim();

    // ✅ Enhanced logging for debugging
    console.log("📬 Teacher notification triggered:");
    console.log("  Document ID:", event.params.docId);
    console.log("  Student ID:", studentId || "(missing)");
    console.log("  Student Name:", studentName || "(missing)");
    console.log("  Activity Type:", activityType || "(missing)");
    console.log("  Details:", details || "(missing)");

    // ✅ REJECT if any required field is missing
    if (!studentId) {
        console.error("❌ INVALID_NOTIFICATION_PAYLOAD: studentId missing");
        await logInvalidNotification("studentId", data);
        return; // Do NOT send notification
    }

    if (!studentName) {
        console.error("❌ INVALID_NOTIFICATION_PAYLOAD: studentName missing");
        await logInvalidNotification("studentName", data);
        return; // Do NOT send notification
    }

    if (!activityType) {
        console.error("❌ INVALID_NOTIFICATION_PAYLOAD: activityType missing");
        await logInvalidNotification("activityType", data);
        return; // Do NOT send notification
    }

    if (!details) {
        console.error("❌ INVALID_NOTIFICATION_PAYLOAD: details missing");
        await logInvalidNotification("details", data);
        return; // Do NOT send notification
    }

    // ✅ All validations passed - proceed with notification
    console.log("✅ Valid payload received, processing notification...");

    // Format notification based on activity type
    let title = "📚 Student Activity";
    let body = `${studentName}: ${details}`;
    let isImportant = false;

    switch (activityType) {
        case 'daily_tasks_completed':
            title = "✅ Daily Tasks Completed";
            body = `${studentName} completed all daily tasks!`;
            break;
        case 'level_complete':
            title = "🎉 Level Completed";
            body = `${studentName} completed a new level!`;
            isImportant = true;
            break;
        case 'needs_help':
            title = "🆘 Student Needs Help";
            body = `${studentName}: ${details}`;
            isImportant = true;
            break;
        case 'streak_milestone':
            title = "🔥 Streak Milestone";
            body = `${studentName} ${details}`;
            isImportant = true;
            break;
        case 'feedback_submitted':
            title = "💬 New Feedback";
            body = `${studentName} submitted feedback`;
            break;
        case 'new_student_signup':
            title = "👋 New Student Joined";
            body = `${studentName} just signed up!`;
            isImportant = true;
            break;
        case 'app_error':
            // ✅ ENHANCED: Parse abstracted error format (category|severity)
            const parts = details.split('|');
            const errorCategory = parts[0] || 'Technical Issue';
            const severity = parts[1] || 'medium';

            // ✅ Professional, teacher-friendly messaging
            title = "⚠️ App Issue Detected";

            // Different messages based on severity
            if (severity === 'low') {
                title = "🔧 Minor App Issue";
                body = `A ${errorCategory.toLowerCase()} was detected in ${studentName}'s app and automatically logged for review.`;
                isImportant = false;
            } else if (severity === 'high') {
                title = "🚨 Critical App Issue";
                body = `A ${errorCategory.toLowerCase()} occurred in ${studentName}'s app. Development team has been notified.`;
                isImportant = true;
            } else {
                title = "⚠️ App Issue Detected";
                body = `A ${errorCategory.toLowerCase()} was reported from ${studentName}'s app and logged for review.`;
                isImportant = false;
            }

            console.log(`🐛 App Error: [${severity}] ${errorCategory} from ${studentName}`);
            break;
        default:
            title = "📚 Student Activity";
            body = `${studentName} performed activity (${activityType}): ${details}`;
            console.warn(`⚠️ Unknown activityType: ${activityType}`);
    }

    const channelId = isImportant
        ? "announcements_channel_v3"
        : "announcements_channel_normal_v3";

    const message = {
        topic: "teachers",
        // ✅ Hybrid payload for reliable delivery
        notification: {
            title: title,
            body: body.substring(0, 200), // Limit body length
        },
        data: {
            type: "student_activity",
            activityType: activityType,
            studentId: studentId,
            studentName: studentName,
            screen: "teacher_dashboard",
            announcement_type: isImportant ? "important" : "normal",
        },
        android: {
            priority: "high",
            notification: {
                channelId: channelId,
                sound: "default",
                priority: isImportant ? "high" : "default",
            },
        },
    };

    try {
        const response = await admin.messaging().send(message);
        console.log(`✅ Teacher notification sent: ${activityType} from ${studentName}`);

        // ✅ Log success (non-blocking)
        logNotificationDelivery('teacher_activity', true, {
            messageId: response,
            activityType: activityType,
            studentId: studentId,
            studentName: studentName,
        });
    } catch (error) {
        console.error("❌ Error sending teacher notification:", error);

        // ✅ Log failure (non-blocking)
        logNotificationDelivery('teacher_activity', false, {
            error: error.message,
            activityType: activityType,
            studentId: studentId,
        });
    }
});

/**
 * ✅ NEW: Logs invalid notification attempts
 */
async function logInvalidNotification(missingField, data) {
    try {
        await admin.firestore().collection('notification_errors').add({
            error_type: 'INVALID_NOTIFICATION_PAYLOAD',
            missing_field: missingField,
            received_data: {
                studentId: data.studentId || '(missing)',
                studentName: data.studentName || '(missing)',
                activityType: data.activityType || '(missing)',
                details: data.details || '(missing)',
            },
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            severity: 'medium',
        });
        console.log(`📝 Logged invalid notification payload (missing: ${missingField})`);
    } catch (error) {
        console.error('Error logging invalid notification:', error);
    }
}


/**
 * sendIndividualNotification
 *
 * ✅ NEW: Send targeted notification to a specific user via FCM Token
 * Required for "Offline" delivery (waking up killed apps)
 * 
 * Parameters:
 *  - targetUserId: String (UID of student)
 *  - title: String
 *  - body: String
 *  - data: Object (optional custom data)
 */
exports.sendIndividualNotification = onCall(async (request) => {
    // 1. Auth Check
    if (!request.auth) {
        throw new HttpsError(
            "unauthenticated",
            "The function must be called while authenticated.",
        );
    }

    const { targetUserId, title, body, data } = request.data;
    const callerUid = request.auth.uid;

    if (!targetUserId || !title || !body) {
        throw new HttpsError(
            "invalid-argument",
            "Missing required fields: targetUserId, title, or body.",
        );
    }

    // 2. Role Check (Caller must be Teacher)
    const callerDoc = await admin.firestore().collection("users").doc(callerUid).get();
    if (!callerDoc.exists || callerDoc.data().role !== "teacher") {
        throw new HttpsError(
            "permission-denied",
            "Only teachers can send individual notifications.",
        );
    }

    // 3. Get Target User's FCM Token
    // Primary path: users/{uid}/private/device.fcmToken
    // Legacy fallback: users/{uid}.fcmToken
    const userRef = admin.firestore().collection("users").doc(targetUserId);
    const targetUserDoc = await userRef.get();
    if (!targetUserDoc.exists) {
        throw new HttpsError("not-found", "Target user not found.");
    }

    let fcmToken = targetUserDoc.data().fcmToken;
    if (!fcmToken) {
        const privateTokenDoc = await userRef.collection("private").doc("device").get();
        if (privateTokenDoc.exists) {
            fcmToken = privateTokenDoc.data().fcmToken;
        }
    }
    if (!fcmToken) {
        console.warn(`⚠️ Target user ${targetUserId} has no FCM token. Notification skipped.`);
        // We return success to not crash the UI, but log the issue.
        return { success: false, reason: "no_token" };
    }

    // 4. Construct Message
    const message = {
        token: fcmToken,
        notification: {
            title: title,
            body: body,
        },
        data: {
            // Merge provided data and ensure defaults
            click_action: "FLUTTER_NOTIFICATION_CLICK",
            screen: "home",
            ...data
        },
        android: {
            priority: "high",
            notification: {
                channelId: "announcements_channel_v3", // High priority channel
                sound: "default",
                priority: "high",
            },
        },
    };

    // 5. Send
    try {
        const response = await admin.messaging().send(message);
        console.log(`✅ Individual notification sent to ${targetUserId}:`, response);

        // Log it
        logNotificationDelivery('individual_message', true, {
            recipientId: targetUserId,
            senderId: callerUid,
            messageId: response
        });

        return { success: true, messageId: response };
    } catch (error) {
        console.error("❌ Error sending individual notification:", error);
        logNotificationDelivery('individual_message', false, {
            recipientId: targetUserId,
            senderId: callerUid,
            error: error.message
        });

        // If token is invalid, delete it from both private and legacy paths.
        if (error.code === 'messaging/registration-token-not-registered') {
            await userRef.collection("private").doc("device").set({
                fcmToken: admin.firestore.FieldValue.delete(),
                lastTokenUpdate: admin.firestore.FieldValue.delete(),
            }, { merge: true });
            await userRef.set({
                fcmToken: admin.firestore.FieldValue.delete(),
                lastTokenUpdate: admin.firestore.FieldValue.delete(),
            }, { merge: true });
            console.log("Deleted invalid FCM token for user");
        }

        throw new HttpsError("internal", "Error sending notification", error);
    }
});

/**
 * ---------------------------------------------------------
 * WORD DUEL (Phase 1) — Multiplayer (Server-Side)
 * ---------------------------------------------------------
 * ✅ Invite-only, same-level only
 * ✅ Questions generated on server from shared learned words
 * ✅ Turn-based answers validated server-side
 * ✅ No client-side question generation
 */

const WORD_DUEL_MIN_COMMON = 10;
const WORD_DUEL_QUESTION_COUNT = 10;
const WORD_DUEL_OPTION_COUNT = 4;

const wordDuelDataCache = {
    beginner: null,
    intermediate: null,
    advanced: null,
    antonyms: null,
};

function loadJson(relativePath) {
    const filePath = path.join(__dirname, relativePath);
    const raw = fs.readFileSync(filePath, "utf8");
    return JSON.parse(raw);
}

function normalizeWord(word) {
    if (!word) return "";
    return word.toString().trim().toLowerCase();
}

function mapPlacementCode(code) {
    const normalized = (code || "").toString().trim().toUpperCase();
    if (normalized === "A" || normalized.includes("ADVANCED")) {
        return { key: "advanced", label: "advanced" };
    }
    if (normalized === "B" || normalized.includes("INTERMEDIATE")) {
        return { key: "intermediate", label: "intermediate" };
    }
    if (normalized === "C" || normalized.includes("BEGINNER")) {
        return { key: "beginner", label: "beginner" };
    }
    return null;
}

function loadVocab(levelKey) {
    if (!wordDuelDataCache[levelKey]) {
        const fileName = `data/vocab_${levelKey}.json`;
        const items = loadJson(fileName);
        const map = new Map();
        for (const item of items) {
            const key = normalizeWord(item.word);
            if (!key) continue;
            map.set(key, item);
        }
        wordDuelDataCache[levelKey] = { items, map };
    }
    return wordDuelDataCache[levelKey];
}

function loadAntonyms() {
    if (!wordDuelDataCache.antonyms) {
        const pairs = loadJson("data/antonyms.json");
        const map = new Map();
        for (const pair of pairs) {
            const key = normalizeWord(pair.word);
            const val = normalizeWord(pair.antonym);
            if (!key || !val) continue;
            if (!map.has(key)) map.set(key, val);
        }
        wordDuelDataCache.antonyms = map;
    }
    return wordDuelDataCache.antonyms;
}

function shuffle(array) {
    for (let i = array.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [array[i], array[j]] = [array[j], array[i]];
    }
    return array;
}

function escapeRegExp(text) {
    return text.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function getTranslation(item, language) {
    if (!item) return "";
    if (language === "Hindi") {
        return (item.hindi || item.tamil || "").trim();
    }
    return (item.tamil || item.hindi || "").trim();
}

function buildMeaningQuestion(wordKey, vocabMap, poolKeys, language) {
    const item = vocabMap.get(wordKey);
    const answer = getTranslation(item, language);
    if (!answer) return null;

    const distractors = [];
    const candidates = shuffle(poolKeys.filter((key) => key !== wordKey));
    for (const key of candidates) {
        const other = vocabMap.get(key);
        const translation = getTranslation(other, language);
        if (!translation || translation === answer) continue;
        if (!distractors.includes(translation)) {
            distractors.push(translation);
        }
        if (distractors.length === WORD_DUEL_OPTION_COUNT - 1) break;
    }

    if (distractors.length < WORD_DUEL_OPTION_COUNT - 1) return null;

    const options = shuffle([answer, ...distractors]);
    return {
        type: "meaning",
        word: item.word,
        prompt: `Select the meaning of "${item.word}".`,
        options,
        answer,
    };
}

function buildFillBlankQuestion(wordKey, vocabMap, poolKeys) {
    const item = vocabMap.get(wordKey);
    if (!item || !item.example) return null;

    const pattern = new RegExp(`\\b${escapeRegExp(item.word)}\\b`, "i");
    if (!pattern.test(item.example)) return null;

    const sentence = item.example.replace(pattern, "____");
    const distractors = [];
    const candidates = shuffle(poolKeys.filter((key) => key !== wordKey));
    for (const key of candidates) {
        const other = vocabMap.get(key);
        if (!other || !other.word) continue;
        if (!distractors.includes(other.word)) {
            distractors.push(other.word);
        }
        if (distractors.length === WORD_DUEL_OPTION_COUNT - 1) break;
    }

    if (distractors.length < WORD_DUEL_OPTION_COUNT - 1) return null;

    const options = shuffle([item.word, ...distractors]);
    return {
        type: "fill_blank",
        word: item.word,
        sentence,
        options,
        answer: item.word,
    };
}

function buildAntonymQuestion(wordKey, vocabMap, poolKeys, antonymMap) {
    const antonymKey = antonymMap.get(wordKey);
    if (!antonymKey) return null;
    if (!vocabMap.has(antonymKey)) return null;

    const item = vocabMap.get(wordKey);
    const antonymItem = vocabMap.get(antonymKey);
    if (!item || !antonymItem) return null;

    const distractors = [];
    const candidates = shuffle(
        poolKeys.filter((key) => key !== wordKey && key !== antonymKey),
    );
    for (const key of candidates) {
        const other = vocabMap.get(key);
        if (!other || !other.word) continue;
        if (!distractors.includes(other.word)) {
            distractors.push(other.word);
        }
        if (distractors.length === WORD_DUEL_OPTION_COUNT - 1) break;
    }

    if (distractors.length < WORD_DUEL_OPTION_COUNT - 1) return null;

    const answer = antonymItem.word;
    const options = shuffle([answer, ...distractors]);
    return {
        type: "antonym",
        word: item.word,
        prompt: `Choose the opposite of "${item.word}".`,
        options,
        answer,
    };
}

function buildWordDuelQuestions({
    sharedKeys,
    vocabMap,
    language,
    antonymMap,
}) {
    const poolKeys = sharedKeys.slice();
    shuffle(poolKeys);

    const used = new Set();
    const questions = [];

    const meaningCandidates = poolKeys.filter((key) => {
        const item = vocabMap.get(key);
        return !!getTranslation(item, language);
    });

    const fillCandidates = poolKeys.filter((key) => {
        const item = vocabMap.get(key);
        if (!item || !item.example) return false;
        const pattern = new RegExp(`\\b${escapeRegExp(item.word)}\\b`, "i");
        return pattern.test(item.example);
    });

    const antonymCandidates = poolKeys.filter((key) => {
        const antonymKey = antonymMap.get(key);
        return !!antonymKey && vocabMap.has(antonymKey);
    });

    const plans = [
        { list: meaningCandidates, count: 4, builder: "meaning" },
        { list: fillCandidates, count: 3, builder: "fill" },
        { list: antonymCandidates, count: 3, builder: "antonym" },
    ];

    const addQuestion = (builder, key) => {
        let question = null;
        if (builder === "meaning") {
            question = buildMeaningQuestion(key, vocabMap, poolKeys, language);
        } else if (builder === "fill") {
            question = buildFillBlankQuestion(key, vocabMap, poolKeys);
        } else if (builder === "antonym") {
            question = buildAntonymQuestion(key, vocabMap, poolKeys, antonymMap);
        }
        if (question) {
            used.add(key);
            questions.push(question);
        }
    };

    for (const plan of plans) {
        const candidates = shuffle(plan.list.slice());
        let added = 0;
        for (const key of candidates) {
            if (questions.length >= WORD_DUEL_QUESTION_COUNT) break;
            if (added >= plan.count) break;
            if (used.has(key)) continue;
            const before = questions.length;
            addQuestion(plan.builder, key);
            if (questions.length > before) {
                added += 1;
            }
        }
    }

    // Fill remaining slots with any available type
    const fallbackOrder = [
        { list: meaningCandidates, builder: "meaning" },
        { list: fillCandidates, builder: "fill" },
        { list: antonymCandidates, builder: "antonym" },
    ];

    for (const fallback of fallbackOrder) {
        const candidates = shuffle(fallback.list.slice());
        for (const key of candidates) {
            if (questions.length >= WORD_DUEL_QUESTION_COUNT) break;
            if (used.has(key)) continue;
            addQuestion(fallback.builder, key);
        }
    }

    if (questions.length < WORD_DUEL_QUESTION_COUNT) {
        return [];
    }

    // Add stable IDs
    return questions.slice(0, WORD_DUEL_QUESTION_COUNT).map((q, index) => ({
        id: `q${index + 1}`,
        ...q,
    }));
}

async function getLearnedWords(uid) {
    const userRef = admin.firestore().collection("users").doc(uid);
    const userSnap = await userRef.get();
    let learned = [];
    if (userSnap.exists) {
        const data = userSnap.data() || {};
        if (Array.isArray(data.learned_vocab_ids)) {
            learned = data.learned_vocab_ids;
        }
    }

    if (!learned || learned.length === 0) {
        const progressSnap = await userRef
            .collection("progress")
            .doc("all_data")
            .get();
        if (progressSnap.exists) {
            const progress = progressSnap.data() || {};
            const cloud = progress.learned_vocab_ids;
            if (Array.isArray(cloud)) {
                learned = cloud;
            } else if (typeof cloud === "string") {
                learned = cloud.split(",").map((w) => w.trim()).filter(Boolean);
            }
        }
    }

    return new Set(learned.map(normalizeWord).filter(Boolean));
}

async function getPreferredLanguage(uid) {
    const progressSnap = await admin.firestore()
        .collection("users")
        .doc(uid)
        .collection("progress")
        .doc("all_data")
        .get();

    if (!progressSnap.exists) return "Tamil";
    const data = progressSnap.data() || {};
    const language = (data.preferred_language || "").toString().trim();
    return language || "Tamil";
}

exports.createWordDuelMatch = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError(
            "unauthenticated",
            "The function must be called while authenticated.",
        );
    }

    const opponentId = request.data?.opponentId;
    const uid = request.auth.uid;

    if (!opponentId || typeof opponentId !== "string") {
        throw new HttpsError("invalid-argument", "Missing opponentId.");
    }

    if (opponentId === uid) {
        throw new HttpsError("invalid-argument", "Cannot invite yourself.");
    }

    const db = admin.firestore();
    const userRef = db.collection("users").doc(uid);
    const opponentRef = db.collection("users").doc(opponentId);

    const [userSnap, opponentSnap] = await Promise.all([
        userRef.get(),
        opponentRef.get(),
    ]);

    if (!userSnap.exists || !opponentSnap.exists) {
        throw new HttpsError("not-found", "Opponent not found.");
    }

    const userData = userSnap.data() || {};
    const opponentData = opponentSnap.data() || {};

    const userLevel = mapPlacementCode(userData.placement_level_code);
    const opponentLevel = mapPlacementCode(opponentData.placement_level_code);

    if (!userLevel || !opponentLevel || userLevel.key !== opponentLevel.key) {
        throw new HttpsError(
            "failed-precondition",
            "You can play Word Duel only with students at the same level.",
        );
    }

    const [userLearned, opponentLearned] = await Promise.all([
        getLearnedWords(uid),
        getLearnedWords(opponentId),
    ]);

    const vocabData = loadVocab(userLevel.key);
    const vocabMap = vocabData.map;

    const sharedKeys = [];
    for (const word of userLearned) {
        if (opponentLearned.has(word) && vocabMap.has(word)) {
            sharedKeys.push(word);
        }
    }

    if (sharedKeys.length < WORD_DUEL_MIN_COMMON) {
        throw new HttpsError(
            "failed-precondition",
            "You need more common learned words to play together.",
        );
    }

    const language = await getPreferredLanguage(uid);

    const matchRef = db.collection("matches").doc();
    await matchRef.set({
        type: "word_duel",
        level: userLevel.key,
        status: "waiting",
        createdBy: uid,
        players: [uid, opponentId],
        accepted: {
            [uid]: true,
            [opponentId]: false,
        },
        questions: [],
        currentTurn: uid,
        currentQuestionIndex: 0,
        answers: {
            [uid]: [],
            [opponentId]: [],
        },
        scores: {
            [uid]: 0,
            [opponentId]: 0,
        },
        language,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        completedAt: null,
    });

    return { success: true, matchId: matchRef.id };
});

exports.respondToWordDuelInvite = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError(
            "unauthenticated",
            "The function must be called while authenticated.",
        );
    }

    const matchId = request.data?.matchId;
    const accept = request.data?.accept === true;
    const uid = request.auth.uid;

    if (!matchId || typeof matchId !== "string") {
        throw new HttpsError("invalid-argument", "Missing matchId.");
    }

    const db = admin.firestore();
    const matchRef = db.collection("matches").doc(matchId);
    const matchSnap = await matchRef.get();

    if (!matchSnap.exists) {
        throw new HttpsError("not-found", "Match not found.");
    }

    const match = matchSnap.data() || {};

    if (match.type !== "word_duel") {
        throw new HttpsError("failed-precondition", "Invalid match type.");
    }

    if (!Array.isArray(match.players) || !match.players.includes(uid)) {
        throw new HttpsError("permission-denied", "Not a match player.");
    }

    if (match.status !== "waiting") {
        return { success: true, status: match.status };
    }

    if (!accept) {
        await matchRef.delete();
        return { success: true, deleted: true };
    }

    const opponentId = match.players.find((p) => p !== uid);
    const accepted = match.accepted || {};
    accepted[uid] = true;

    let updates = { accepted };

    const shouldStart = accepted[opponentId] === true &&
        (!Array.isArray(match.questions) || match.questions.length === 0);

    if (shouldStart) {
        const levelKey = match.level || mapPlacementCode(match.level)?.key || "beginner";
        const vocabData = loadVocab(levelKey);
        const vocabMap = vocabData.map;
        const antonymMap = loadAntonyms();

        const [userLearned, opponentLearned] = await Promise.all([
            getLearnedWords(uid),
            getLearnedWords(opponentId),
        ]);

        const sharedKeys = [];
        for (const word of userLearned) {
            if (opponentLearned.has(word) && vocabMap.has(word)) {
                sharedKeys.push(word);
            }
        }

        if (sharedKeys.length < WORD_DUEL_MIN_COMMON) {
            throw new HttpsError(
                "failed-precondition",
                "You need more common learned words to play together.",
            );
        }

        const language = match.language || await getPreferredLanguage(match.createdBy || uid);
        const questions = buildWordDuelQuestions({
            sharedKeys,
            vocabMap,
            language,
            antonymMap,
        });

        if (!questions || questions.length === 0) {
            throw new HttpsError(
                "failed-precondition",
                "Not enough shared learned words to build a match.",
            );
        }

        const startingPlayer = Math.random() < 0.5 ? match.players[0] : match.players[1];

        updates = {
            ...updates,
            status: "active",
            questions,
            currentQuestionIndex: 0,
            currentTurn: startingPlayer,
        };
    }

    await matchRef.update(updates);
    return { success: true, status: updates.status || "waiting" };
});

exports.submitWordDuelAnswer = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError(
            "unauthenticated",
            "The function must be called while authenticated.",
        );
    }

    const matchId = request.data?.matchId;
    const answer = request.data?.answer;
    const uid = request.auth.uid;

    if (!matchId || typeof matchId !== "string") {
        throw new HttpsError("invalid-argument", "Missing matchId.");
    }

    if (typeof answer !== "string" || answer.trim().length === 0) {
        throw new HttpsError("invalid-argument", "Missing answer.");
    }

    const db = admin.firestore();
    const matchRef = db.collection("matches").doc(matchId);

    await db.runTransaction(async (tx) => {
        const matchSnap = await tx.get(matchRef);
        if (!matchSnap.exists) {
            throw new HttpsError("not-found", "Match not found.");
        }

        const match = matchSnap.data() || {};
        if (match.type !== "word_duel") {
            throw new HttpsError("failed-precondition", "Invalid match type.");
        }

        if (!Array.isArray(match.players) || !match.players.includes(uid)) {
            throw new HttpsError("permission-denied", "Not a match player.");
        }

        if (match.status !== "active") {
            throw new HttpsError("failed-precondition", "Match is not active.");
        }

        if (match.currentTurn !== uid) {
            throw new HttpsError("failed-precondition", "It is not your turn.");
        }

        const questions = Array.isArray(match.questions) ? match.questions : [];
        const index = match.currentQuestionIndex || 0;
        const question = questions[index];
        if (!question) {
            throw new HttpsError("failed-precondition", "Question not found.");
        }

        const answers = match.answers || {};
        const playerAnswers = Array.isArray(answers[uid]) ? answers[uid] : [];
        if (playerAnswers.length > index) {
            throw new HttpsError("failed-precondition", "Already answered.");
        }

        const normalizedAnswer = answer.trim().toLowerCase();
        const normalizedCorrect = (question.answer || "").toString().trim().toLowerCase();
        const isCorrect = normalizedAnswer === normalizedCorrect;

        playerAnswers.push({
            questionId: question.id || `q${index + 1}`,
            answer: answer.trim(),
            correct: isCorrect,
            answeredAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        answers[uid] = playerAnswers;

        const scores = match.scores || {};
        const currentScore = Number(scores[uid] || 0);
        scores[uid] = isCorrect ? currentScore + 1 : currentScore;

        const opponentId = match.players.find((p) => p !== uid);
        const opponentAnswers = Array.isArray(answers[opponentId]) ? answers[opponentId] : [];

        let currentTurn = opponentId;
        let currentQuestionIndex = index;
        let status = match.status;
        let completedAt = match.completedAt || null;

        if (opponentAnswers.length > index) {
            // Both players answered, move to next question
            currentQuestionIndex = index + 1;
            if (currentQuestionIndex >= questions.length) {
                status = "completed";
                currentTurn = null;
                completedAt = admin.firestore.FieldValue.serverTimestamp();
            } else {
                currentTurn = opponentId;
            }
        } else {
            // Waiting for opponent
            currentTurn = opponentId;
        }

        tx.update(matchRef, {
            answers,
            scores,
            currentTurn,
            currentQuestionIndex,
            status,
            completedAt,
        });
    });

    return { success: true };
});

/**
 * updateReminderTime
 *
 * Called by the Flutter app when the user sets or changes their daily reminder time.
 * Stores the reminder preferences in users/{uid}/private/reminder so that the
 * dispatchCustomReminders scheduler can look it up.
 *
 * Parameters (from Flutter):
 *  - hour: int (0–23)  — local hour chosen by the user
 *  - minute: int (0–59) — local minute chosen by the user
 *  - timezoneOffsetMinutes: int — UTC offset of the device (e.g. 330 for IST UTC+5:30)
 *  - enabled: bool — whether reminders are active for this user
 */
exports.updateReminderTime = onCall(
    {
        region: "us-central1",
    },
    async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "Must be authenticated.");
    }

    const uid = request.auth.uid;
    const { hour, minute, timezoneOffsetMinutes, enabled } = request.data;

    // Validate
    if (
        typeof hour !== "number" || hour < 0 || hour > 23 ||
        typeof minute !== "number" || minute < 0 || minute > 59
    ) {
        throw new HttpsError("invalid-argument", "Invalid hour or minute.");
    }

    const reminderRef = admin.firestore()
        .collection("users").doc(uid)
        .collection("private").doc("reminder");

    const normalizedOffset = normalizeTimezoneOffsetMinutes(
        timezoneOffsetMinutes,
        330,
    );
    const reminderEnabled = enabled !== false;

    await reminderRef.set({
        reminder_hour: hour,
        reminder_minute: minute,
        hour: hour, // legacy compatibility
        minute: minute, // legacy compatibility
        timezone_offset_minutes: normalizedOffset,
        timezoneOffsetMinutes: normalizedOffset, // legacy compatibility
        reminder_enabled: reminderEnabled,
        enabled: reminderEnabled, // legacy compatibility
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    console.log(
        `[updateReminderTime] uid=${uid} hour=${hour} minute=${minute} offset=${normalizedOffset} enabled=${reminderEnabled}`,
    );
    return { success: true };
},
);

const REMINDER_WINDOW_MINUTES = 5;
const MAX_TIMEZONE_OFFSET_MINUTES = 14 * 60; // UTC-12 to UTC+14 safety

function parseNumber(value) {
    if (typeof value === "number" && Number.isFinite(value)) {
        return value;
    }
    if (typeof value === "string" && value.trim() !== "") {
        const parsed = Number(value);
        if (Number.isFinite(parsed)) return parsed;
    }
    return null;
}

function normalizeTimezoneOffsetMinutes(value, fallback = 330) {
    const parsed = parseNumber(value);
    if (parsed === null) return fallback;

    const rounded = Math.trunc(parsed);
    if (
        rounded < -MAX_TIMEZONE_OFFSET_MINUTES ||
        rounded > MAX_TIMEZONE_OFFSET_MINUTES
    ) {
        return fallback;
    }
    return rounded;
}

function parseReminderTime(reminder) {
    const hourRaw = parseNumber(reminder?.reminder_hour ?? reminder?.hour);
    const minuteRaw = parseNumber(reminder?.reminder_minute ?? reminder?.minute);
    if (hourRaw === null || minuteRaw === null) return null;

    const hour = Math.trunc(hourRaw);
    const minute = Math.trunc(minuteRaw);
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return { hour, minute };
}

function parseReminderMinutesOfDay(value) {
    const totalMinutesRaw = parseNumber(value);
    if (totalMinutesRaw === null) return null;

    const totalMinutes = Math.trunc(totalMinutesRaw);
    if (totalMinutes < 0 || totalMinutes > ((24 * 60) - 1)) return null;

    return {
        hour: Math.floor(totalMinutes / 60),
        minute: totalMinutes % 60,
    };
}

function parseReminderFromProgress(progressData) {
    if (!progressData || typeof progressData !== "object") return null;
    return parseReminderMinutesOfDay(progressData.daily_reminder_minutes);
}

function resolveReminderEnabled(reminderData, progressData) {
    const reminderEnabled = !reminderData || (
        reminderData.reminder_enabled !== false &&
        reminderData.enabled !== false
    );
    const progressEnabled = !progressData || (
        progressData.notifications_enabled !== false
    );
    return reminderEnabled && progressEnabled;
}

function buildLocalDateKey(nowUtc, offsetMinutes) {
    const localNow = new Date(nowUtc.getTime() + (offsetMinutes * 60000));
    const y = localNow.getUTCFullYear();
    const m = String(localNow.getUTCMonth() + 1).padStart(2, "0");
    const d = String(localNow.getUTCDate()).padStart(2, "0");
    return `${y}-${m}-${d}`;
}

/**
 * dispatchCustomReminders
 *
 * Runs every 5 minutes. For each student whose local current time is within
 * [reminder_time, reminder_time + 5min), sends an FCM push to their device.
 * This ensures reminders are never sent earlier than the chosen local time.
 *
 * De-duplication: one reminder per local date via
 * users/{uid}/private/reminder.last_sent_local_date_key.
 *
 * This approach needs no Cloud Tasks or per-user cron jobs — a single
 * scheduled function handles all users.
 */
exports.dispatchCustomReminders = onSchedule(
    {
        region: "us-central1",
        schedule: "*/5 * * * *", // every 5 minutes
        timeZone: "UTC",
    },
    async () => {
        const db = admin.firestore();
        const nowUtc = new Date();
        const nowUtcHour = nowUtc.getUTCHours();
        const nowUtcMinute = nowUtc.getUTCMinutes();
        const nowUtcTotalMinutes = (nowUtcHour * 60) + nowUtcMinute;

        console.log(`[dispatchCustomReminders] UTC ${nowUtcHour}:${String(nowUtcMinute).padStart(2, "0")}`);

        // Fetch all student users (batch via collection query)
        const usersSnap = await db.collection("users")
            .where("role", "==", "student")
            .get();

        if (usersSnap.empty) {
            console.log("No student users found.");
            return;
        }

        const students = usersSnap.docs.map((doc) => ({
            uid: doc.id,
            userData: doc.data() || {},
        }));

        const stats = {
            totalStudents: students.length,
            sent: 0,
            skipped: 0,
            missingReminder: 0,
            missingReminderDoc: 0,
            disabled: 0,
            invalidReminderConfig: 0,
            missingToken: 0,
            notDue: 0,
            alreadySentToday: 0,
            dueCandidates: 0,
            sendFailed: 0,
            usedProgressFallback: 0,
            usedDefaultFallback: 0,
        };

        // Process in batches of 20 to respect Firestore getAll limits
        const BATCH_SIZE = 20;
        for (let i = 0; i < students.length; i += BATCH_SIZE) {
            const batchStudents = students.slice(i, i + BATCH_SIZE);

            // Read private/reminder for each user in this batch
            const reminderRefs = batchStudents.map(({ uid }) =>
                db.collection("users").doc(uid).collection("private").doc("reminder")
            );
            const tokenRefs = batchStudents.map(({ uid }) =>
                db.collection("users").doc(uid).collection("private").doc("device")
            );
            const progressRefs = batchStudents.map(({ uid }) =>
                db.collection("users").doc(uid).collection("progress").doc("all_data")
            );

            const [reminderSnaps, tokenSnaps, progressSnaps] = await Promise.all([
                db.getAll(...reminderRefs),
                db.getAll(...tokenRefs),
                db.getAll(...progressRefs),
            ]);

            const sendPromises = [];

            for (let j = 0; j < batchStudents.length; j++) {
                const { uid, userData } = batchStudents[j];
                const reminderSnap = reminderSnaps[j];
                const tokenSnap = tokenSnaps[j];
                const progressSnap = progressSnaps[j];

                if (!reminderSnap.exists) stats.missingReminderDoc++;

                const reminder = reminderSnap.exists ? (reminderSnap.data() || {}) : null;
                const progressData = progressSnap.exists ? (progressSnap.data() || {}) : null;
                const reminderEnabled = resolveReminderEnabled(reminder, progressData);
                if (!reminderEnabled) {
                    stats.skipped++;
                    stats.disabled++;
                    continue;
                }

                let reminderTime = parseReminderTime(reminder);
                let reminderSource = "private";
                if (!reminderTime) {
                    const progressReminderTime = parseReminderFromProgress(progressData);
                    if (progressReminderTime) {
                        reminderTime = progressReminderTime;
                        reminderSource = "progress";
                        stats.usedProgressFallback++;
                    }
                }
                if (!reminderTime) {
                    // Backward-compatible default for users who never saved custom reminder config.
                    reminderTime = { hour: 9, minute: 0 };
                    reminderSource = "default";
                    stats.usedDefaultFallback++;
                }

                if (!reminderTime) {
                    stats.skipped++;
                    stats.invalidReminderConfig++;
                    stats.missingReminder++;
                    continue;
                }

                const offsetMinutes = normalizeTimezoneOffsetMinutes(
                    reminder?.timezone_offset_minutes ??
                        reminder?.timezoneOffsetMinutes ??
                        progressData?.timezone_offset_minutes ??
                        progressData?.timezoneOffsetMinutes ??
                        userData?.timezone_offset_minutes ??
                        userData?.timezoneOffsetMinutes,
                    330,
                );

                if (reminderSource !== "private") {
                    try {
                        await reminderSnap.ref.set({
                            reminder_hour: reminderTime.hour,
                            reminder_minute: reminderTime.minute,
                            hour: reminderTime.hour,
                            minute: reminderTime.minute,
                            timezone_offset_minutes: offsetMinutes,
                            timezoneOffsetMinutes: offsetMinutes,
                            reminder_enabled: reminderEnabled,
                            enabled: reminderEnabled,
                            fallback_source: reminderSource,
                            updated_at: admin.firestore.FieldValue.serverTimestamp(),
                        }, { merge: true });
                    } catch (persistError) {
                        console.error(
                            `[dispatchCustomReminders] fallback persist failed uid=${uid}: ${persistError.message}`,
                        );
                    }
                }

                const privateToken = tokenSnap.exists
                    ? (tokenSnap.data()?.fcmToken || "")
                    : "";
                let fcmToken = typeof privateToken === "string"
                    ? privateToken.trim()
                    : "";
                let tokenSource = "private";

                // Fallback for legacy users where token is still in users/{uid}.fcmToken.
                if (!fcmToken) {
                    const legacyToken = typeof userData.fcmToken === "string"
                        ? userData.fcmToken.trim()
                        : "";
                    if (legacyToken) {
                        fcmToken = legacyToken;
                        tokenSource = "legacy_root";
                    }
                }

                if (!fcmToken) {
                    stats.skipped++;
                    stats.missingToken++;
                    continue;
                }

                // Convert current UTC clock to user's local clock (minutes since midnight).
                const nowLocalMinutes = (
                    ((nowUtcTotalMinutes + offsetMinutes) % (24 * 60)) + (24 * 60)
                ) % (24 * 60);
                const reminderLocalMinutes = (reminderTime.hour * 60) + reminderTime.minute;

                // Delta in [0..1439]. Eligible window is [0..4] minutes after chosen time.
                const deltaMinutes = (
                    (nowLocalMinutes - reminderLocalMinutes) + (24 * 60)
                ) % (24 * 60);
                if (deltaMinutes >= REMINDER_WINDOW_MINUTES) {
                    stats.skipped++;
                    stats.notDue++;
                    continue;
                }

                // De-dupe per user per local day.
                const localDateKey = buildLocalDateKey(nowUtc, offsetMinutes);
                const lastSentLocalDateKey =
                    (reminder.last_sent_local_date_key || "").toString();
                if (lastSentLocalDateKey === localDateKey) {
                    stats.skipped++;
                    stats.alreadySentToday++;
                    continue;
                }

                // Concurrency guard:
                // claim this user/day before sending so overlapping scheduler
                // runs do not send duplicates.
                let claimedForToday = false;
                try {
                    claimedForToday = await db.runTransaction(async (tx) => {
                        const latestReminderSnap = await tx.get(reminderSnap.ref);
                        const latestReminder = latestReminderSnap.exists
                            ? (latestReminderSnap.data() || {})
                            : {};
                        const latestSentKey =
                            (latestReminder.last_sent_local_date_key || "").toString();
                        const pendingKey =
                            (latestReminder.pending_local_date_key || "").toString();

                        if (
                            latestSentKey === localDateKey ||
                            pendingKey === localDateKey
                        ) {
                            return false;
                        }

                        tx.set(reminderSnap.ref, {
                            pending_local_date_key: localDateKey,
                            pending_marked_at: admin.firestore.FieldValue.serverTimestamp(),
                        }, { merge: true });
                        return true;
                    });
                } catch (claimError) {
                    console.error(
                        `[dispatchCustomReminders] claim failed uid=${uid}: ${claimError.message}`,
                    );
                    claimedForToday = false;
                }

                if (!claimedForToday) {
                    stats.skipped++;
                    stats.alreadySentToday++;
                    continue;
                }

                stats.dueCandidates++;

                const message = {
                    token: fcmToken,
                    notification: {
                        title: "Daily Learning Reminder",
                        body: "Time to practise! Complete your vocabulary and speaking tasks today.",
                    },
                    data: {
                        type: "daily_reminder",
                        screen: "daily_tasks",
                        click_action: "FLUTTER_NOTIFICATION_CLICK",
                        reminder_local_time: `${String(reminderTime.hour).padStart(2, "0")}:${String(reminderTime.minute).padStart(2, "0")}`,
                    },
                    android: {
                        priority: "high",
                        notification: {
                            channelId: "daily_reminders_channel",
                            sound: "default",
                        },
                    },
                };

                sendPromises.push(
                    admin.messaging().send(message)
                        .then(async (msgId) => {
                            stats.sent++;
                            console.log(
                                `[dispatchCustomReminders] sent uid=${uid} msgId=${msgId} source=${reminderSource}`,
                            );

                            // Record delivery marker to avoid duplicate sends the same day.
                            await reminderSnap.ref.set({
                                last_sent_at: admin.firestore.FieldValue.serverTimestamp(),
                                last_sent_local_date_key: localDateKey,
                                last_sent_message_id: msgId,
                                pending_local_date_key: admin.firestore.FieldValue.delete(),
                                pending_marked_at: admin.firestore.FieldValue.delete(),
                            }, { merge: true });
                        })
                        .catch(async (err) => {
                            stats.sendFailed++;
                            console.error(`[dispatchCustomReminders] failed uid=${uid}: ${err.message}`);

                            // Release day-claim so a later scheduler run can retry.
                            await reminderSnap.ref.set({
                                pending_local_date_key: admin.firestore.FieldValue.delete(),
                                pending_marked_at: admin.firestore.FieldValue.delete(),
                            }, { merge: true });

                            // If token is invalid/expired, clean up both private and legacy fields.
                            if (
                                err.code === "messaging/registration-token-not-registered" ||
                                err.code === "messaging/invalid-registration-token"
                            ) {
                                const cleanupOps = [];
                                if (tokenSnap.exists) {
                                    cleanupOps.push(
                                        tokenSnap.ref.set({
                                            fcmToken: admin.firestore.FieldValue.delete(),
                                            lastTokenUpdate: admin.firestore.FieldValue.delete(),
                                        }, { merge: true }),
                                    );
                                }
                                cleanupOps.push(
                                    db.collection("users").doc(uid).set({
                                        fcmToken: admin.firestore.FieldValue.delete(),
                                        lastTokenUpdate: admin.firestore.FieldValue.delete(),
                                    }, { merge: true }),
                                );
                                await Promise.allSettled(cleanupOps);
                                console.log(`[dispatchCustomReminders] cleared invalid token uid=${uid} source=${tokenSource}`);
                            }
                        }),
                );
            }

            await Promise.all(sendPromises);
        }

        console.log(`[dispatchCustomReminders] done ${JSON.stringify(stats)}`);
        await logNotificationDelivery("dispatch_custom_reminders", true, {
            ...stats,
            runAtUtc: nowUtc.toISOString(),
            windowMinutes: REMINDER_WINDOW_MINUTES,
        });
    }
);

