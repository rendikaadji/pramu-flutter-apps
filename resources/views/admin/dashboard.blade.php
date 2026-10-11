@extends('admin.layout')

@section('title', 'Beranda Utama & Operasional')
@section('header', 'Beranda Utama')

@section('content')
<div class="space-y-6">

    <!-- Sapaan & Ringkasan Hari Ini -->
    <div class="bg-white rounded-2xl border border-[#E2D9CC] p-6 shadow-xs flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
            <div class="flex items-center gap-2">
                <span class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-[#E3F2EA] text-[#1B6E45]">
                    <span class="w-1.5 h-1.5 rounded-full bg-[#1B6E45]"></span>
                    Operasional Berjalan Lancar
                </span>
                <span class="text-xs text-[#5A5146]">
                    {{ now()->translatedFormat('l, d F Y') }}
                </span>
            </div>
            <h2 class="mt-2 text-xl lg:text-2xl font-bold text-[#1F1B16] tracking-tight">
                Selamat Datang, Admin Pramu
            </h2>
            <p class="text-xs sm:text-sm text-[#5A5146] mt-1">
                Berikut rangkuman aktivitas tenaga kerja, penitipan gaji aman, dan antrean berkas yang memerlukan perhatian Anda hari ini.
            </p>
        </div>

        <div class="flex items-center gap-3">
            @if($stats['pending_verifications'] > 0)
                <a href="{{ route('admin.verifications.index') }}" 
                   class="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-[#244C7C] text-white text-xs font-semibold shadow-xs hover:bg-[#1a385c] transition-colors">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                    <span>Periksa KTP ({{ $stats['pending_verifications'] }})</span>
                </a>
            @else
                <span class="inline-flex items-center gap-1.5 px-3 py-2 rounded-xl bg-[#FAF7F2] border border-[#E2D9CC] text-xs font-medium text-[#1B6E45]">
                    <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                        <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
                    </svg>
                    Semua KTP Selesai Diperiksa
                </span>
            @endif
        </div>
    </div>

    <!-- Alert Khusus: Bila Ada Keluhan Pengguna Butuh Mediasi -->
    @if($stats['open_disputes'] > 0)
        <div class="p-4 bg-[#FBE5E3] border border-[#B3261E]/30 rounded-2xl flex items-center justify-between gap-4">
            <div class="flex items-center gap-3">
                <div class="w-9 h-9 rounded-xl bg-[#B3261E] text-white flex items-center justify-center flex-shrink-0 font-bold">
                    !
                </div>
                <div>
                    <h4 class="text-xs font-bold text-[#B3261E]">Ada {{ $stats['open_disputes'] }} Laporan Masalah Yang Membutuhkan Mediasi Admin</h4>
                    <p class="text-[11px] text-[#5A5146] mt-0.5">Segera tinjau kronologi kejadian untuk membantu penyelesaian yang adil bagi kedua belah pihak.</p>
                </div>
            </div>
            <a href="{{ route('admin.reports.index') }}" 
               class="px-3.5 py-1.5 bg-[#B3261E] text-white text-xs font-semibold rounded-lg hover:bg-[#8f1e18] transition-colors whitespace-nowrap">
                Buka Pusat Mediasi &rarr;
            </a>
        </div>
    @endif

    <!-- 4 Kartu Angka Kunci Operasional (1 Baris Rapi & Jelas) -->
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <!-- Kartu 1: Pengguna -->
        <div class="bg-white p-5 rounded-2xl border border-[#E2D9CC] shadow-xs hover:border-[#244C7C]/40 transition-colors">
            <div class="flex items-center justify-between">
                <span class="text-xs font-semibold text-[#5A5146] uppercase tracking-wider">Pengguna Terdaftar</span>
                <span class="w-8 h-8 rounded-lg bg-[#E4ECF7] text-[#244C7C] flex items-center justify-center">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"/></svg>
                </span>
            </div>
            <div class="mt-3 text-3xl font-extrabold text-[#1F1B16] font-mono tracking-tight">
                {{ $stats['total_users'] }}
            </div>
            <div class="mt-2 text-xs text-[#5A5146] flex items-center justify-between pt-2 border-t border-[#E2D9CC]/50">
                <span>{{ $stats['total_assistants'] }} Asisten</span>
                <span class="text-[#8C8070]">&bull;</span>
                <span>{{ $stats['total_seekers'] }} Majikan</span>
            </div>
        </div>

        <!-- Kartu 2: Uang Titipan Gaji Aman (Escrow) -->
        <div class="bg-white p-5 rounded-2xl border border-[#E2D9CC] shadow-xs hover:border-[#244C7C]/40 transition-colors">
            <div class="flex items-center justify-between">
                <span class="text-xs font-semibold text-[#5A5146] uppercase tracking-wider">Titipan Gaji Aman</span>
                <span class="w-8 h-8 rounded-lg bg-[#E3F2EA] text-[#1B6E45] flex items-center justify-center">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"/></svg>
                </span>
            </div>
            <div class="mt-3 text-2xl font-extrabold text-[#1B6E45] font-mono tracking-tight">
                Rp{{ number_format($stats['escrow_held'], 0, ',', '.') }}
            </div>
            <div class="mt-2 text-xs text-[#5A5146] pt-2 border-t border-[#E2D9CC]/50">
                Tertahan aman sampai pekerjaan selesai
            </div>
        </div>

        <!-- Kartu 3: Lowongan Kerja Tayang -->
        <div class="bg-white p-5 rounded-2xl border border-[#E2D9CC] shadow-xs hover:border-[#244C7C]/40 transition-colors">
            <div class="flex items-center justify-between">
                <span class="text-xs font-semibold text-[#5A5146] uppercase tracking-wider">Lowongan Tayang</span>
                <span class="w-8 h-8 rounded-lg bg-[#FAF7F2] text-[#9A4E1C] flex items-center justify-center border border-[#E2D9CC]">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"/></svg>
                </span>
            </div>
            <div class="mt-3 text-3xl font-extrabold text-[#1F1B16] font-mono tracking-tight">
                {{ $stats['open_listings'] }}
            </div>
            <div class="mt-2 text-xs text-[#5A5146] pt-2 border-t border-[#E2D9CC]/50">
                Siap dilamar oleh calon asisten
            </div>
        </div>

        <!-- Kartu 4: Kontrak Kerja Sedang Berjalan -->
        <div class="bg-white p-5 rounded-2xl border border-[#E2D9CC] shadow-xs hover:border-[#244C7C]/40 transition-colors">
            <div class="flex items-center justify-between">
                <span class="text-xs font-semibold text-[#5A5146] uppercase tracking-wider">Pekerjaan Berjalan</span>
                <span class="w-8 h-8 rounded-lg bg-[#FAF7F2] text-[#1F1B16] flex items-center justify-center border border-[#E2D9CC]">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4"/></svg>
                </span>
            </div>
            <div class="mt-3 text-3xl font-extrabold text-[#1F1B16] font-mono tracking-tight">
                {{ $stats['active_bookings'] }}
            </div>
            <div class="mt-2 text-xs text-[#5A5146] pt-2 border-t border-[#E2D9CC]/50">
                Kontrak kerja resmi kedua belah pihak
            </div>
        </div>
    </div>

    <!-- Konten Utama: 2 Kolom Seimbang & Produktif -->
    <div class="grid grid-cols-1 lg:grid-cols-12 gap-6">

        <!-- Kolom Kiri: Tugas Utama Admin (8 Kolom) -->
        <div class="lg:col-span-8 space-y-6">

            <!-- Blok 1: Antrean Pemeriksaan KTP (Prioritas Kerja Hari Ini) -->
            <div class="bg-white rounded-2xl border border-[#E2D9CC] shadow-xs overflow-hidden">
                <div class="px-6 py-4 border-b border-[#E2D9CC] flex items-center justify-between">
                    <div>
                        <h3 class="text-sm font-bold text-[#1F1B16] uppercase tracking-wide">
                            Pemeriksaan Berkas KTP Terbaru
                        </h3>
                        <p class="text-xs text-[#5A5146] mt-0.5">
                            Pastikan data calon asisten dan majikan sesuai identitas asli
                        </p>
                    </div>
                    <a href="{{ route('admin.verifications.index') }}" class="text-xs font-semibold text-[#244C7C] hover:underline">
                        Lihat Semua Antrean &rarr;
                    </a>
                </div>

                @if($pendingVerifications->isEmpty())
                    <div class="p-8 text-center">
                        <div class="w-12 h-12 rounded-full bg-[#E3F2EA] text-[#1B6E45] flex items-center justify-center mx-auto mb-3">
                            <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 20 20">
                                <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
                            </svg>
                        </div>
                        <h4 class="text-sm font-bold text-[#1F1B16]">Tidak Ada Antrean Verifikasi</h4>
                        <p class="text-xs text-[#5A5146] mt-1 max-w-sm mx-auto">
                            Semua pengajuan KTP calon asisten dan majikan telah selesai diperiksa. Platform dalam kondisi tertib dan aman.
                        </p>
                    </div>
                @else
                    <div class="divide-y divide-[#E2D9CC]/60">
                        @foreach($pendingVerifications as $verif)
                            <div class="p-5 flex flex-col sm:flex-row sm:items-center justify-between gap-4 hover:bg-[#FAF7F2]/50 transition-colors">
                                <div class="flex items-center gap-3.5">
                                    <div class="w-10 h-10 rounded-full bg-[#244C7C] text-white flex items-center justify-center font-bold text-sm shadow-xs">
                                        {{ strtoupper(substr($verif->user->name, 0, 1)) }}
                                    </div>
                                    <div>
                                        <div class="flex items-center gap-2">
                                            <span class="text-sm font-bold text-[#1F1B16]">{{ $verif->user->name }}</span>
                                            <span class="px-2 py-0.5 rounded text-[10px] font-semibold {{ $verif->user->active_role === 'assistant' ? 'bg-[#F8E9DC] text-[#9A4E1C]' : 'bg-[#E4ECF7] text-[#244C7C]' }}">
                                                {{ $verif->user->active_role === 'assistant' ? 'Calon Asisten' : 'Majikan' }}
                                            </span>
                                        </div>
                                        <div class="text-xs text-[#5A5146] font-mono mt-0.5">
                                            NIK: {{ substr($verif->nik, 0, 6) }}****** &bull; Diajukan {{ $verif->created_at->diffForHumans() }}
                                        </div>
                                    </div>
                                </div>

                                <div class="flex items-center gap-2.5 self-end sm:self-center">
                                    <a href="{{ route('admin.verifications.show', $verif->id) }}" 
                                       class="px-3 py-1.5 rounded-lg border border-[#E2D9CC] bg-white text-xs font-semibold text-[#1F1B16] hover:bg-[#FAF7F2] transition-colors">
                                        Tinjau Berkas
                                    </a>
                                    <form action="{{ route('admin.verifications.approve', $verif->id) }}" method="POST" class="inline">
                                        @csrf
                                        <button type="submit" 
                                                onclick="return confirm('Konfirmasi persetujuan KTP atas nama {{ $verif->user->name }}?')"
                                                class="px-3.5 py-1.5 rounded-lg bg-[#1B6E45] text-white text-xs font-semibold hover:bg-[#155434] transition-colors">
                                            Setujui &check;
                                        </button>
                                    </form>
                                </div>
                            </div>
                        @endforeach
                    </div>
                @endif
            </div>

            <!-- Blok 2: Kontrak Kerja Sedang Berjalan -->
            <div class="bg-white rounded-2xl border border-[#E2D9CC] shadow-xs overflow-hidden">
                <div class="px-6 py-4 border-b border-[#E2D9CC] flex items-center justify-between">
                    <div>
                        <h3 class="text-sm font-bold text-[#1F1B16] uppercase tracking-wide">
                            Pekerjaan & Kontrak Sedang Berjalan
                        </h3>
                        <p class="text-xs text-[#5A5146] mt-0.5">
                            Pantau tenaga kerja yang sedang aktif bertugas di rumah majikan
                        </p>
                    </div>
                    <a href="{{ route('admin.bookings.index') }}" class="text-xs font-semibold text-[#244C7C] hover:underline">
                        Lihat Semua Kontrak &rarr;
                    </a>
                </div>

                @if($activeBookings->isEmpty())
                    <div class="p-8 text-center text-xs text-[#5A5146]">
                        Belum ada pekerjaan aktif yang sedang berjalan saat ini.
                    </div>
                @else
                    <div class="overflow-x-auto">
                        <table class="w-full text-left text-xs text-[#1F1B16]">
                            <thead class="bg-[#FAF7F2] uppercase font-semibold text-[#5A5146] border-b border-[#E2D9CC]">
                                <tr>
                                    <th class="px-6 py-3.5">Pihak Terlibat</th>
                                    <th class="px-6 py-3.5">Jenis Pekerjaan</th>
                                    <th class="px-6 py-3.5">Gaji Bulanan</th>
                                    <th class="px-6 py-3.5">Termin</th>
                                    <th class="px-6 py-3.5 text-right">Status</th>
                                </tr>
                            </thead>
                            <tbody class="divide-y divide-[#E2D9CC]/60">
                                @foreach($activeBookings as $b)
                                    <tr class="hover:bg-[#FAF7F2]/40 transition-colors">
                                        <td class="px-6 py-4">
                                            <div class="font-bold text-[#1F1B16]">{{ $b->seeker?->name ?? 'Majikan' }}</div>
                                            <div class="text-[11px] text-[#5A5146]">Asisten: {{ $b->assistant?->name ?? 'Asisten' }}</div>
                                        </td>
                                        <td class="px-6 py-4">
                                            <span class="inline-flex items-center px-2 py-0.5 rounded text-[11px] font-medium bg-[#FAF7F2] text-[#244C7C] border border-[#E2D9CC]">
                                                {{ $b->listing?->category?->name ?? 'Layanan Rumah Tangga' }}
                                            </span>
                                        </td>
                                        <td class="px-6 py-4 font-mono font-bold text-[#1F1B16]">
                                            Rp{{ number_format($b->total_agreed_rate, 0, ',', '.') }}
                                        </td>
                                        <td class="px-6 py-4 font-mono text-[11px] text-[#5A5146]">
                                            {{ $b->periods?->count() ?? 1 }} Periode
                                        </td>
                                        <td class="px-6 py-4 text-right">
                                            <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-[#E3F2EA] text-[#1B6E45]">
                                                AKTIF
                                            </span>
                                        </td>
                                    </tr>
                                @endforeach
                            </tbody>
                        </table>
                    </div>
                @endif
            </div>

        </div>

        <!-- Kolom Kanan: Agenda Wawancara & Ringkasan Produktivitas (4 Kolom) -->
        <div class="lg:col-span-4 space-y-6">

            <!-- Blok 3: Wawancara Online Terdekat (Google Meet) -->
            <div class="bg-white rounded-2xl border border-[#E2D9CC] shadow-xs p-5 space-y-4">
                <div class="flex items-center justify-between pb-3 border-b border-[#E2D9CC]">
                    <div>
                        <h3 class="text-sm font-bold text-[#1F1B16] uppercase tracking-wide">
                            Wawancara Terdekat
                        </h3>
                        <p class="text-[11px] text-[#5A5146]">Pertemuan calon pekerja & majikan</p>
                    </div>
                    <a href="{{ route('admin.interviews.index') }}" class="text-xs font-semibold text-[#244C7C] hover:underline">
                        Semua &rarr;
                    </a>
                </div>

                @if($upcomingInterviews->isEmpty())
                    <div class="p-6 text-center text-xs text-[#5A5146] bg-[#FAF7F2] rounded-xl border border-dashed border-[#E2D9CC]">
                        Belum ada jadwal wawancara hari ini.
                    </div>
                @else
                    <div class="space-y-3">
                        @foreach($upcomingInterviews->take(3) as $interview)
                            <div class="p-3.5 rounded-xl border border-[#E2D9CC] bg-[#FAF7F2]">
                                <div class="flex items-start justify-between gap-2">
                                    <div>
                                        <div class="text-xs font-bold text-[#1F1B16]">
                                            {{ $interview->application?->user?->name ?? 'Kandidat Asisten' }}
                                        </div>
                                        <div class="text-[11px] text-[#5A5146]">
                                            Majikan: {{ $interview->application?->listing?->user?->name ?? 'Majikan' }}
                                        </div>
                                    </div>
                                    <span class="px-2 py-0.5 rounded text-[10px] font-semibold bg-[#E4ECF7] text-[#244C7C]">
                                        {{ $interview->scheduled_at ? $interview->scheduled_at->format('H:i') . ' WIB' : 'Segera' }}
                                    </span>
                                </div>

                                <div class="mt-3 flex items-center justify-between pt-2 border-t border-[#E2D9CC]/60 text-xs">
                                    <span class="text-[11px] text-[#5A5146] font-mono">
                                        {{ $interview->scheduled_at ? $interview->scheduled_at->format('d M Y') : '-' }}
                                    </span>
                                    @if($interview->meeting_link)
                                        <a href="{{ $interview->meeting_link }}" target="_blank" rel="noopener noreferrer"
                                           class="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg bg-[#1B6E45] text-white text-[11px] font-semibold hover:bg-[#155434] transition-colors">
                                            <span>Masuk Wawancara</span>
                                            <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
                                            </svg>
                                        </a>
                                    @else
                                        <span class="text-[11px] text-[#8C8070] italic">Menunggu link</span>
                                    @endif
                                </div>
                            </div>
                        @endforeach
                    </div>
                @endif
            </div>

            <!-- Blok 4: Transparansi Dana & Hak Asisten -->
            <div class="bg-white rounded-2xl border border-[#E2D9CC] shadow-xs p-5 space-y-4">
                <div class="pb-3 border-b border-[#E2D9CC] flex items-center justify-between">
                    <div>
                        <h3 class="text-sm font-bold text-[#1F1B16] uppercase tracking-wide">
                            Pencairan & Bagi Hasil
                        </h3>
                        <p class="text-[11px] text-[#5A5146]">Pengawasan hak upah pekerja</p>
                    </div>
                    <a href="{{ route('admin.finances.index') }}" class="text-xs font-semibold text-[#244C7C] hover:underline">
                        Rincian &rarr;
                    </a>
                </div>

                <div class="space-y-3 text-xs">
                    <div class="p-3.5 bg-[#FAF7F2] rounded-xl border border-[#E2D9CC]/70">
                        <div class="text-[11px] text-[#5A5146]">Total Gaji Sukses Dicairkan ke Asisten</div>
                        <div class="text-xl font-bold font-mono text-[#1B6E45] mt-1">
                            Rp{{ number_format($stats['escrow_settled'], 0, ',', '.') }}
                        </div>
                    </div>

                    <div class="p-3.5 bg-[#FAF7F2] rounded-xl border border-[#E2D9CC]/70">
                        <div class="text-[11px] text-[#5A5146]">Pendapatan Jasa Platform (10%)</div>
                        <div class="text-xl font-bold font-mono text-[#9A4E1C] mt-1">
                            Rp{{ number_format($stats['platform_fees'], 0, ',', '.') }}
                        </div>
                    </div>
                </div>

                <p class="text-[11px] text-[#5A5146] pt-1">
                    Seluruh pencairan dana upah langsung ditransfer ke rekening bank asisten tanpa potongan tersembunyi.
                </p>
            </div>

            <!-- Blok 5: Kategori Layanan Paling Banyak Dicari -->
            <div class="bg-white rounded-2xl border border-[#E2D9CC] shadow-xs p-5 space-y-4">
                <div class="pb-3 border-b border-[#E2D9CC]">
                    <h3 class="text-sm font-bold text-[#1F1B16] uppercase tracking-wide">
                        Layanan Paling Diminati
                    </h3>
                    <p class="text-[11px] text-[#5A5146]">Jumlah permintaan lowongan majikan</p>
                </div>

                <div class="space-y-3.5 text-xs">
                    @forelse($categories as $category)
                        @php
                            $catTotal = max($stats['open_listings'], 1);
                            $percentage = min(100, round(($category->listings_count / $catTotal) * 100));
                        @endphp
                        <div>
                            <div class="flex justify-between items-center mb-1">
                                <span class="font-semibold text-[#1F1B16]">{{ $category->name }}</span>
                                <span class="text-[#5A5146] font-mono text-[11px]">
                                    <strong>{{ $category->listings_count }}</strong> lowongan
                                </span>
                            </div>
                            <div class="w-full bg-[#EAE4DC] h-1.5 rounded-full overflow-hidden">
                                <div class="bg-[#244C7C] h-full rounded-full transition-all duration-300" 
                                     style="width: {{ max(10, $percentage) }}%"></div>
                            </div>
                        </div>
                    @empty
                        <div class="text-xs text-[#5A5146]">Belum ada kategori data.</div>
                    @endforelse
                </div>
            </div>

        </div>

    </div>

</div>
@endsection
