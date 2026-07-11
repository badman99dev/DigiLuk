const admin = require('firebase-admin');

// Path to your service account JSON file from Firebase Console
// Project settings -> Service accounts -> Generate new private key
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'digiluk',
});

const db = admin.firestore();

async function migrateTrusts() {
  const snapshot = await db.collection('trusts').get();
  console.log(`Found ${snapshot.size} trusts to migrate`);

  const batch = db.batch();
  let count = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const members = data.members || [];

    const memberUids = members.map((m) => m.uid).filter(Boolean);
    const managerUids = members
      .filter((m) => m.role === 'creator' || m.role === 'manager')
      .map((m) => m.uid)
      .filter(Boolean);

    batch.update(doc.ref, {
      memberUids: admin.firestore.FieldValue.arrayUnion(...memberUids),
      managerUids: admin.firestore.FieldValue.arrayUnion(...managerUids),
    });

    count++;
    if (count % 500 === 0) {
      await batch.commit();
      console.log(`Committed ${count} trusts...`);
    }
  }

  if (count % 500 !== 0) {
    await batch.commit();
  }

  console.log(`Migration complete. Updated ${count} trusts.`);
}

migrateTrusts()
  .then(() => process.exit(0))
  .catch((e) => {
    console.error('Migration failed:', e);
    process.exit(1);
  });
