import 'package:flutter_test/flutter_test.dart';
import 'package:pramu_apps/core/router/role_shell.dart';
import 'package:pramu_apps/core/router/routes.dart';

void main() {
  test('tab Pelamar: Profil menggantikan Dompet', () {
    final labels = assistantTabs.map((t) => t.label).toList();
    expect(labels, ['Beranda', 'Lowongan', 'Pekerjaan', 'Pesan', 'Profil']);
    expect(assistantTabs.last.path, Routes.assistantAccount);
  });

  test('tab Pencari tetap 4 tab', () {
    expect(seekerTabs.map((t) => t.label), [
      'Beranda',
      'Cari',
      'Pekerjaan',
      'Pesan',
    ]);
  });
}
