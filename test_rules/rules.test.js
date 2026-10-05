import { describe, it, before, after, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from '@firebase/rules-unit-testing';
import fs from 'fs';

let testEnv;

before(async () => {
  const rulesPath = new URL('../database.rules.json', import.meta.url);
  const rules = fs.readFileSync(rulesPath, 'utf8');
  testEnv = await initializeTestEnvironment({
    projectId: 'presensi-rules-test',
    database: {
      host: '127.0.0.1',
      port: 9000,
      rules: rules,
    },
  });
});

after(async () => {
  if (testEnv) {
    await testEnv.cleanup();
  }
});

beforeEach(async () => {
  // Clear and setup fresh seed data
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.database();
    await db.ref().set(null); // reset

    // Seed users
    await db.ref('users/mhs1').set({
      nama: 'Mahasiswa Satu',
      email: 'mhs1@student.uin-malang.ac.id',
      identitas: '240605110101',
      role: 'mahasiswa',
    });
    await db.ref('users/mhs2').set({
      nama: 'Mahasiswa Dua',
      email: 'mhs2@student.uin-malang.ac.id',
      identitas: '240605110102',
      role: 'mahasiswa',
    });
    await db.ref('users/dosen1').set({
      nama: 'Dosen Satu, M.Kom.',
      email: 'dosen1@uin-malang.ac.id',
      identitas: '198001012005011001',
      role: 'dosen',
    });
    await db.ref('users/dosen2').set({
      nama: 'Dosen Dua, M.T.',
      email: 'dosen2@uin-malang.ac.id',
      identitas: '198502022010022002',
      role: 'dosen',
    });

    // Seed sessions
    // Sesi 1: dibuat oleh dosen1, status 'aktif', kode 'ABCXYZ'
    await db.ref('sessions/sesi1').set({
      judulSesi: 'Pertemuan 1 Mobile Programming',
      informasiPertemuan: 'Pengenalan Flutter',
      lecturerId: 'dosen1',
      kodePresensi: 'ABCXYZ',
      status: 'aktif',
      waktuDibuat: Date.now(),
      waktuDibuka: Date.now(),
    });

    // Sesi 2: dibuat oleh dosen2, status 'ditutup', kode 'DEFUVW'
    await db.ref('sessions/sesi2').set({
      judulSesi: 'Pertemuan 1 Basis Data',
      informasiPertemuan: 'Pengenalan SQL',
      lecturerId: 'dosen2',
      kodePresensi: 'DEFUVW',
      status: 'ditutup',
      waktuDibuat: Date.now(),
    });
  });
});

describe('Firebase Realtime Database Security Rules Test Suite', () => {
  // Skenario 1
  it('1. Mahasiswa gagal membaca seluruh koleksi sessions tanpa query', async () => {
    const mhsDb = testEnv.authenticatedContext('mhs1').database();
    await assertFails(mhsDb.ref('sessions').once('value'));
  });

  // Skenario 2
  it('2. Mahasiswa berhasil mencari kode exact-match yang valid', async () => {
    const mhsDb = testEnv.authenticatedContext('mhs1').database();
    const queryRef = mhsDb
      .ref('sessions')
      .orderByChild('kodePresensi')
      .equalTo('ABCXYZ');
    const snap = await assertSucceeds(queryRef.once('value'));
    const val = snap.val();
    assert.ok(val !== null);
    assert.ok(val.sesi1 !== undefined);
  });

  // Skenario 3
  it('3. Mahasiswa gagal membaca attendance mahasiswa lain', async () => {
    // Seed attendance mhs2 terlebih dahulu
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.database();
      await db.ref('attendance/sesi1/mhs2').set({
        sessionId: 'sesi1',
        studentId: 'mhs2',
        status: 'Hadir',
        waktuPresensi: Date.now(),
      });
    });

    const mhs1Db = testEnv.authenticatedContext('mhs1').database();
    // Mhs1 mencoba membaca node mhs2
    await assertFails(mhs1Db.ref('attendance/sesi1/mhs2').once('value'));
    // Mhs1 juga gagal membaca root attendance sesi1
    await assertFails(mhs1Db.ref('attendance/sesi1').once('value'));
  });

  // Skenario 4
  it('4. Dosen pemilik berhasil membaca attendance sesinya', async () => {
    // Seed attendance
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.database();
      await db.ref('attendance/sesi1/mhs1').set({
        sessionId: 'sesi1',
        studentId: 'mhs1',
        status: 'Hadir',
        waktuPresensi: Date.now(),
      });
    });

    const dosen1Db = testEnv.authenticatedContext('dosen1').database();
    const snap = await assertSucceeds(dosen1Db.ref('attendance/sesi1').once('value'));
    assert.ok(snap.val() !== null);
  });

  // Skenario 5
  it('5. Dosen lain gagal membaca attendance sesi tersebut', async () => {
    // Seed attendance pada sesi1 (milik dosen1)
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.database();
      await db.ref('attendance/sesi1/mhs1').set({
        sessionId: 'sesi1',
        studentId: 'mhs1',
        status: 'Hadir',
        waktuPresensi: Date.now(),
      });
    });

    // dosen2 mencoba membaca attendance sesi1
    const dosen2Db = testEnv.authenticatedContext('dosen2').database();
    await assertFails(dosen2Db.ref('attendance/sesi1').once('value'));
  });

  // Skenario 6
  it('6. Mahasiswa gagal mengganti role', async () => {
    const mhsDb = testEnv.authenticatedContext('mhs1').database();
    await assertFails(mhsDb.ref('users/mhs1').update({ role: 'dosen' }));
    await assertFails(mhsDb.ref('users/mhs1/role').set('dosen'));
  });

  // Skenario 7
  it('7. Mahasiswa gagal membuat sesi', async () => {
    const mhsDb = testEnv.authenticatedContext('mhs1').database();
    await assertFails(
      mhsDb.ref('sessions/sesi_ilegal').set({
        judulSesi: 'Sesi Ilegal Mahasiswa',
        informasiPertemuan: 'Tidak sah',
        lecturerId: 'mhs1',
        kodePresensi: 'ILEGAL',
        status: 'aktif',
        waktuDibuat: Date.now(),
      })
    );
  });

  // Skenario 8
  it('8. Mahasiswa berhasil presensi Hadir pertama', async () => {
    const mhsDb = testEnv.authenticatedContext('mhs1').database();
    await assertSucceeds(
      mhsDb.ref('attendance/sesi1/mhs1').set({
        sessionId: 'sesi1',
        studentId: 'mhs1',
        status: 'Hadir',
        waktuPresensi: Date.now(),
      })
    );
  });

  // Skenario 9
  it('9. Presensi kedua ditolak', async () => {
    const mhsDb = testEnv.authenticatedContext('mhs1').database();
    // Presensi pertama
    await assertSucceeds(
      mhsDb.ref('attendance/sesi1/mhs1').set({
        sessionId: 'sesi1',
        studentId: 'mhs1',
        status: 'Hadir',
        waktuPresensi: Date.now(),
      })
    );

    // Presensi kedua (mencoba menulis ulang / set ulang)
    await assertFails(
      mhsDb.ref('attendance/sesi1/mhs1').set({
        sessionId: 'sesi1',
        studentId: 'mhs1',
        status: 'Hadir',
        waktuPresensi: Date.now() + 1000,
      })
    );
  });

  // Skenario 10
  it('10. Mahasiswa gagal mengubah status', async () => {
    const mhsDb = testEnv.authenticatedContext('mhs1').database();
    // Presensi pertama
    await assertSucceeds(
      mhsDb.ref('attendance/sesi1/mhs1').set({
        sessionId: 'sesi1',
        studentId: 'mhs1',
        status: 'Hadir',
        waktuPresensi: Date.now(),
      })
    );

    // Mahasiswa mencoba mengubah status sendiri ke Izin
    await assertFails(
      mhsDb.ref('attendance/sesi1/mhs1').update({
        status: 'Izin',
      })
    );
  });

  // Skenario 11
  it('11. Dosen pemilik berhasil melakukan koreksi', async () => {
    // Seed kehadiran mhs1 sebagai Hadir
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.database();
      await db.ref('attendance/sesi1/mhs1').set({
        sessionId: 'sesi1',
        studentId: 'mhs1',
        status: 'Hadir',
        waktuPresensi: Date.now(),
      });
    });

    const dosen1Db = testEnv.authenticatedContext('dosen1').database();
    // Dosen1 mengoreksi status mhs1 menjadi 'Izin'
    await assertSucceeds(
      dosen1Db.ref('attendance/sesi1/mhs1').update({
        status: 'Izin',
      })
    );

    // Dosen1 membuat koreksi langsung untuk mhs2 yang belum presensi menjadi 'Alpha'
    await assertSucceeds(
      dosen1Db.ref('attendance/sesi1/mhs2').set({
        sessionId: 'sesi1',
        studentId: 'mhs2',
        status: 'Alpha',
        waktuPresensi: Date.now(),
      })
    );
  });

  // Skenario 12
  it('12. Dosen lain gagal melakukan koreksi', async () => {
    // Seed kehadiran mhs1 di sesi1 (milik dosen1)
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.database();
      await db.ref('attendance/sesi1/mhs1').set({
        sessionId: 'sesi1',
        studentId: 'mhs1',
        status: 'Hadir',
        waktuPresensi: Date.now(),
      });
    });

    const dosen2Db = testEnv.authenticatedContext('dosen2').database();
    // Dosen2 mencoba mengoreksi status di sesi milik dosen1
    await assertFails(
      dosen2Db.ref('attendance/sesi1/mhs1').update({
        status: 'Sakit',
      })
    );
    await assertFails(
      dosen2Db.ref('attendance/sesi1/mhs2').set({
        sessionId: 'sesi1',
        studentId: 'mhs2',
        status: 'Alpha',
        waktuPresensi: Date.now(),
      })
    );
  });

  // Pengujian Tambahan: Query sesi dosen & pembacaan langsung
  it('13. Dosen hanya boleh query sesi miliknya (berdasarkan lecturerId === auth.uid)', async () => {
    const dosen1Db = testEnv.authenticatedContext('dosen1').database();
    // Query sesi miliknya sendiri -> SUCCEED
    const queryOwn = dosen1Db
      .ref('sessions')
      .orderByChild('lecturerId')
      .equalTo('dosen1');
    const snap = await assertSucceeds(queryOwn.once('value'));
    assert.ok(snap.val().sesi1 !== undefined);

    // Query sesi milik dosen lain -> FAIL
    const queryOther = dosen1Db
      .ref('sessions')
      .orderByChild('lecturerId')
      .equalTo('dosen2');
    await assertFails(queryOther.once('value'));
  });

  it('14. Pembacaan langsung sesi aktif vs ditutup', async () => {
    const mhsDb = testEnv.authenticatedContext('mhs1').database();
    const dosen1Db = testEnv.authenticatedContext('dosen1').database();

    // Sesi1 aktif: Mahasiswa & Dosen pemilik boleh membaca
    await assertSucceeds(mhsDb.ref('sessions/sesi1').once('value'));
    await assertSucceeds(dosen1Db.ref('sessions/sesi1').once('value'));

    // Sesi2 ditutup (milik dosen2): Mahasiswa & Dosen1 gagal membaca langsung
    await assertFails(mhsDb.ref('sessions/sesi2').once('value'));
    await assertFails(dosen1Db.ref('sessions/sesi2').once('value'));

    // Sesi2 ditutup: Dosen2 (pemilik) tetap berhasil membaca langsung
    const dosen2Db = testEnv.authenticatedContext('dosen2').database();
    await assertSucceeds(dosen2Db.ref('sessions/sesi2').once('value'));
  });

  it('15. Dosen pemilik mengubah sesi miliknya vs dosen lain mencoba mengubah', async () => {
    const dosen1Db = testEnv.authenticatedContext('dosen1').database();
    const dosen2Db = testEnv.authenticatedContext('dosen2').database();

    // Dosen1 menutup sesi miliknya -> SUCCEED
    await assertSucceeds(
      dosen1Db.ref('sessions/sesi1').update({
        status: 'ditutup',
        waktuDitutup: Date.now(),
      })
    );

    // Dosen2 mencoba mengubah sesi1 milik dosen1 -> FAIL
    await assertFails(
      dosen2Db.ref('sessions/sesi1').update({
        status: 'aktif',
      })
    );

    // Dosen1 mencoba mengganti lecturerId pada sesinya -> FAIL (immutable)
    await assertFails(
      dosen1Db.ref('sessions/sesi1').update({
        lecturerId: 'dosen2',
      })
    );
  });
});
