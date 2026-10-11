@extends('admin.layout')

@section('title', 'Ringkasan Sistem')
@section('header', 'Ringkasan Sistem & Operasional')

@section('content')
<div class="space-y-6">
    <!-- Stat Cards Grid -->
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
        <!-- Stat 1 -->
        <div class="bg-white p-5 rounded-xl border border-[#E2D9CC] shadow-sm">
            <div class="text-xs font-medium text-[#5A5146] uppercase tracking-wider">Menunggu Verifikasi KTP</div>
            <div class="mt-2 flex items-baseline justify-between">
                <span class="text-3xl font-bold text-[#1F1B16]">{{ $stats['pending_verifications'] }}</span>
                @if($stats['pending_verifications'] > 0)
                    <span class="text-xs font-semibold px-2 py-1 bg-[#F8E9DC] text-[#9A4E1C] rounded-md">Perlu Ditinjau</span>
                @else
                    <span class="text-xs font-semibold px-2 py-1 bg-[#E3F2EA] text-[#1B6E45] rounded-md">Semua Selesai</span>
                @endif
            </div>
            <a href="{{ route('admin.verifications.index') }}" class="mt-3 inline-block text-xs font-medium text-[#244C7C] hover:underline">
                Buka antrean verifikasi &rarr;
            </a>
        </div>

        <!-- Stat 2 -->
        <div class="bg-white p-5 rounded-xl border border-[#E2D9CC] shadow-sm">
            <div class="text-xs font-medium text-[#5A5146] uppercase tracking-wider">Dana Escrow Ditahan Aman</div>
            <div class="mt-2 flex items-baseline justify-between">
                <span class="text-2xl font-bold text-[#1F1B16] font-mono">
                    Rp{{ number_format($stats['escrow_held'], 0, ',', '.') }}
                </span>
                <span class="text-xs font-semibold px-2 py-1 bg-[#E4ECF7] text-[#244C7C] rounded-md">Escrow Aktif</span>
            </div>
            <p class="mt-3 text-xs text-[#5A5146]">Aman tertahan sampai konfirmasi pekerjaan selesai</p>
        </div>

        <!-- Stat 3 -->
        <div class="bg-white p-5 rounded-xl border border-[#E2D9CC] shadow-sm">
            <div class="text-xs font-medium text-[#5A5146] uppercase tracking-wider">Sengketa / Laporan Terbuka</div>
            <div class="mt-2 flex items-baseline justify-between">
                <span class="text-3xl font-bold text-[#1F1B16]">{{ $stats['open_disputes'] }}</span>
                @if($stats['open_disputes'] > 0)
                    <span class="text-xs font-semibold px-2 py-1 bg-[#FBE5E3] text-[#B3261E] rounded-md">Butuh Mediasi</span>
                @else
                    <span class="text-xs font-semibold px-2 py-1 bg-[#E3F2EA] text-[#1B6E45] rounded-md">Tidak Ada</span>
                @endif
            </div>
            <a href="{{ route('admin.reports.index') }}" class="mt-3 inline-block text-xs font-medium text-[#244C7C] hover:underline">
                Kelola sengketa &rarr;
            </a>
        </div>

        <!-- Stat 4 -->
        <div class="bg-white p-5 rounded-xl border border-[#E2D9CC] shadow-sm">
            <div class="text-xs font-medium text-[#5A5146] uppercase tracking-wider">Total Pengguna Terdaftar</div>
            <div class="mt-2 text-3xl font-bold text-[#1F1B16]">{{ $stats['total_users'] }}</div>
            <p class="mt-3 text-xs text-[#5A5146]">Pencari majikan & asisten terdaftar</p>
        </div>

        <!-- Stat 5 -->
        <div class="bg-white p-5 rounded-xl border border-[#E2D9CC] shadow-sm">
            <div class="text-xs font-medium text-[#5A5146] uppercase tracking-wider">Lowongan Tayang Aktif</div>
            <div class="mt-2 text-3xl font-bold text-[#1F1B16]">{{ $stats['open_listings'] }}</div>
            <p class="mt-3 text-xs text-[#5A5146]">Lowongan siap dilamar di aplikasi mobile</p>
        </div>

        <!-- Stat 6 -->
        <div class="bg-white p-5 rounded-xl border border-[#E2D9CC] shadow-sm">
            <div class="text-xs font-medium text-[#5A5146] uppercase tracking-wider">Kontrak Sedang Berjalan</div>
            <div class="mt-2 text-3xl font-bold text-[#1F1B16]">{{ $stats['active_bookings'] }}</div>
            <p class="mt-3 text-xs text-[#5A5146]">Pekerjaan yang telah disepakati kedua pihak</p>
        </div>
    </div>

    <!-- Pending Verifications Table -->
    <div class="bg-white rounded-xl border border-[#E2D9CC] shadow-sm overflow-hidden">
        <div class="px-6 py-4 border-b border-[#E2D9CC] flex items-center justify-between">
            <div>
                <h3 class="text-base font-semibold text-[#1F1B16]">Antrean Verifikasi KTP Terbaru</h3>
                <p class="text-xs text-[#5A5146]">Periksa KTP dan foto selfie untuk menjaga keamanan platform</p>
            </div>
            <a href="{{ route('admin.verifications.index') }}" class="text-xs font-medium text-[#244C7C] hover:underline">
                Lihat Semua &rarr;
            </a>
        </div>

        @if($recentVerifications->isEmpty())
            <div class="p-8 text-center text-[#5A5146] text-sm">
                Tidak ada pengajuan verifikasi yang tertunda saat ini.
            </div>
        @else
            <div class="overflow-x-auto">
                <table class="w-full text-left text-sm text-[#1F1B16]">
                    <thead class="bg-[#FAF7F2] text-xs uppercase font-medium text-[#5A5146] border-b border-[#E2D9CC]">
                        <tr>
                            <th class="px-6 py-3">Nama Pemohon</th>
                            <th class="px-6 py-3">Peran Aktif</th>
                            <th class="px-6 py-3">NIK</th>
                            <th class="px-6 py-3">Waktu Diajukan</th>
                            <th class="px-6 py-3 text-right">Aksi</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-[#E2D9CC]">
                        @foreach($recentVerifications as $verif)
                            <tr class="hover:bg-[#FAF7F2]/50 transition-colors">
                                <td class="px-6 py-4 font-medium">{{ $verif->user->name }}</td>
                                <td class="px-6 py-4">
                                    <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium {{ $verif->user->active_role === 'assistant' ? 'bg-[#F8E9DC] text-[#9A4E1C]' : 'bg-[#E4ECF7] text-[#244C7C]' }}">
                                        {{ $verif->user->active_role === 'assistant' ? 'Asisten' : 'Pencari' }}
                                    </span>
                                </td>
                                <td class="px-6 py-4 font-mono text-xs">{{ $verif->nik }}</td>
                                <td class="px-6 py-4 text-xs text-[#5A5146]">{{ $verif->created_at->diffForHumans() }}</td>
                                <td class="px-6 py-4 text-right">
                                    <a href="{{ route('admin.verifications.show', $verif->id) }}" 
                                       class="inline-flex items-center px-3 py-1.5 rounded-lg bg-[#244C7C] text-white text-xs font-medium hover:bg-[#1a385c] transition-colors">
                                        Tinjau Berkas &rarr;
                                    </a>
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        @endif
    </div>
</div>
@endsection
