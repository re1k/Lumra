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
                    title: "Reminder",
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
///////////////JANAS PART//////////////////////////////////
export const sendDailyCaregiverSupport = onSchedule("every 24 hours", async (event) => {
  //FOR TEST
  //export const sendDailyCaregiverSupport = onSchedule("*/1 * * * *", async (event) => {

    console.log("Sending daily supportive notifications to caregivers...");
  
    const now = new Date();
  
    // Today range (00:00 -> 23:59)
    const startOfDay = new Date(now);
    startOfDay.setHours(0, 0, 0, 0);
  
    const endOfDay = new Date(now);
    endOfDay.setHours(23, 59, 59, 999);
  
    //  Get all caregivers
    const caregiversSnap = await db
      .collection("users")
      .where("role", "==", "caregiver")
      .get();
  
    if (caregiversSnap.empty) {
      console.log("No caregivers found.");
      return;
    }
  
    for (const caregiverDoc of caregiversSnap.docs) {
      const caregiver = caregiverDoc.data();
      const caregiverId = caregiverDoc.id;
      const token = caregiver.fcmToken;
      const linkedUserId = caregiver.linkedUserId; // ADHD child UID
  
      if (!token) {
        console.log(`Caregiver ${caregiverId} has no FCM token, skipping.`);
        continue;
      }
  
      if (!linkedUserId) {
        console.log(`Caregiver ${caregiverId} has no linkedUserId, skipping.`);
        continue;
      }
  
      // Count checked tasks for the CG user today
      const tasksSnap = await db
      .collection("users")
      .doc(caregiverId)
      .collection("tasks")
      .where("isChecked", "==", true)
      .where("updatedAt", ">=", startOfDay)
      .where("updatedAt", "<=", endOfDay)
      .get();
      const completedCount = tasksSnap.size;
  
      // supportive message
      let body;
      if (completedCount > 0) {
        //WE MIGHT USE THIS ASK TEAM 
       // body = `Great job today! ${completedCount} task${completedCount > 1 ? "s were" : " was"} completed. Your follow-up is making a big difference `;
       body = `Nice work today! You completed some tasks — keep going.`;

      } else {
        body =
          "Today was a quiet day, and that’s okay. You’re still doing your best!";
      }
  
      const message = {
        notification: {
          title: "Daily Support",
          body,
        },
        token,
      };
  
      try {
        await messaging.send(message);
        console.log(`Sent daily supportive notification to caregiver ${caregiverId}`);
      } catch (err) {
        console.error(`Error sending daily support to caregiver ${caregiverId}:`, err);
      }
    }
  });
