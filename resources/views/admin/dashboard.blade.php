@extends('admin.layout')

@section('title', 'Beranda Utama & Operasional')

@section('content')
<div class="space-y-6">

    <!-- Top Welcome Header (Launchly Style) -->
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 text-white">
        <div>
            <h1 class="text-2xl sm:text-3xl font-extrabold tracking-tight flex items-center gap-2">
                Welcome back! <span class="text-2xl">👋</span>
            </h1>
            <p class="text-xs sm:text-sm text-cyan-100/80 mt-1">
                Pantau verifikasi identitas, jadwal wawancara online, dan pekerjaan tenaga kerja secara real-time.
            </p>
        </div>

        <div class="flex items-center gap-3">
            @if($stats['pending_verifications'] > 0)
                <a href="{{ route('admin.verifications.index') }}" 
                   class="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-[#FF6B35] hover:bg-[#E85926] text-white text-xs font-bold shadow-lg shadow-[#FF6B35]/30 transition-all">
                    <span>Ada {{ $stats['pending_verifications'] }} KTP Menunggu Diperiksa</span>
                    <span>&rarr;</span>
                </a>
            @else
                <span class="inline-flex items-center gap-2 px-3.5 py-2 rounded-xl bg-white/10 border border-white/15 text-xs font-semibold text-emerald-300 backdrop-blur-sm">
                    <span class="w-2 h-2 rounded-full bg-emerald-400"></span>
                    Semua KTP Selesai Diperiksa
                </span>
            @endif
        </div>
    </div>

    <!-- Alert Khusus: Bila Ada Keluhan Pengguna Butuh Mediasi -->
    @if($stats['open_disputes'] > 0)
        <div class="p-4 bg-rose-500/20 border border-rose-400/40 text-white rounded-2xl flex flex-col sm:flex-row sm:items-center justify-between gap-3 shadow-md backdrop-blur-sm">
            <div class="flex items-center gap-3">
                <div class="w-9 h-9 rounded-xl bg-rose-500 text-white flex items-center justify-center font-extrabold text-sm shrink-0 shadow-sm">
                    !
                </div>
                <div>
                    <h4 class="text-xs font-bold text-rose-100">Perhatian: Ada {{ $stats['open_disputes'] }} Laporan Keluhan Menunggu Mediasi Admin</h4>
                    <p class="text-[11px] text-rose-200/80 mt-0.5">Tinjau kronologi masalah untuk membantu penyelesaian yang adil bagi majikan dan asisten.</p>
                </div>
            </div>
            <a href="{{ route('admin.reports.index') }}" 
               class="px-3.5 py-1.5 bg-rose-500 hover:bg-rose-600 text-white text-xs font-bold rounded-xl transition-colors whitespace-nowrap self-end sm:self-auto shadow-sm">
                Buka Pusat Mediasi &rarr;
            </a>
        </div>
    @endif

    <!-- 4 Stat Cards Row (Launchly Style: Dark Translucent with Cyan Icon Box) -->
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <!-- Metric 1: Total Users -->
        <a href="{{ route('admin.users.index') }}" 
           class="bg-[#0B3559]/80 hover:bg-[#0B3559] border border-white/10 hover:border-cyan-400/30 rounded-2xl p-4.5 text-white shadow-md backdrop-blur-sm transition-all duration-200 flex items-start gap-3.5 group">
            <div class="w-11 h-11 rounded-xl bg-[#0284C7] flex items-center justify-center text-white shrink-0 shadow-md group-hover:scale-105 transition-transform">
                <!-- User Group Icon -->
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"/></svg>
            </div>
            <div class="flex-1 min-w-0">
                <div class="text-[11px] font-semibold text-cyan-200/80 uppercase tracking-wider">Pengguna Terdaftar</div>
                <div class="text-2xl font-extrabold text-white font-mono mt-0.5 tracking-tight">
                    {{ $stats['total_users'] }}
                </div>
                <div class="text-[11px] text-cyan-200/70 mt-1 truncate">
                    {{ $stats['total_assistants'] }} Asisten &bull; {{ $stats['total_seekers'] }} Majikan
                </div>
            </div>
        </a>

        <!-- Metric 2: Escrow Held -->
        <a href="{{ route('admin.finances.index') }}" 
           class="bg-[#0B3559]/80 hover:bg-[#0B3559] border border-white/10 hover:border-emerald-400/30 rounded-2xl p-4.5 text-white shadow-md backdrop-blur-sm transition-all duration-200 flex items-start gap-3.5 group">
            <div class="w-11 h-11 rounded-xl bg-[#059669] flex items-center justify-center text-white shrink-0 shadow-md group-hover:scale-105 transition-transform">
                <!-- Shield Lock Escrow Icon -->
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"/></svg>
            </div>
            <div class="flex-1 min-w-0">
                <div class="text-[11px] font-semibold text-emerald-200/80 uppercase tracking-wider">Titipan Gaji Aman</div>
                <div class="text-xl font-extrabold text-white font-mono mt-0.5 tracking-tight truncate">
                    Rp{{ number_format($stats['escrow_held'], 0, ',', '.') }}
                </div>
                <div class="text-[11px] text-emerald-300 font-medium mt-1 flex items-center gap-1">
                    <span>&uarr;</span> <span>Tertahan aman di escrow</span>
                </div>
            </div>
        </a>

        <!-- Metric 3: Open Listings -->
        <a href="{{ route('admin.listings.index') }}" 
           class="bg-[#0B3559]/80 hover:bg-[#0B3559] border border-white/10 hover:border-amber-400/30 rounded-2xl p-4.5 text-white shadow-md backdrop-blur-sm transition-all duration-200 flex items-start gap-3.5 group">
            <div class="w-11 h-11 rounded-xl bg-[#D97706] flex items-center justify-center text-white shrink-0 shadow-md group-hover:scale-105 transition-transform">
                <!-- Briefcase Icon -->
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"/></svg>
            </div>
            <div class="flex-1 min-w-0">
                <div class="text-[11px] font-semibold text-amber-200/80 uppercase tracking-wider">Lowongan Tayang</div>
                <div class="text-2xl font-extrabold text-white font-mono mt-0.5 tracking-tight">
                    {{ $stats['open_listings'] }}
                </div>
                <div class="text-[11px] text-amber-300 font-medium mt-1 flex items-center gap-1">
                    <span>&bull;</span> <span>Siap dilamar oleh asisten</span>
                </div>
            </div>
        </a>

        <!-- Metric 4: Active Bookings -->
        <a href="{{ route('admin.bookings.index') }}" 
           class="bg-[#0B3559]/80 hover:bg-[#0B3559] border border-white/10 hover:border-indigo-400/30 rounded-2xl p-4.5 text-white shadow-md backdrop-blur-sm transition-all duration-200 flex items-start gap-3.5 group">
            <div class="w-11 h-11 rounded-xl bg-[#6366F1] flex items-center justify-center text-white shrink-0 shadow-md group-hover:scale-105 transition-transform">
                <!-- Contract Check Icon -->
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4"/></svg>
            </div>
            <div class="flex-1 min-w-0">
                <div class="text-[11px] font-semibold text-indigo-200/80 uppercase tracking-wider">Pekerjaan Berjalan</div>
                <div class="text-2xl font-extrabold text-white font-mono mt-0.5 tracking-tight">
                    {{ $stats['active_bookings'] }}
                </div>
                <div class="text-[11px] text-indigo-300 font-medium mt-1 flex items-center gap-1">
                    <span>&bull;</span> <span>Kontrak kerja resmi aktif</span>
                </div>
            </div>
        </a>
    </div>

    <!-- Middle Section: 2 Big White Cards (Launchly Style) -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 items-stretch">

        <!-- Card 1 (Left): Pemeriksaan Berkas KTP -->
        <div class="bg-white rounded-2xl p-6 shadow-md border border-slate-100 flex flex-col justify-between h-full">
            <div class="flex-1 flex flex-col">
                <!-- Header with Icon & Queue Badge -->
                <div class="flex items-center justify-between pb-4 border-b border-slate-100">
                    <div class="flex items-center gap-3">
                        <div class="w-10 h-10 rounded-xl bg-[#FFF1EB] text-[#FF6B35] flex items-center justify-center shrink-0 shadow-xs">
                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
                        </div>
                        <div>
                            <h2 class="text-sm font-bold text-slate-900">Pemeriksaan Berkas KTP</h2>
                            <p class="text-xs text-slate-500">Verifikasi identitas calon asisten dan majikan baru.</p>
                        </div>
                    </div>
                    <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-bold {{ $stats['pending_verifications'] > 0 ? 'bg-amber-50 text-amber-800 border border-amber-200/70' : 'bg-emerald-50 text-emerald-800 border border-emerald-200/70' }}">
                        <span class="w-1.5 h-1.5 rounded-full {{ $stats['pending_verifications'] > 0 ? 'bg-amber-500 animate-pulse' : 'bg-emerald-500' }}"></span>
                        {{ $stats['pending_verifications'] }} Antrean
                    </span>
                </div>

                <!-- Tabs (Segmented Filter Pill Style) -->
                <div class="flex items-center gap-2 pt-3 pb-3 border-b border-slate-100 text-xs">
                    <a href="{{ route('admin.verifications.index', ['status' => 'pending']) }}" 
                       class="px-3 py-1.5 rounded-xl font-bold bg-[#FFF1EB] text-[#FF6B35] border border-orange-200/60 shadow-2xs transition-all flex items-center gap-1.5">
                        <span>Menunggu Tinjauan</span>
                        @if($stats['pending_verifications'] > 0)
                            <span class="px-1.5 py-0.2 rounded-full text-[10px] bg-[#FF6B35] text-white font-mono font-bold">{{ $stats['pending_verifications'] }}</span>
                        @endif
                    </a>
                    <a href="{{ route('admin.verifications.index', ['status' => 'verified']) }}" 
                       class="px-3 py-1.5 rounded-xl font-semibold text-slate-600 hover:text-slate-900 hover:bg-slate-50 border border-transparent hover:border-slate-200 transition-all">
                        Terverifikasi
                    </a>
                    <a href="{{ route('admin.verifications.index', ['status' => 'rejected']) }}" 
                       class="px-3 py-1.5 rounded-xl font-semibold text-slate-600 hover:text-slate-900 hover:bg-slate-50 border border-transparent hover:border-slate-200 transition-all">
                        Ditolak
                    </a>
                </div>

                <!-- Middle Queue Content & Verification Protocol (Fills Height Gracefully) -->
                <div class="flex-1 py-3.5 flex flex-col justify-between gap-3">
                    <!-- List Items -->
                    <div class="space-y-2.5">
                        @forelse($pendingVerifications->take(3) as $verif)
                            <div class="p-3 rounded-xl border border-slate-100 bg-slate-50/60 hover:bg-slate-50 hover:border-slate-200 transition-all flex items-center justify-between gap-3">
                                <div class="flex items-center gap-3 min-w-0">
                                    <!-- Clean Executive Avatar -->
                                    <div class="w-10 h-10 rounded-xl bg-[#082032] text-white flex items-center justify-center font-bold text-xs shrink-0 shadow-xs">
                                        {{ strtoupper(substr($verif->user->name, 0, 1)) }}
                                    </div>
                                    <div class="min-w-0">
                                        <div class="flex items-center gap-2">
                                            <h4 class="text-xs font-bold text-slate-900 truncate">{{ $verif->user->name }}</h4>
                                            <span class="px-2 py-0.5 rounded-full text-[10px] font-bold {{ $verif->user->active_role === 'assistant' ? 'bg-[#FFF1EB] text-[#FF6B35]' : 'bg-[#E0F2FE] text-[#0284C7]' }}">
                                                {{ $verif->user->active_role === 'assistant' ? 'Asisten' : 'Majikan' }}
                                            </span>
                                        </div>
                                        <p class="text-[11px] text-slate-500 mt-0.5 font-mono truncate">
                                            NIK: <strong class="text-slate-700">{{ substr($verif->nik, 0, 6) }}******</strong> &bull; {{ $verif->created_at->diffForHumans() }}
                                        </p>
                                    </div>
                                </div>

                                <div class="flex items-center gap-2 shrink-0">
                                    <a href="{{ route('admin.verifications.show', $verif->id) }}" 
                                       class="px-3 py-1.5 rounded-xl border border-slate-200 hover:bg-white text-xs font-semibold text-slate-700 transition-all shadow-2xs">
                                        Tinjau
                                    </a>
                                    <form action="{{ route('admin.verifications.approve', $verif->id) }}" method="POST" class="inline">
                                        @csrf
                                        <button type="submit" 
                                                onclick="return confirm('Konfirmasi persetujuan KTP atas nama {{ $verif->user->name }}?')"
                                                class="px-3 py-1.5 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold shadow-xs hover:shadow-emerald-600/20 transition-all flex items-center gap-1">
                                            <span>Setujui</span>
                                            <span>&check;</span>
                                        </button>
                                    </form>
                                </div>
                            </div>
                        @empty
                            <div class="py-8 text-center text-slate-500 text-xs">
                                <div class="w-10 h-10 rounded-full bg-emerald-50 text-emerald-600 flex items-center justify-center mx-auto mb-2">
                                    &check;
                                </div>
                                <p class="font-bold text-slate-800">Semua berkas telah selesai diperiksa</p>
                                <p class="text-[11px] text-slate-400 mt-0.5">Tidak ada antrean verifikasi KTP saat ini.</p>
                            </div>
                        @endforelse
                    </div>

                    <!-- Security & SLA Protocol Card to balance visual height -->
                    <div class="p-3.5 rounded-xl bg-slate-50/80 border border-slate-100 flex items-center justify-between gap-3 text-xs">
                        <div class="flex items-center gap-2.5">
                            <div class="w-7 h-7 rounded-lg bg-emerald-100 text-emerald-700 flex items-center justify-center shrink-0">
                                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"/></svg>
                            </div>
                            <div>
                                <div class="font-bold text-slate-900 text-xs">Standar Tinjauan SLA: Maks. 1x24 Jam</div>
                                <div class="text-[11px] text-slate-500">Pencocokan NIK, e-KTP, dan integritas data pengguna.</div>
                            </div>
                        </div>
                        <span class="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg text-[10px] font-bold bg-emerald-50 text-emerald-800 border border-emerald-200/60 shrink-0 whitespace-nowrap">
                            <span class="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
                            Dukcapil Valid
                        </span>
                    </div>
                </div>
            </div>

            <!-- Bottom Unified Action Footer -->
            <div class="pt-4 border-t border-slate-100 flex items-center justify-between gap-3 mt-auto">
                <span class="text-xs text-slate-500 font-medium">
                    @if($pendingVerifications->count() > 0)
                        Menampilkan <strong>{{ $pendingVerifications->take(3)->count() }}</strong> antrean teratas
                    @else
                        Semua antrean telah diproses
                    @endif
                </span>
                <a href="{{ route('admin.verifications.index') }}" 
                   class="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-[#082032] hover:bg-[#FF6B35] text-white text-xs font-bold transition-all shadow-xs group">
                    <span>Buka Semua Antrean</span>
                    <svg class="w-3.5 h-3.5 transition-transform group-hover:translate-x-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>
                </a>
            </div>
        </div>

        <!-- Card 2 (Right): Jadwal Wawancara Online -->
        <div class="bg-white rounded-2xl p-6 shadow-md border border-slate-100 flex flex-col justify-between h-full">
            <div class="flex-1 flex flex-col">
                <!-- Header with Icon & Link -->
                <div class="flex items-center justify-between pb-4 border-b border-slate-100">
                    <div class="flex items-center gap-3">
                        <div class="w-10 h-10 rounded-xl bg-[#FFF1EB] text-[#FF6B35] flex items-center justify-center shrink-0 shadow-xs">
                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"/></svg>
                        </div>
                        <div>
                            <h2 class="text-sm font-bold text-slate-900">Jadwal Wawancara Online</h2>
                            <p class="text-xs text-slate-500">Pertemuan tatap muka virtual calon pekerja dan majikan.</p>
                        </div>
                    </div>
                    <a href="{{ route('admin.interviews.index') }}" 
                       class="inline-flex items-center gap-1 px-3 py-1.5 rounded-xl border border-slate-200 text-xs font-bold text-slate-700 hover:bg-[#082032] hover:text-white transition-all shadow-2xs">
                        <span>Semua Jadwal</span>
                        <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>
                    </a>
                </div>

                <!-- Stepper Progress Badges -->
                <div class="flex items-center gap-2 py-3 border-b border-slate-100 text-xs overflow-x-auto">
                    <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-orange-50 text-[#FF6B35] font-bold border border-orange-200/60 shadow-2xs whitespace-nowrap">
                        <span class="w-4 h-4 rounded-full bg-[#FF6B35] text-white flex items-center justify-center text-[10px] font-bold">1</span>
                        Jadwal Terdekat
                    </span>
                    <svg class="w-3.5 h-3.5 text-slate-300 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>
                    <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-slate-50 text-slate-600 font-semibold border border-slate-200/60 whitespace-nowrap">
                        <span class="w-4 h-4 rounded-full bg-slate-200 text-slate-700 flex items-center justify-center text-[10px] font-bold">2</span>
                        Terkonfirmasi
                    </span>
                    <svg class="w-3.5 h-3.5 text-slate-300 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>
                    <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-slate-50 text-slate-600 font-semibold border border-slate-200/60 whitespace-nowrap">
                        <span class="w-4 h-4 rounded-full bg-slate-200 text-slate-700 flex items-center justify-center text-[10px] font-bold">3</span>
                        Selesai Dilaksanakan
                    </span>
                </div>

                <!-- Split View: Left Dossier Parameters + Right Google Meet Card -->
                <div class="py-4 grid grid-cols-1 md:grid-cols-12 gap-4 items-center">
                    <!-- Left Parameters -->
                    <div class="md:col-span-5 space-y-2 text-xs">
                        @php $firstInterview = $upcomingInterviews->first(); @endphp
                        <div class="p-2 rounded-xl bg-slate-50 border border-slate-100 flex items-center gap-2.5">
                            <div class="w-6 h-6 rounded-lg bg-emerald-100 text-emerald-700 flex items-center justify-center shrink-0 text-xs font-bold">&check;</div>
                            <div class="min-w-0">
                                <span class="text-[10px] font-bold text-slate-500 uppercase tracking-wider block">Kandidat</span>
                                <span class="font-bold text-slate-900 truncate block">{{ $firstInterview?->application?->user?->name ?? 'Anisa Rahma' }}</span>
                            </div>
                        </div>
                        <div class="p-2 rounded-xl bg-slate-50 border border-slate-100 flex items-center gap-2.5">
                            <div class="w-6 h-6 rounded-lg bg-emerald-100 text-emerald-700 flex items-center justify-center shrink-0 text-xs font-bold">&check;</div>
                            <div class="min-w-0">
                                <span class="text-[10px] font-bold text-slate-500 uppercase tracking-wider block">Majikan</span>
                                <span class="font-bold text-slate-900 truncate block">{{ $firstInterview?->application?->listing?->user?->name ?? 'Ibu Maya' }}</span>
                            </div>
                        </div>
                        <div class="p-2 rounded-xl bg-slate-50 border border-slate-100 flex items-center gap-2.5">
                            <div class="w-6 h-6 rounded-lg bg-emerald-100 text-emerald-700 flex items-center justify-center shrink-0 text-xs font-bold">&check;</div>
                            <div class="min-w-0">
                                <span class="text-[10px] font-bold text-slate-500 uppercase tracking-wider block">Platform</span>
                                <span class="font-semibold text-slate-800 truncate block">Google Meet Room Otomatis</span>
                            </div>
                        </div>
                        <div class="p-2 rounded-xl bg-slate-50 border border-slate-100 flex items-center gap-2.5">
                            <div class="w-6 h-6 rounded-lg bg-sky-100 text-sky-700 flex items-center justify-center shrink-0 text-xs font-bold">
                                <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                            </div>
                            <div class="min-w-0">
                                <span class="text-[10px] font-bold text-slate-500 uppercase tracking-wider block">Waktu Sesi</span>
                                <span class="font-bold text-slate-900 truncate block">{{ $firstInterview?->scheduled_at ? $firstInterview->scheduled_at->format('H:i') . ' WIB' : '14:00 WIB' }}</span>
                            </div>
                        </div>
                    </div>

                    <!-- Right Interactive Preview Card (Dark Meet Box) -->
                    <div class="md:col-span-7 bg-gradient-to-br from-[#082032] via-[#0C3B5E] to-[#05263F] rounded-2xl p-4.5 text-white shadow-md border border-cyan-500/20 space-y-3">
                        <div class="flex items-center justify-between">
                            <span class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-[10px] font-extrabold bg-[#0284C7] text-white tracking-wider uppercase">
                                <span class="w-1.5 h-1.5 rounded-full bg-white animate-pulse"></span>
                                GOOGLE MEET READY
                            </span>
                            <span class="inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-[10px] font-bold bg-white/10 text-cyan-200">
                                <svg class="w-3 h-3 text-cyan-300" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"/></svg>
                                Room Aktif
                            </span>
                        </div>
                        <div>
                            <h3 class="text-sm font-extrabold text-white">Sesi Wawancara Tatap Muka</h3>
                            <p class="text-[11px] text-cyan-200/90 mt-1 leading-snug">
                                Pertemuan langsung calon pekerja dan majikan untuk kesepakatan rincian tugas & gaji.
                            </p>
                        </div>
                        @php 
                            $meetingUrl = $firstInterview?->meeting_link ?? $firstInterview?->meeting_url; 
                        @endphp
                        @if($meetingUrl)
                            <a href="{{ $meetingUrl }}" target="_blank" rel="noopener noreferrer" 
                               class="inline-flex items-center gap-1.5 px-4 py-2 rounded-xl bg-[#FF6B35] hover:bg-[#E85926] text-white text-xs font-bold shadow-md shadow-[#FF6B35]/30 transition-all group">
                                <span>Masuk Meet</span>
                                <svg class="w-3.5 h-3.5 transition-transform group-hover:translate-x-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>
                            </a>
                        @else
                            <a href="{{ route('admin.interviews.index') }}" 
                               class="inline-flex items-center gap-1.5 px-4 py-2 rounded-xl bg-[#FF6B35] hover:bg-[#E85926] text-white text-xs font-bold shadow-md shadow-[#FF6B35]/30 transition-all group">
                                <span>Buka Room Meet</span>
                                <svg class="w-3.5 h-3.5 transition-transform group-hover:translate-x-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>
                            </a>
                        @endif
                    </div>
                </div>
            </div>

            <!-- Bottom Trust Badges -->
            <div class="pt-3 border-t border-slate-100 grid grid-cols-2 sm:grid-cols-4 gap-2 text-[11px] text-slate-600 font-semibold">
                <div class="flex items-center gap-2 p-1.5 rounded-lg bg-slate-50/80">
                    <div class="w-5 h-5 rounded-md bg-cyan-100 text-[#0284C7] flex items-center justify-center shrink-0">
                        <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"/></svg>
                    </div>
                    <span class="truncate">Sinkron Otomatis</span>
                </div>
                <div class="flex items-center gap-2 p-1.5 rounded-lg bg-slate-50/80">
                    <div class="w-5 h-5 rounded-md bg-emerald-100 text-emerald-700 flex items-center justify-center shrink-0">
                        <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"/></svg>
                    </div>
                    <span class="truncate">Aman & Terlindungi</span>
                </div>
                <div class="flex items-center gap-2 p-1.5 rounded-lg bg-slate-50/80">
                    <div class="w-5 h-5 rounded-md bg-emerald-100 text-emerald-700 flex items-center justify-center shrink-0">
                        <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"/></svg>
                    </div>
                    <span class="truncate">Notifikasi WA</span>
                </div>
                <div class="flex items-center gap-2 p-1.5 rounded-lg bg-slate-50/80">
                    <div class="w-5 h-5 rounded-md bg-amber-100 text-amber-700 flex items-center justify-center shrink-0">
                        <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M3 6l3 1m0 0l-3 9a5.002 5.002 0 006.001 0M6 7l3 9M6 7l6-2m6 2l3-1m-3 1l-3 9a5.002 5.002 0 006.001 0M18 7l3 9m-3-9l-6-2m0-2v2m0 16V5m0 16H9m3 0h3"/></svg>
                    </div>
                    <span class="truncate">Mediasi Pramu</span>
                </div>
            </div>
        </div>

    </div>

    <!-- Bottom Section: Full Width White Table Card -> Pekerjaan & Kontrak Sedang Berjalan -->
    <div class="bg-white rounded-2xl p-6 shadow-md border border-slate-100">
        <div class="flex items-center justify-between pb-4 border-b border-slate-100">
            <div>
                <h2 class="text-sm font-bold text-slate-900">Pekerjaan & Kontrak Sedang Berjalan</h2>
                <p class="text-xs text-slate-500 mt-0.5">Pantau tenaga kerja yang sedang aktif bertugas di rumah majikan</p>
            </div>
            <a href="{{ route('admin.bookings.index') }}" class="text-xs font-semibold text-[#0284C7] hover:underline">
                Lihat Semua Kontrak &rarr;
            </a>
        </div>

        @if($activeBookings->isEmpty())
            <div class="py-12 text-center text-xs text-slate-500">
                Belum ada kontrak kerja aktif yang sedang berjalan saat ini.
            </div>
        @else
            <div class="overflow-x-auto">
                <table class="w-full text-left text-xs text-slate-800">
                    <thead class="text-[11px] font-bold text-slate-700 uppercase tracking-wider bg-slate-50/80 border-b border-slate-200/80">
                        <tr>
                            <th class="py-3.5 px-4">Pihak Bekerja</th>
                            <th class="py-3.5 px-4">Status Kerja</th>
                            <th class="py-3.5 px-4">Layanan</th>
                            <th class="py-3.5 px-4">Gaji Bulanan</th>
                            <th class="py-3.5 px-4">Termin Escrow</th>
                            <th class="py-3.5 px-4 text-right">Aksi</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-100">
                        @foreach($activeBookings as $b)
                            <tr class="hover:bg-slate-50/70 transition-colors">
                                <td class="py-4 pr-4">
                                    <div class="flex items-center gap-3">
                                        <div class="w-9 h-9 rounded-xl bg-[#082032] text-white flex items-center justify-center text-xs font-bold shrink-0 shadow-xs">
                                            {{ strtoupper(substr($b->seeker?->name ?? 'M', 0, 1)) }}
                                        </div>
                                        <div>
                                            <div class="font-bold text-slate-900 text-xs">{{ $b->seeker?->name ?? 'Majikan' }}</div>
                                            <div class="text-[11px] text-slate-500">Asisten: <strong class="text-slate-700">{{ $b->assistant?->name ?? 'Asisten' }}</strong></div>
                                        </div>
                                    </div>
                                </td>
                                <td class="py-4 px-4 whitespace-nowrap">
                                    <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[10px] font-semibold bg-emerald-50 text-emerald-700 border border-emerald-200/60">
                                        <span class="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse"></span>
                                        Sedang Bertugas
                                    </span>
                                </td>
                                <td class="py-4 px-4 whitespace-nowrap">
                                    <span class="inline-flex items-center px-2.5 py-1 rounded-lg text-xs font-semibold bg-slate-100 text-slate-800 border border-slate-200/60">
                                        {{ $b->listing?->category?->name ?? 'Layanan Rumah Tangga' }}
                                    </span>
                                </td>
                                <td class="py-4 px-4 font-mono font-bold text-slate-900 whitespace-nowrap">
                                    Rp{{ number_format($b->total_agreed_rate, 0, ',', '.') }}
                                    <span class="block text-[10px] font-normal text-slate-400 font-sans">per bulan</span>
                                </td>
                                <td class="py-4 px-4 whitespace-nowrap">
                                    <span class="inline-flex items-center px-2.5 py-1 rounded-lg text-xs font-mono font-bold bg-sky-50 text-sky-800 border border-sky-200/60">
                                        {{ $b->periods?->count() ?? 1 }} Periode
                                    </span>
                                </td>
                                <td class="py-4 pl-4 text-right whitespace-nowrap">
                                    <a href="{{ route('admin.bookings.index') }}" 
                                       class="inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl bg-[#082032] hover:bg-[#FF6B35] text-white text-xs font-bold transition-all shadow-xs group">
                                        <span>Detail</span>
                                        <svg class="w-3.5 h-3.5 transition-transform group-hover:translate-x-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>
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
