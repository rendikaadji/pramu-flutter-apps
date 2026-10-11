@extends('admin.layout')

@section('title', 'Beranda Utama & Operasional')
@section('header', 'Beranda Utama')

@section('content')
<div class="space-y-8">

    <!-- Header Halaman Bersih & Bernafas -->
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-2 border-b border-[#E2D9CC]/60">
        <div>
            <div class="flex items-center gap-2.5">
                <span class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-[#E3F2EA] text-[#1B6E45]">
                    <span class="w-1.5 h-1.5 rounded-full bg-[#1B6E45] animate-pulse"></span>
                    Sistem Operasional Normal
                </span>
                <span class="text-xs text-[#5A5146]">
                    {{ now()->translatedFormat('l, d F Y') }}
                </span>
            </div>
            <h1 class="text-2xl font-bold text-[#1F1B16] tracking-tight mt-1.5">
                Beranda Operasional
            </h1>
            <p class="text-xs sm:text-sm text-[#5A5146] mt-0.5">
                Pantau verifikasi identitas, jadwal wawancara, dan pekerjaan tenaga kerja secara real-time.
            </p>
        </div>

        <div class="flex items-center gap-2.5">
            @if($stats['pending_verifications'] > 0)
                <a href="{{ route('admin.verifications.index') }}" 
                   class="inline-flex items-center gap-2 px-3.5 py-2 rounded-xl bg-[#244C7C] text-white text-xs font-semibold shadow-2xs hover:bg-[#1a385c] transition-colors">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                    <span>Ada {{ $stats['pending_verifications'] }} KTP Menunggu Diperiksa</span>
                </a>
            @else
                <span class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-[#FAF7F2] border border-[#E2D9CC] text-xs font-medium text-[#1B6E45]">
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
        <div class="p-4 bg-[#FBE5E3] border border-[#B3261E]/30 rounded-2xl flex flex-col sm:flex-row sm:items-center justify-between gap-3 shadow-2xs">
            <div class="flex items-center gap-3">
                <div class="w-9 h-9 rounded-xl bg-[#B3261E] text-white flex items-center justify-center flex-shrink-0 font-bold text-sm">
                    !
                </div>
                <div>
                    <h4 class="text-xs font-bold text-[#B3261E]">Perhatian: Ada {{ $stats['open_disputes'] }} Laporan Keluhan Menunggu Mediasi Admin</h4>
                    <p class="text-[11px] text-[#5A5146] mt-0.5">Tinjau kronologi masalah untuk membantu penyelesaian yang adil bagi majikan dan asisten.</p>
                </div>
            </div>
            <a href="{{ route('admin.reports.index') }}" 
               class="px-3.5 py-1.5 bg-[#B3261E] text-white text-xs font-semibold rounded-lg hover:bg-[#8f1e18] transition-colors whitespace-nowrap self-end sm:self-auto">
                Buka Pusat Mediasi &rarr;
            </a>
        </div>
    @endif

    <!-- 4 Kartu Metrik Utama Interaktif: Bisa Diklik Langsung untuk Masuk ke Halaman Terkait -->
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
        <!-- Metrik 1: Pengguna -->
        <a href="{{ route('admin.users.index') }}" 
           class="bg-white p-6 rounded-2xl border border-[#E2D9CC] shadow-2xs flex flex-col justify-between hover:border-[#244C7C] hover:shadow-xs transition-all duration-200 group">
            <div>
                <div class="flex items-center justify-between text-xs text-[#5A5146] font-semibold uppercase tracking-wider">
                    <span>Pengguna Terdaftar</span>
                    <span class="w-7 h-7 rounded-lg bg-[#E4ECF7] text-[#244C7C] flex items-center justify-center group-hover:bg-[#244C7C] group-hover:text-white transition-colors">
                        <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"/></svg>
                    </span>
                </div>
                <div class="mt-3 text-3xl font-extrabold text-[#1F1B16] font-mono tracking-tight">
                    {{ $stats['total_users'] }}
                </div>
            </div>
            <div class="mt-4 text-xs text-[#5A5146] flex items-center justify-between pt-2 border-t border-[#E2D9CC]/50">
                <span>{{ $stats['total_assistants'] }} Asisten &bull; {{ $stats['total_seekers'] }} Majikan</span>
                <span class="text-[#244C7C] font-semibold group-hover:translate-x-0.5 transition-transform">&rarr;</span>
            </div>
        </a>

        <!-- Metrik 2: Uang Titipan Gaji Aman (Escrow) -->
        <a href="{{ route('admin.finances.index') }}" 
           class="bg-white p-6 rounded-2xl border border-[#E2D9CC] shadow-2xs flex flex-col justify-between hover:border-[#1B6E45] hover:shadow-xs transition-all duration-200 group">
            <div>
                <div class="flex items-center justify-between text-xs text-[#5A5146] font-semibold uppercase tracking-wider">
                    <span>Titipan Gaji Aman</span>
                    <span class="w-7 h-7 rounded-lg bg-[#E3F2EA] text-[#1B6E45] flex items-center justify-center group-hover:bg-[#1B6E45] group-hover:text-white transition-colors">
                        <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"/></svg>
                    </span>
                </div>
                <div class="mt-3 text-2xl font-extrabold text-[#1B6E45] font-mono tracking-tight">
                    Rp{{ number_format($stats['escrow_held'], 0, ',', '.') }}
                </div>
            </div>
            <div class="mt-4 text-xs text-[#5A5146] flex items-center justify-between pt-2 border-t border-[#E2D9CC]/50">
                <span>Tertahan aman di rekening resmi</span>
                <span class="text-[#1B6E45] font-semibold group-hover:translate-x-0.5 transition-transform">&rarr;</span>
            </div>
        </a>

        <!-- Metrik 3: Lowongan Kerja Tayang -->
        <a href="{{ route('admin.listings.index') }}" 
           class="bg-white p-6 rounded-2xl border border-[#E2D9CC] shadow-2xs flex flex-col justify-between hover:border-[#9A4E1C] hover:shadow-xs transition-all duration-200 group">
            <div>
                <div class="flex items-center justify-between text-xs text-[#5A5146] font-semibold uppercase tracking-wider">
                    <span>Lowongan Tayang</span>
                    <span class="w-7 h-7 rounded-lg bg-[#FAF7F2] text-[#9A4E1C] flex items-center justify-center border border-[#E2D9CC] group-hover:bg-[#9A4E1C] group-hover:text-white group-hover:border-[#9A4E1C] transition-colors">
                        <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"/></svg>
                    </span>
                </div>
                <div class="mt-3 text-3xl font-extrabold text-[#1F1B16] font-mono tracking-tight">
                    {{ $stats['open_listings'] }}
                </div>
            </div>
            <div class="mt-4 text-xs text-[#5A5146] flex items-center justify-between pt-2 border-t border-[#E2D9CC]/50">
                <span>Siap dilamar oleh para asisten</span>
                <span class="text-[#9A4E1C] font-semibold group-hover:translate-x-0.5 transition-transform">&rarr;</span>
            </div>
        </a>

        <!-- Metrik 4: Kontrak Kerja Sedang Berjalan -->
        <a href="{{ route('admin.bookings.index') }}" 
           class="bg-white p-6 rounded-2xl border border-[#E2D9CC] shadow-2xs flex flex-col justify-between hover:border-[#1F1B16] hover:shadow-xs transition-all duration-200 group">
            <div>
                <div class="flex items-center justify-between text-xs text-[#5A5146] font-semibold uppercase tracking-wider">
                    <span>Pekerjaan Berjalan</span>
                    <span class="w-7 h-7 rounded-lg bg-[#FAF7F2] text-[#1F1B16] flex items-center justify-center border border-[#E2D9CC] group-hover:bg-[#1F1B16] group-hover:text-white group-hover:border-[#1F1B16] transition-colors">
                        <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4"/></svg>
                    </span>
                </div>
                <div class="mt-3 text-3xl font-extrabold text-[#1F1B16] font-mono tracking-tight">
                    {{ $stats['active_bookings'] }}
                </div>
            </div>
            <div class="mt-4 text-xs text-[#5A5146] flex items-center justify-between pt-2 border-t border-[#E2D9CC]/50">
                <span>Kontrak kerja resmi aktif</span>
                <span class="text-[#1F1B16] font-semibold group-hover:translate-x-0.5 transition-transform">&rarr;</span>
            </div>
        </a>
    </div>

    <!-- SEKSI 1: Dua Modul Tugas & Agenda Hari Ini (Grid 2 Kolom Seimbang: 6 & 6) -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 items-start">

        <!-- Modul A: Antrean Pemeriksaan KTP (Aksi Cepat Admin) -->
        <div class="bg-white rounded-2xl border border-[#E2D9CC] shadow-2xs overflow-hidden flex flex-col justify-between">
            <div>
                <div class="px-6 py-4.5 border-b border-[#E2D9CC] flex items-center justify-between">
                    <div>
                        <h2 class="text-sm font-bold text-[#1F1B16] uppercase tracking-wide">
                            Pemeriksaan Berkas KTP
                        </h2>
                        <p class="text-xs text-[#5A5146] mt-0.5">
                            Verifikasi identitas calon asisten dan majikan baru
                        </p>
                    </div>
                    <a href="{{ route('admin.verifications.index') }}" class="text-xs font-semibold text-[#244C7C] hover:underline">
                        Buka Semua Antrean &rarr;
                    </a>
                </div>

                @if($pendingVerifications->isEmpty())
                    <div class="p-8 text-center">
                        <div class="w-10 h-10 rounded-full bg-[#E3F2EA] text-[#1B6E45] flex items-center justify-center mx-auto mb-2.5">
                            <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                                <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
                            </svg>
                        </div>
                        <h4 class="text-xs font-bold text-[#1F1B16]">Semua Berkas Telah Diperiksa</h4>
                        <p class="text-xs text-[#5A5146] mt-1">Tidak ada pengajuan verifikasi KTP yang tertunda saat ini.</p>
                    </div>
                @else
                    <div class="divide-y divide-[#E2D9CC]/60">
                        @foreach($pendingVerifications->take(3) as $verif)
                            <div class="p-4 sm:p-5 flex items-center justify-between gap-3 hover:bg-[#FAF7F2]/50 transition-colors">
                                <div class="flex items-center gap-3 min-w-0">
                                    <div class="w-10 h-10 rounded-full bg-[#244C7C] text-white flex items-center justify-center font-bold text-xs flex-shrink-0 shadow-2xs">
                                        {{ strtoupper(substr($verif->user->name, 0, 1)) }}
                                    </div>
                                    <div class="min-w-0">
                                        <div class="flex items-center gap-2">
                                            <span class="text-xs font-bold text-[#1F1B16] truncate">{{ $verif->user->name }}</span>
                                            <span class="px-2 py-0.5 rounded text-[10px] font-semibold flex-shrink-0 {{ $verif->user->active_role === 'assistant' ? 'bg-[#F8E9DC] text-[#9A4E1C]' : 'bg-[#E4ECF7] text-[#244C7C]' }}">
                                                {{ $verif->user->active_role === 'assistant' ? 'Asisten' : 'Majikan' }}
                                            </span>
                                        </div>
                                        <div class="text-[11px] text-[#5A5146] font-mono mt-0.5">
                                            NIK: {{ substr($verif->nik, 0, 6) }}****** &bull; {{ $verif->created_at->diffForHumans() }}
                                        </div>
                                        <div class="flex items-center gap-2 mt-1 text-[10px] text-[#1B6E45] font-medium">
                                            <span class="inline-flex items-center gap-0.5">&check; Foto KTP</span>
                                            <span class="inline-flex items-center gap-0.5">&check; Foto Wajah Selfie</span>
                                        </div>
                                    </div>
                                </div>

                                <div class="flex items-center gap-2 flex-shrink-0">
                                    <a href="{{ route('admin.verifications.show', $verif->id) }}" 
                                       class="px-3 py-1.5 rounded-lg bg-[#FAF7F2] border border-[#E2D9CC] text-xs font-semibold text-[#244C7C] hover:bg-[#EAE4DC] transition-colors whitespace-nowrap">
                                        Tinjau
                                    </a>
                                    <form action="{{ route('admin.verifications.approve', $verif->id) }}" method="POST" class="inline">
                                        @csrf
                                        <button type="submit" 
                                                onclick="return confirm('Konfirmasi persetujuan KTP atas nama {{ $verif->user->name }}?')"
                                                class="px-3 py-1.5 rounded-lg bg-[#1B6E45] text-white text-xs font-semibold hover:bg-[#155434] transition-colors whitespace-nowrap">
                                            Setujui &check;
                                        </button>
                                    </form>
                                </div>
                            </div>
                        @endforeach
                    </div>
                @endif
            </div>

            <div class="px-6 py-3 bg-[#FAF7F2]/50 border-t border-[#E2D9CC]/60 text-xs text-[#5A5146] flex items-center justify-between">
                <span>Pemeriksaan berkas sesuai NIK Dukcapil</span>
                <span class="font-medium text-[#1F1B16]">{{ $stats['verified_users'] }} akun telah sah</span>
            </div>
        </div>

        <!-- Modul B: Jadwal Wawancara Online Hari Ini (Google Meet) -->
        <div class="bg-white rounded-2xl border border-[#E2D9CC] shadow-2xs overflow-hidden flex flex-col justify-between">
            <div>
                <div class="px-6 py-4.5 border-b border-[#E2D9CC] flex items-center justify-between">
                    <div>
                        <h2 class="text-sm font-bold text-[#1F1B16] uppercase tracking-wide">
                            Wawancara Online Terjadwal
                        </h2>
                        <p class="text-xs text-[#5A5146] mt-0.5">
                            Pertemuan tatap muka virtual calon pekerja & majikan
                        </p>
                    </div>
                    <a href="{{ route('admin.interviews.index') }}" class="text-xs font-semibold text-[#244C7C] hover:underline">
                        Semua Jadwal &rarr;
                    </a>
                </div>

                @if($upcomingInterviews->isEmpty())
                    <div class="p-8 text-center text-xs text-[#5A5146]">
                        <p>Belum ada jadwal wawancara aktif yang terdaftar hari ini.</p>
                    </div>
                @else
                    <div class="divide-y divide-[#E2D9CC]/60">
                        @foreach($upcomingInterviews->take(3) as $interview)
                            <div class="p-4 sm:p-5 flex items-center justify-between gap-3 hover:bg-[#FAF7F2]/50 transition-colors">
                                <div class="flex items-center gap-3 min-w-0">
                                    <div class="w-10 h-10 rounded-full bg-[#FAF7F2] border border-[#E2D9CC] text-[#244C7C] flex items-center justify-center font-bold text-xs flex-shrink-0">
                                        {{ strtoupper(substr($interview->application?->user?->name ?? 'A', 0, 1)) }}
                                    </div>
                                    <div class="min-w-0">
                                        <div class="flex items-center gap-2">
                                            <span class="text-xs font-bold text-[#1F1B16] truncate">
                                                {{ $interview->application?->user?->name ?? 'Kandidat Asisten' }}
                                            </span>
                                            <span class="text-[11px] text-[#5A5146] truncate">&bull; Majikan: {{ $interview->application?->listing?->user?->name ?? 'Majikan' }}</span>
                                        </div>
                                        <div class="text-[11px] text-[#5A5146] mt-0.5 truncate">
                                            {{ Str::limit($interview->application?->listing?->title ?? 'Pramu ART', 32) }}
                                        </div>
                                        <div class="text-[10px] text-[#8C8070] mt-0.5">
                                            Tanggal: {{ $interview->scheduled_at ? $interview->scheduled_at->format('d M Y') : '-' }}
                                        </div>
                                    </div>
                                </div>

                                <div class="flex items-center gap-2 flex-shrink-0">
                                    <span class="px-2.5 py-1 rounded-md text-[11px] font-mono font-semibold bg-[#E4ECF7] text-[#244C7C]">
                                        {{ $interview->scheduled_at ? $interview->scheduled_at->format('H:i') . ' WIB' : 'Segera' }}
                                    </span>
                                    @if($interview->meeting_link)
                                        <a href="{{ $interview->meeting_link }}" target="_blank" rel="noopener noreferrer" 
                                           class="px-3 py-1.5 rounded-lg bg-[#1B6E45] text-white text-xs font-semibold hover:bg-[#155434] transition-colors flex items-center gap-1.5 shadow-2xs">
                                            <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"/></svg>
                                            <span>Masuk Meet</span>
                                        </a>
                                    @endif
                                </div>
                            </div>
                        @endforeach
                    </div>
                @endif
            </div>

            <div class="px-6 py-3 bg-[#FAF7F2]/50 border-t border-[#E2D9CC]/60 text-xs text-[#5A5146] flex items-center justify-between">
                <span>Google Meet otomatis tersinkron</span>
                <span class="font-medium text-[#1F1B16]">{{ $upcomingInterviews->count() }} sesi terdaftar</span>
            </div>
        </div>

    </div>

    <!-- SEKSI 2: Transaksi Berjalan & Kategori Layanan (Grid 8 : 4) -->
    <div class="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">

        <!-- Tabel Kontrak Kerja Sedang Berjalan (8 Kolom) -->
        <div class="lg:col-span-8 bg-white rounded-2xl border border-[#E2D9CC] shadow-2xs overflow-hidden">
            <div class="px-6 py-4.5 border-b border-[#E2D9CC] flex items-center justify-between">
                <div>
                    <h2 class="text-sm font-bold text-[#1F1B16] uppercase tracking-wide">
                        Pekerjaan & Kontrak Sedang Berjalan
                    </h2>
                    <p class="text-xs text-[#5A5146] mt-0.5">
                        Pantau tenaga kerja yang sedang aktif bertugas di rumah majikan
                    </p>
                </div>
                <a href="{{ route('admin.bookings.index') }}" class="text-xs font-semibold text-[#244C7C] hover:underline">
                    Semua Kontrak &rarr;
                </a>
            </div>

            @if($activeBookings->isEmpty())
                <div class="p-8 text-center text-xs text-[#5A5146]">
                    Belum ada kontrak kerja aktif yang sedang berjalan saat ini.
                </div>
            @else
                <div class="overflow-x-auto">
                    <table class="w-full text-left text-xs text-[#1F1B16]">
                        <thead class="bg-[#FAF7F2] uppercase font-semibold text-[#5A5146] border-b border-[#E2D9CC]">
                            <tr>
                                <th class="px-6 py-3.5">Pihak Bekerja</th>
                                <th class="px-6 py-3.5">Layanan</th>
                                <th class="px-6 py-3.5">Gaji Bulanan</th>
                                <th class="px-6 py-3.5">Termin Escrow</th>
                                <th class="px-6 py-3.5 text-right">Status Kerja</th>
                            </tr>
                        </thead>
                        <tbody class="divide-y divide-[#E2D9CC]/60">
                            @foreach($activeBookings as $b)
                                <tr class="hover:bg-[#FAF7F2]/40 transition-colors">
                                    <td class="px-6 py-4">
                                        <div class="flex items-center gap-2">
                                            <span class="w-5 h-5 rounded-md bg-[#E4ECF7] text-[#244C7C] flex items-center justify-center font-bold text-[10px]">M</span>
                                            <span class="font-bold text-[#1F1B16] text-xs">{{ $b->seeker?->name ?? 'Majikan' }}</span>
                                        </div>
                                        <div class="flex items-center gap-2 mt-1 text-[11px] text-[#5A5146]">
                                            <span class="w-5 h-5 rounded-md bg-[#F8E9DC] text-[#9A4E1C] flex items-center justify-center font-bold text-[10px]">A</span>
                                            <span>Asisten: <strong>{{ $b->assistant?->name ?? 'Asisten' }}</strong></span>
                                        </div>
                                    </td>
                                    <td class="px-6 py-4">
                                        <span class="inline-flex items-center px-2.5 py-1 rounded-lg text-[11px] font-medium bg-[#FAF7F2] text-[#244C7C] border border-[#E2D9CC]">
                                            {{ $b->listing?->category?->name ?? 'Layanan Rumah Tangga' }}
                                        </span>
                                    </td>
                                    <td class="px-6 py-4">
                                        <div class="font-mono font-bold text-[#1F1B16] text-sm">
                                            Rp{{ number_format($b->total_agreed_rate, 0, ',', '.') }}
                                        </div>
                                        <span class="text-[10px] text-[#8C8070]">per bulan</span>
                                    </td>
                                    <td class="px-6 py-4">
                                        <span class="inline-flex items-center px-2 py-0.5 rounded text-[11px] font-mono bg-[#FAF7F2] border border-[#E2D9CC] text-[#1F1B16]">
                                            {{ $b->periods?->count() ?? 1 }} Periode
                                        </span>
                                    </td>
                                    <td class="px-6 py-4 text-right">
                                        <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[10px] font-semibold bg-[#E3F2EA] text-[#1B6E45]">
                                            <span class="w-1.5 h-1.5 rounded-full bg-[#1B6E45]"></span>
                                            Sedang Bertugas
                                        </span>
                                    </td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            @endif
        </div>

        <!-- Kolom Kanan: Keuangan & Kategori Layanan (4 Kolom) -->
        <div class="lg:col-span-4 space-y-6">

            <!-- Card 1: Ringkasan Pencairan Gaji & Bagi Hasil -->
            <div class="bg-white rounded-2xl border border-[#E2D9CC] shadow-2xs p-6 space-y-4">
                <div class="pb-3 border-b border-[#E2D9CC] flex items-center justify-between">
                    <div>
                        <h2 class="text-sm font-bold text-[#1F1B16] uppercase tracking-wide">
                            Pencairan & Bagi Hasil
                        </h2>
                        <p class="text-xs text-[#5A5146] mt-0.5">Pengawasan upah dan pendapatan platform</p>
                    </div>
                    <a href="{{ route('admin.finances.index') }}" class="text-xs font-semibold text-[#244C7C] hover:underline">
                        Rincian &rarr;
                    </a>
                </div>

                <div class="space-y-3.5">
                    <div class="p-3 bg-[#FAF7F2] rounded-xl border border-[#E2D9CC]/60">
                        <div class="text-[11px] text-[#5A5146] font-medium">Total Gaji Sukses Dicairkan ke Asisten:</div>
                        <div class="text-xl font-extrabold font-mono text-[#1B6E45] mt-1">
                            Rp{{ number_format($stats['escrow_settled'], 0, ',', '.') }}
                        </div>
                    </div>

                    <div class="p-3 bg-[#FAF7F2] rounded-xl border border-[#E2D9CC]/60">
                        <div class="text-[11px] text-[#5A5146] font-medium">Pendapatan Jasa Platform (10%):</div>
                        <div class="text-lg font-bold font-mono text-[#9A4E1C] mt-1">
                            Rp{{ number_format($stats['platform_fees'], 0, ',', '.') }}
                        </div>
                        <div class="text-[10px] text-[#8C8070] mt-0.5">5% dari majikan + 5% dari asisten</div>
                    </div>

                    <div class="p-3 bg-[#FAF7F2] rounded-xl border border-[#E2D9CC]/60">
                        <div class="text-[11px] text-[#5A5146] font-medium">Biaya Penayangan Lowongan:</div>
                        <div class="text-lg font-bold font-mono text-[#1F1B16] mt-1">
                            Rp{{ number_format($stats['listing_fees'], 0, ',', '.') }}
                        </div>
                        <div class="text-[10px] text-[#8C8070] mt-0.5">Rp25.000 per publikasi iklan</div>
                    </div>
                </div>

                <p class="text-[11px] text-[#5A5146] pt-1">
                    Seluruh pencairan upah ditransfer langsung ke rekening bank asisten tanpa potongan tersembunyi.
                </p>
            </div>

            <!-- Card 2: Kategori Layanan Paling Diminati -->
            <div class="bg-white rounded-2xl border border-[#E2D9CC] shadow-2xs p-6 space-y-4">
                <div class="pb-3 border-b border-[#E2D9CC]">
                    <h2 class="text-sm font-bold text-[#1F1B16] uppercase tracking-wide">
                        Layanan Paling Diminati
                    </h2>
                    <p class="text-xs text-[#5A5146] mt-0.5">Peringkat kebutuhan majikan saat ini</p>
                </div>

                <div class="space-y-4 text-xs">
                    @forelse($categories as $index => $category)
                        @php
                            $catTotal = max($stats['open_listings'], 1);
                            $percentage = min(100, round(($category->listings_count / $catTotal) * 100));
                        @endphp
                        <div>
                            <div class="flex justify-between items-center mb-1.5">
                                <span class="font-semibold text-[#1F1B16] flex items-center gap-1.5">
                                    <span class="w-4 h-4 rounded-full bg-[#EAE4DC] text-[#5A5146] text-[10px] font-bold flex items-center justify-center">{{ $index + 1 }}</span>
                                    <span>{{ $category->name }}</span>
                                </span>
                                <span class="text-[#5A5146] font-mono text-[11px]">
                                    <strong>{{ $category->listings_count }}</strong> lowongan
                                </span>
                            </div>
                            <div class="w-full bg-[#EAE4DC] h-2 rounded-full overflow-hidden">
                                <div class="bg-[#244C7C] h-full rounded-full transition-all duration-300" 
                                     style="width: {{ max(10, $percentage) }}%"></div>
                            </div>
                        </div>
                    @empty
                        <div class="text-xs text-[#5A5146]">Belum ada data kategori.</div>
                    @endforelse
                </div>
            </div>

        </div>

    </div>

</div>
@endsection
