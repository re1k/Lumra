import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { initializeApp } from "firebase-admin/app";

initializeApp();
const db = getFirestore();
const messaging = getMessaging();


export const scheduleEventReminder = onSchedule("every 1 minutes", async (event) => {
    console.log(" Checking upcoming events...");

    const now = new Date();
    const in24Hours = new Date(now.getTime() + 24 * 60 * 60 * 1000);


    const snapshot = await db.collection("events")
        .where("start", "<=", in24Hours)
        .where("start", ">", now)
        .get();

    if (snapshot.empty) {
        console.log(" No upcoming events within 24h.");
        return;
    }

    for (const doc of snapshot.docs) {
        const data = doc.data();
        const eventId = doc.id;

        if (data.reminderSent) {
            console.log(` Skipping already-sent reminder for: ${data.title}`);
            continue;
        }

        console.log(` Sending reminder for event: ${data.title}`);

        const participants = data.participants || [];

        let allTokens = [];

        for (const uid of participants) {
            const userDoc = await db.collection("users").doc(uid).get();
            const token = userDoc.data()?.fcmToken;
            if (token) allTokens.push(token);
        }


        if (allTokens.length) {
            const message = {
                notification: {
                    title: "⏰ Reminder: Upcoming Event",
                    body: `Your event "${data.title}" starts in 24 hours.`,
                },
                tokens: allTokens,
            };

            try {
                const res = await messaging.sendEachForMulticast(message);
                console.log(` Sent reminder to ${res.successCount}/${allTokens.length} users.`);
            } catch (err) {
                console.error(" Error sending multicast message:", err);
            }
        }

        await doc.ref.update({ reminderSent: true });
        console.log(` Marked reminderSent for ${data.title}`);
    }
});
