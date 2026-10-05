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

  // ─────────────────────────────────────────
  // SKENARIO BARU: Persistent Index & Role-Enforced Query
  // ─────────────────────────────────────────

  it('16. Riwayat tetap dapat dimuat instance SessionService baru tanpa cache lama', async () => {
    // Seed: attendance mhs1 di sesi1, dan index sudah ada
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.database();
      await db.ref('attendance/sesi1/mhs1').set({
        sessionId: 'sesi1',
        studentId: 'mhs1',
        status: 'Hadir',
        waktuPresensi: Date.now(),
      });
      await db.ref('users/mhs1/attendanceSessionIds/sesi1').set(true);
    });

    // Simulasi instance baru: baca index dari Firebase (bukan cache proses)
    const mhs1Db = testEnv.authenticatedContext('mhs1').database();
    const indexSnap = await assertSucceeds(
      mhs1Db.ref('users/mhs1/attendanceSessionIds').once('value')
    );
    assert.ok(indexSnap.val() !== null);
    assert.ok(indexSnap.val()['sesi1'] === true);

    // Baca attendance berdasarkan index — seperti yang dilakukan getRiwayatMahasiswa()
    const attSnap = await assertSucceeds(
      mhs1Db.ref('attendance/sesi1/mhs1').once('value')
    );
    assert.ok(attSnap.val() !== null);
    assert.strictEqual(attSnap.val().status, 'Hadir');
  });

  it('17. Riwayat tetap ada setelah simulasi logout dan login ulang', async () => {
    // Seed: attendance + index persisten
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.database();
      await db.ref('attendance/sesi1/mhs1').set({
        sessionId: 'sesi1',
        studentId: 'mhs1',
        status: 'Hadir',
        waktuPresensi: Date.now(),
      });
      await db.ref('users/mhs1/attendanceSessionIds/sesi1').set(true);
    });

    // "Logout" = gunakan context auth baru (simulasi re-login dengan uid yang sama)
    const freshCtx = testEnv.authenticatedContext('mhs1');
    const freshDb = freshCtx.database();

    const indexSnap = await assertSucceeds(
      freshDb.ref('users/mhs1/attendanceSessionIds').once('value')
    );
    assert.ok(indexSnap.val() !== null, 'Index harus ada setelah re-login');

    const attSnap = await assertSucceeds(
      freshDb.ref('attendance/sesi1/mhs1').once('value')
    );
    assert.ok(attSnap.val() !== null, 'Attendance harus tetap ada');
  });

  it('18. Mahasiswa hanya dapat menulis index miliknya setelah attendance ada', async () => {
    // Seed attendance mhs1 di sesi1
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.database();
      await db.ref('attendance/sesi1/mhs1').set({
        sessionId: 'sesi1',
        studentId: 'mhs1',
        status: 'Hadir',
        waktuPresensi: Date.now(),
      });
    });

    const mhs1Db = testEnv.authenticatedContext('mhs1').database();

    // mhs1 menulis index miliknya sendiri setelah attendance ada -> SUCCEED
    await assertSucceeds(
      mhs1Db.ref('users/mhs1/attendanceSessionIds/sesi1').set(true)
    );
  });

  it('19. Mahasiswa tidak dapat menambahkan session ID palsu (tanpa attendance)', async () => {
    const mhs1Db = testEnv.authenticatedContext('mhs1').database();

    // Tidak ada attendance/sesi1/mhs1 — index tidak boleh ditulis
    await assertFails(
      mhs1Db.ref('users/mhs1/attendanceSessionIds/sesi1').set(true)
    );

    // Session tidak ada sama sekali
    await assertFails(
      mhs1Db.ref('users/mhs1/attendanceSessionIds/sesipalsu').set(true)
    );
  });

  it('20. Mahasiswa tidak dapat menulis index milik mahasiswa lain', async () => {
    // Seed attendance mhs1 di sesi1
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.database();
      await db.ref('attendance/sesi1/mhs1').set({
        sessionId: 'sesi1',
        studentId: 'mhs1',
        status: 'Hadir',
        waktuPresensi: Date.now(),
      });
    });

    const mhs1Db = testEnv.authenticatedContext('mhs1').database();

    // mhs1 mencoba menulis index milik mhs2 -> FAIL
    await assertFails(
      mhs1Db.ref('users/mhs2/attendanceSessionIds/sesi1').set(true)
    );
  });

  it('21. Dosen pemilik sesi dapat menambahkan index setelah koreksi', async () => {
    // Seed: dosen1 sudah membuat attendance mhs2 via koreksi
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.database();
      await db.ref('attendance/sesi1/mhs2').set({
        sessionId: 'sesi1',
        studentId: 'mhs2',
        status: 'Alpha',
        waktuPresensi: Date.now(),
      });
    });

    const dosen1Db = testEnv.authenticatedContext('dosen1').database();

    // Dosen1 menulis index mhs2 untuk sesi1 (sesi miliknya) -> SUCCEED
    await assertSucceeds(
      dosen1Db.ref('users/mhs2/attendanceSessionIds/sesi1').set(true)
    );
  });

  it('22. Dosen lain tidak dapat menulis index mahasiswa pada sesi yang bukan miliknya', async () => {
    // Seed: attendance mhs1 di sesi1 (milik dosen1) dan sesi2 (milik dosen2)
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.database();
      await db.ref('attendance/sesi1/mhs1').set({
        sessionId: 'sesi1',
        studentId: 'mhs1',
        status: 'Hadir',
        waktuPresensi: Date.now(),
      });
      // dosen2 juga mengoreksi mhs1 di sesi2 miliknya
      await db.ref('attendance/sesi2/mhs1').set({
        sessionId: 'sesi2',
        studentId: 'mhs1',
        status: 'Alpha',
        waktuPresensi: Date.now(),
      });
    });

    const dosen2Db = testEnv.authenticatedContext('dosen2').database();

    // Dosen2 mencoba menulis index mhs1 untuk sesi1 (sesi milik dosen1) -> FAIL
    await assertFails(
      dosen2Db.ref('users/mhs1/attendanceSessionIds/sesi1').set(true)
    );

    // Dosen2 boleh menulis index mhs1 untuk sesi2 (sesi miliknya sendiri) -> SUCCEED
    // Ini skenario sah: dosen2 melakukan koreksi pada sesi2 untuk mhs1
    await assertSucceeds(
      dosen2Db.ref('users/mhs1/attendanceSessionIds/sesi2').set(true)
    );
  });

  it('23. Akun Authentication tanpa profil gagal query kode', async () => {
    // Pengguna dengan auth tapi tidak ada data di users/
    const ghostDb = testEnv.authenticatedContext('ghost_uid').database();

    // Query kodePresensi: harus punya role mahasiswa -> FAIL
    const queryRef = ghostDb
      .ref('sessions')
      .orderByChild('kodePresensi')
      .equalTo('ABCXYZ');
    await assertFails(queryRef.once('value'));
  });

  it('24. Mahasiswa berhasil query kode exact-match (sudah punya profil valid)', async () => {
    const mhs1Db = testEnv.authenticatedContext('mhs1').database();

    // mhs1 punya profil role mahasiswa -> SUCCEED
    const queryRef = mhs1Db
      .ref('sessions')
      .orderByChild('kodePresensi')
      .equalTo('ABCXYZ');
    const snap = await assertSucceeds(queryRef.once('value'));
    assert.ok(snap.val() !== null);
    assert.ok(snap.val()['sesi1'] !== undefined);
  });

  it('25. Dosen hanya berhasil query sesi miliknya sendiri', async () => {
    const dosen1Db = testEnv.authenticatedContext('dosen1').database();

    // Dosen1 query sesi miliknya -> SUCCEED
    const queryOwn = dosen1Db
      .ref('sessions')
      .orderByChild('lecturerId')
      .equalTo('dosen1');
    const snap = await assertSucceeds(queryOwn.once('value'));
    assert.ok(snap.val() !== null);

    // Dosen1 query sesi milik dosen2 -> FAIL (equalTo !== auth.uid)
    const queryOther = dosen1Db
      .ref('sessions')
      .orderByChild('lecturerId')
      .equalTo('dosen2');
    await assertFails(queryOther.once('value'));

    // Mahasiswa tidak boleh query lecturerId -> FAIL (bukan role dosen)
    const mhs1Db = testEnv.authenticatedContext('mhs1').database();
    const queryMhs = mhs1Db
      .ref('sessions')
      .orderByChild('lecturerId')
      .equalTo('dosen1');
    await assertFails(queryMhs.once('value'));
  });

  // ─────────────────────────────────────────
  // SKENARIO BARU: Validasi attendance record wajib ada + sessionId/studentId cocok
  // ─────────────────────────────────────────

  it('26. Dosen pemilik gagal menambah index sebelum attendance dibuat', async () => {
    // belum ada attendance/sesi1/mhs1 sama sekali (beforeEach sudah reset)
    const dosen1Db = testEnv.authenticatedContext('dosen1').database();

    // attendance belum ada -> FAIL meski dosen adalah pemilik sesi
    await assertFails(
      dosen1Db.ref('users/mhs1/attendanceSessionIds/sesi1').set(true)
    );
  });

  it('27. Dosen pemilik berhasil menambah index setelah attendance dibuat', async () => {
    // Seed: dosen1 sudah menulis attendance mhs1 di sesi1 (via koreksi)
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.database().ref('attendance/sesi1/mhs1').set({
        sessionId: 'sesi1',
        studentId: 'mhs1',
        status: 'Alpha',
        waktuPresensi: Date.now(),
      });
    });

    const dosen1Db = testEnv.authenticatedContext('dosen1').database();

    // attendance sudah ada + sessionId/studentId cocok -> SUCCEED
    await assertSucceeds(
      dosen1Db.ref('users/mhs1/attendanceSessionIds/sesi1').set(true)
    );
  });

  it('28. Dosen gagal menambah index pada profil dengan role dosen', async () => {
    // Seed: attendance sesi1/dosen2 — target $uid adalah dosen2 (role dosen)
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.database().ref('attendance/sesi1/dosen2').set({
        sessionId: 'sesi1',
        studentId: 'dosen2',
        status: 'Hadir',
        waktuPresensi: Date.now(),
      });
    });

    const dosen1Db = testEnv.authenticatedContext('dosen1').database();

    // Target $uid = dosen2 yang role-nya 'dosen', bukan 'mahasiswa' -> FAIL
    await assertFails(
      dosen1Db.ref('users/dosen2/attendanceSessionIds/sesi1').set(true)
    );
  });

  it('29. Mahasiswa gagal menambah index jika attendance belum ada', async () => {
    // beforeEach sudah reset — tidak ada attendance sama sekali
    const mhs1Db = testEnv.authenticatedContext('mhs1').database();

    // Tidak ada attendance/sesi1/mhs1 -> FAIL
    await assertFails(
      mhs1Db.ref('users/mhs1/attendanceSessionIds/sesi1').set(true)
    );
  });

  it('30. Mahasiswa berhasil menambah index setelah attendance miliknya ada (sessionId & studentId cocok)', async () => {
    // Seed: attendance mhs1 di sesi1 dengan sessionId dan studentId yang benar
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.database().ref('attendance/sesi1/mhs1').set({
        sessionId: 'sesi1',   // cocok dengan $sessionId
        studentId: 'mhs1',    // cocok dengan $uid
        status: 'Hadir',
        waktuPresensi: Date.now(),
      });
    });

    const mhs1Db = testEnv.authenticatedContext('mhs1').database();

    // attendance ada + sessionId === $sessionId + studentId === $uid -> SUCCEED
    await assertSucceeds(
      mhs1Db.ref('users/mhs1/attendanceSessionIds/sesi1').set(true)
    );
  });
});
