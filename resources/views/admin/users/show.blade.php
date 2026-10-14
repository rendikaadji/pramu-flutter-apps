@extends('admin.layout')

@section('title', 'Detail Pengguna: ' . $user->name)
@section('header', 'Detail Akun: ' . ($user->active_role === 'assistant' ? 'Asisten Rumah Tangga' : 'Majikan (Pencari)'))

@section('content')
<div class="max-w-6xl space-y-6">
    <!-- Breadcrumb & Back Navigation -->
    <div class="flex items-center justify-between gap-4">
        <a href="{{ route('admin.users.index', ['role' => $user->active_role]) }}" 
           class="inline-flex items-center gap-2 text-xs font-semibold text-white/90 hover:text-white bg-white/10 hover:bg-white/15 px-3.5 py-2 rounded-xl border border-white/15 backdrop-blur-xs transition-all shadow-xs">
            <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"/>
            </svg>
            <span>Kembali ke {{ $user->active_role === 'assistant' ? 'Daftar Asisten (ART)' : 'Daftar Majikan (Pencari)' }}</span>
        </a>
        <div class="hidden sm:flex items-center gap-2 text-xs text-cyan-200/90 font-mono">
            <span>Pengguna</span>
            <span class="text-cyan-400">&bull;</span>
            <span class="text-white font-semibold">{{ $user->name }}</span>
        </div>
    </div>

    <!-- Main Profile Header Card (Launchly Modern Style) -->
    <div class="bg-white rounded-2xl border border-slate-100 p-6 sm:p-7 shadow-md space-y-6">
        <!-- Top Row: Avatar, Name, Badges, & Action Button -->
        <div class="flex flex-col md:flex-row md:items-center justify-between gap-5 border-b border-slate-100 pb-5">
            <div class="flex items-center gap-4.5">
                <div class="w-16 h-16 rounded-2xl {{ $user->active_role === 'assistant' ? 'bg-[#FF6B35]' : 'bg-[#082032]' }} text-white flex items-center justify-center font-black text-2xl shrink-0 shadow-sm border border-slate-700/20">
                    {{ strtoupper(substr($user->name, 0, 1)) }}
                </div>
                <div>
                    <div class="flex flex-wrap items-center gap-2.5">
                        <h2 class="text-2xl font-black text-slate-900 tracking-tight leading-tight">{{ $user->name }}</h2>
                        <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-bold whitespace-nowrap {{ $user->active_role === 'assistant' ? 'bg-orange-50 text-orange-950 border border-orange-300' : 'bg-sky-50 text-sky-950 border border-sky-300' }}">
                            {{ $user->active_role === 'assistant' ? 'Asisten Rumah Tangga (ART)' : 'Majikan (Pencari)' }}
                        </span>

                        @if($user->is_verified || ($user->verification && $user->verification->status === 'verified'))
                            <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-emerald-100 text-emerald-950 border border-emerald-300 whitespace-nowrap">
                                <svg class="w-3.5 h-3.5 text-emerald-700" fill="currentColor" viewBox="0 0 20 20">
                                    <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
                                </svg>
                                KTP Terverifikasi Sah
                            </span>
                        @elseif($user->verification && $user->verification->status === 'pending')
                            <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-amber-100 text-amber-950 border border-amber-300 whitespace-nowrap">
                                <span class="w-1.5 h-1.5 rounded-full bg-amber-600 animate-pulse"></span>
                                KTP Menunggu Tinjauan
                            </span>
                        @else
                            <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-bold bg-amber-50 text-amber-950 border border-amber-200 whitespace-nowrap">
                                KTP Belum Terverifikasi
                            </span>
                        @endif
                    </div>
                    
                    <p class="text-xs text-slate-600 mt-1.5 flex flex-wrap items-center gap-2">
                        <span>ID Akun: <strong class="font-mono text-slate-800">#{{ substr($user->id, 0, 8) }}</strong></span>
                        <span class="text-slate-300">&bull;</span>
                        <span>Terdaftar sejak <strong class="font-mono text-slate-800">{{ $user->created_at->format('d M Y, H:i') }} WIB</strong></span>
                    </p>
                </div>
            </div>

            <!-- Quick Action: Tinjau KTP di Verifikasi -->
            <div class="flex items-center gap-3 shrink-0 self-start md:self-center">
                @if($user->verification)
                    <a href="{{ route('admin.verifications.show', $user->verification->id) }}" 
                       class="inline-flex items-center gap-2 px-4.5 py-2.5 rounded-xl bg-slate-50 hover:bg-[#082032] text-slate-850 hover:text-white border border-slate-200 hover:border-[#082032] font-bold text-xs transition-all shadow-xs whitespace-nowrap group">
                        <svg class="w-4 h-4 text-cyan-600 group-hover:text-cyan-300 transition-colors" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V8a2 2 0 00-2-2h-5m-4 0V5a2 2 0 114 0v1m-4 0a2 2 0 104 0m-5 8a2 2 0 100-4 2 2 0 000 4zm0 0c1.306 0 2.417.835 2.83 2M9 14a3.001 3.001 0 00-2.83 2M15 11h3m-3 4h2" />
                        </svg>
                        <span>Tinjau KTP di Verifikasi</span>
                        <span class="text-slate-400 group-hover:text-white transition-colors">&rarr;</span>
                    </a>
                @endif
            </div>
        </div>

        <!-- High-Contrast Metadata Information Strip -->
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            <!-- No Telepon -->
            <div class="p-3.5 bg-slate-50/90 rounded-xl border border-slate-200/80 flex items-center gap-3">
                <div class="w-9 h-9 rounded-lg bg-white border border-slate-200 flex items-center justify-center text-slate-700 shrink-0">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"/></svg>
                </div>
                <div class="min-w-0">
                    <span class="text-[11px] font-bold text-slate-600 block uppercase tracking-wider">No. Telepon / HP</span>
                    <strong class="text-xs font-bold font-mono text-slate-900 block truncate">{{ $user->phone }}</strong>
                </div>
            </div>

            <!-- Email -->
            <div class="p-3.5 bg-slate-50/90 rounded-xl border border-slate-200/80 flex items-center gap-3">
                <div class="w-9 h-9 rounded-lg bg-white border border-slate-200 flex items-center justify-center text-slate-700 shrink-0">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/></svg>
                </div>
                <div class="min-w-0">
                    <span class="text-[11px] font-bold text-slate-600 block uppercase tracking-wider">Alamat Email</span>
                    <strong class="text-xs font-bold font-mono text-slate-900 block truncate" title="{{ $user->email }}">{{ $user->email }}</strong>
                </div>
            </div>

            @if($user->active_role === 'assistant')
                <!-- Rating Asisten -->
                <div class="p-3.5 bg-slate-50/90 rounded-xl border border-slate-200/80 flex items-center gap-3">
                    <div class="w-9 h-9 rounded-lg bg-amber-50 border border-amber-200 text-amber-600 flex items-center justify-center shrink-0">
                        ★
                    </div>
                    <div>
                        <span class="text-[11px] font-bold text-slate-600 block uppercase tracking-wider">Rating Asisten</span>
                        <div class="flex items-center gap-1.5 mt-0.5">
                            <strong class="text-xs font-bold font-mono text-amber-700">★ {{ number_format($user->received_reviews_avg_rating ?? 5.0, 1) }}</strong>
                            <span class="text-[11px] text-slate-600 font-semibold">({{ $user->received_reviews_count ?? 0 }} ulasan)</span>
                        </div>
                    </div>
                </div>

                <!-- Pengalaman Kerja -->
                <div class="p-3.5 bg-slate-50/90 rounded-xl border border-slate-200/80 flex items-center gap-3">
                    <div class="w-9 h-9 rounded-lg bg-orange-50 border border-orange-200 text-[#FF6B35] flex items-center justify-center shrink-0">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 13.255A23.931 23.931 0 0112 15c-3.183 0-6.22-.62-9-1.745M16 6V4a2 2 0 00-2-2h-4a2 2 0 00-2 2v2m4 6h.01M5 20h14a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/></svg>
                    </div>
                    <div>
                        <span class="text-[11px] font-bold text-slate-600 block uppercase tracking-wider">Pengalaman Kerja</span>
                        <strong class="text-xs font-bold text-slate-900 block mt-0.5">
                            {{ $user->assistantProfile?->experience_years ? $user->assistantProfile->experience_years . ' Tahun' : 'Asisten Baru' }}
                        </strong>
                    </div>
                </div>
            @else
                <!-- Lowongan Majikan -->
                <div class="p-3.5 bg-slate-50/90 rounded-xl border border-slate-200/80 flex items-center gap-3">
                    <div class="w-9 h-9 rounded-lg bg-sky-50 border border-sky-200 text-[#0C5D8F] flex items-center justify-center shrink-0">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"/></svg>
                    </div>
                    <div>
                        <span class="text-[11px] font-bold text-slate-600 block uppercase tracking-wider">Lowongan Terpasang</span>
                        <strong class="text-xs font-bold font-mono text-slate-900 block mt-0.5">
                            {{ $user->listings->count() }} lowongan ({{ $user->listings->where('status', 'open')->count() }} aktif)
                        </strong>
                    </div>
                </div>

                <!-- Regulasi SKCK Majikan -->
                <div class="p-3.5 bg-slate-50/90 rounded-xl border border-slate-200/80 flex items-center gap-3">
                    <div class="w-9 h-9 rounded-lg bg-emerald-50 border border-emerald-200 text-emerald-600 flex items-center justify-center shrink-0">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                    </div>
                    <div>
                        <span class="text-[11px] font-bold text-slate-600 block uppercase tracking-wider">Regulasi SKCK</span>
                        <strong class="text-xs font-bold text-slate-700 block mt-0.5">
                            Tidak Diperlukan (Majikan)
                        </strong>
                    </div>
                </div>
            @endif
        </div>
    </div>

    @if($user->active_role === 'assistant' && $user->assistantProfile)
        <!-- Profil Kerja, Keahlian, & Domisili Asisten -->
        <div class="bg-white rounded-2xl border border-slate-100 p-6 sm:p-7 shadow-md space-y-4">
            <div class="flex items-center justify-between border-b border-slate-100 pb-3.5">
                <div class="flex items-center gap-2.5">
                    <div class="w-7 h-7 rounded-lg bg-orange-50 text-[#FF6B35] flex items-center justify-center font-bold text-xs">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/></svg>
                    </div>
                    <h3 class="text-sm font-bold text-slate-900 tracking-tight">Profil Kerja & Spesialisasi Asisten</h3>
                </div>
                <div class="flex items-center gap-2">
                    <span class="text-xs font-bold px-2.5 py-1 rounded-lg {{ $user->assistantProfile->availability_status === 'available' ? 'bg-emerald-100 text-emerald-950 border border-emerald-300' : 'bg-slate-100 text-slate-800 border border-slate-200' }}">
                        {{ $user->assistantProfile->availability_status === 'available' ? 'Tersedia / Siap Bekerja' : 'Sedang Bekerja' }}
                    </span>
                </div>
            </div>

            <!-- Bio / Deskripsi Diri -->
            @if($user->assistantProfile->bio)
                <div class="p-4 bg-slate-50/80 rounded-xl border border-slate-200/80 text-xs text-slate-700 leading-relaxed">
                    <span class="text-[10px] font-bold text-slate-500 uppercase tracking-wider block mb-1">Tentang Diri & Pengalaman:</span>
                    <p class="font-medium">"{{ $user->assistantProfile->bio }}"</p>
                </div>
            @endif

            <!-- Skills, Expected Rate, & City Grid -->
            <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 pt-1">
                <!-- Keahlian Kerja -->
                <div class="p-4 bg-slate-50/80 rounded-xl border border-slate-200/80">
                    <span class="text-[11px] font-bold text-slate-600 block uppercase tracking-wider mb-2">Keahlian & Keterampilan</span>
                    @if(!empty($user->assistantProfile->skills))
                        <div class="flex flex-wrap gap-1.5">
                            @foreach($user->assistantProfile->skills as $skill)
                                <span class="px-2.5 py-1 rounded-lg bg-white border border-slate-200 text-[11px] font-semibold text-slate-800 shadow-2xs">
                                    {{ $skill }}
                                </span>
                            @endforeach
                        </div>
                    @else
                        <span class="text-xs text-slate-500 font-medium">Belum mengisi keahlian khusus</span>
                    @endif
                </div>

                <!-- Tarif Gaji Harapan -->
                <div class="p-4 bg-slate-50/80 rounded-xl border border-slate-200/80">
                    <span class="text-[11px] font-bold text-slate-600 block uppercase tracking-wider mb-1">Ekspektasi Tarif Gaji</span>
                    <strong class="text-base font-extrabold font-mono text-[#FF6B35] block">
                        Rp {{ number_format($user->assistantProfile->rate_per_period ?? 0, 0, ',', '.') }}
                    </strong>
                    <span class="text-[11px] text-slate-500 font-medium mt-0.5 block">
                        Periode: {{ $user->assistantProfile->period_type === 'monthly' ? 'Bulanan' : 'Harian' }}
                    </span>
                </div>

                <!-- Domisili / Kota Penempatan -->
                <div class="p-4 bg-slate-50/80 rounded-xl border border-slate-200/80">
                    <span class="text-[11px] font-bold text-slate-600 block uppercase tracking-wider mb-1">Domisili Kota</span>
                    <strong class="text-sm font-bold text-slate-900 block">
                        {{ $user->assistantProfile->city_name ?? 'Kota belum diatur' }}
                    </strong>
                    <span class="text-[11px] text-slate-500 font-medium mt-0.5 block">
                        Total {{ $user->applications->count() }} lamaran diajukan
                    </span>
                </div>
            </div>
        </div>
    @endif

    <!-- Section Header on Canvas (FIXED CONTRAST: High-Contrast White and Cyan on Dark Canvas) -->
    <div class="space-y-4 pt-1">
        <div class="flex items-center justify-between pb-1">
            <div class="flex items-center gap-2.5">
                <span class="w-2.5 h-2.5 rounded-full bg-[#FF6B35]"></span>
                <h3 class="text-sm font-extrabold text-white tracking-wide uppercase">Dokumen Verifikasi & Kepatuhan</h3>
            </div>
            <span class="text-xs font-semibold text-cyan-200">
                {{ $user->active_role === 'assistant' ? 'KTP & SKCK wajib untuk Asisten Rumah Tangga' : 'Hanya KTP yang diwajibkan untuk Majikan' }}
            </span>
        </div>

        @if($user->active_role === 'seeker')
            <!-- Notice for Seeker regarding SKCK -->
            <div class="p-5 bg-white rounded-2xl border border-slate-100 shadow-md flex items-start gap-4 text-xs text-slate-700">
                <div class="w-9 h-9 rounded-xl bg-sky-50 text-[#0C5D8F] flex items-center justify-center shrink-0 border border-sky-100">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>
                </div>
                <div class="leading-relaxed">
                    <strong class="text-slate-900 font-bold block mb-0.5">Kebijakan Verifikasi Majikan:</strong>
                    Dokumen SKCK (Surat Keterangan Catatan Kepolisian) <strong class="text-slate-900">tidak diperlukan</strong> bagi majikan atau pencari asisten. Majikan hanya melalui pemeriksaan KTP & wajah guna menjamin identitas resmi saat membuka lowongan kerja dan mengikat kontrak kerja sama.
                </div>
            </div>
        @endif

        <div class="grid grid-cols-1 {{ $user->active_role === 'assistant' ? 'md:grid-cols-2' : 'md:grid-cols-1' }} gap-6">
            <!-- 1. KTP Card -->
            <div class="bg-white rounded-2xl border border-slate-100 p-6 shadow-md space-y-4 flex flex-col justify-between">
                <div>
                    <div class="flex items-center justify-between border-b border-slate-100 pb-3.5">
                        <div class="flex items-center gap-2">
                            <div class="w-7 h-7 rounded-lg bg-cyan-50 text-cyan-700 flex items-center justify-center font-bold text-xs">1</div>
                            <h4 class="text-sm font-bold text-slate-900">Kartu Tanda Penduduk (KTP)</h4>
                        </div>

                        @if($user->verification)
                            @if($user->verification->status === 'verified')
                                <span class="inline-flex items-center gap-1 px-3 py-1 rounded-full text-xs font-bold bg-emerald-100 text-emerald-950 border border-emerald-300">
                                    Terverifikasi Sah
                                </span>
                            @elseif($user->verification->status === 'pending')
                                <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-bold bg-amber-100 text-amber-950 border border-amber-300">
                                    Menunggu Tinjauan
                                </span>
                            @else
                                <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-bold bg-rose-100 text-rose-950 border border-rose-300">
                                    Ditolak
                                </span>
                            @endif
                        @else
                            <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-slate-100 text-slate-700 border border-slate-200">
                                Belum Mengajukan KTP
                            </span>
                        @endif
                    </div>

                    @if($user->verification)
                        <div class="space-y-3 pt-2">
                            <div class="flex items-center justify-between text-xs">
                                <span class="text-slate-600 font-semibold">Nomor Induk Kependudukan (NIK):</span>
                                <span class="font-bold font-mono text-slate-900 bg-slate-100 px-2.5 py-1 rounded-lg border border-slate-200">{{ $user->verification->nik }}</span>
                            </div>
                            <div class="flex items-center justify-between text-xs">
                                <span class="text-slate-600 font-semibold">Waktu Pengajuan:</span>
                                <span class="font-mono text-slate-800 font-bold">{{ $user->verification->created_at->format('d M Y, H:i') }} WIB</span>
                            </div>

                            <!-- Preview Images Side by Side -->
                            <div class="grid grid-cols-2 gap-3.5 pt-2">
                                <div>
                                    <span class="text-[11px] font-bold text-slate-600 block mb-1.5 uppercase tracking-wider">Foto KTP:</span>
                                    <div class="h-44 bg-slate-950/5 rounded-xl border border-slate-200/90 flex items-center justify-center overflow-hidden relative group">
                                        @php
                                            $userKtpExists = $user->verification->ktp_path && (
                                                \Illuminate\Support\Facades\Storage::disk('local')->exists($user->verification->ktp_path) ||
                                                file_exists(storage_path('app/' . $user->verification->ktp_path)) ||
                                                file_exists(storage_path('app/private/' . $user->verification->ktp_path))
                                            );
                                        @endphp

                                        @if($userKtpExists)
                                            <a href="{{ route('admin.file.preview', ['path' => $user->verification->ktp_path]) }}" target="_blank" class="w-full h-full flex items-center justify-center p-2 group">
                                                <img src="{{ route('admin.file.preview', ['path' => $user->verification->ktp_path]) }}" alt="Foto KTP" class="w-full h-full object-contain group-hover:scale-105 transition-transform duration-200">
                                            </a>
                                        @else
                                            <div class="text-center p-3">
                                                <svg class="w-7 h-7 mx-auto text-slate-400 mb-1" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z"/></svg>
                                                <span class="text-xs text-slate-600 font-semibold block">Tersimpan di Vault</span>
                                            </div>
                                        @endif
                                    </div>
                                </div>

                                <div>
                                    <span class="text-[11px] font-bold text-slate-600 block mb-1.5 uppercase tracking-wider">Foto Selfie:</span>
                                    <div class="h-44 bg-slate-950/5 rounded-xl border border-slate-200/90 flex items-center justify-center overflow-hidden relative group">
                                        @php
                                            $userSelfieExists = $user->verification->selfie_path && (
                                                \Illuminate\Support\Facades\Storage::disk('local')->exists($user->verification->selfie_path) ||
                                                file_exists(storage_path('app/' . $user->verification->selfie_path)) ||
                                                file_exists(storage_path('app/private/' . $user->verification->selfie_path))
                                            );
                                        @endphp

                                        @if($userSelfieExists)
                                            <a href="{{ route('admin.file.preview', ['path' => $user->verification->selfie_path]) }}" target="_blank" class="w-full h-full flex items-center justify-center p-2 group">
                                                <img src="{{ route('admin.file.preview', ['path' => $user->verification->selfie_path]) }}" alt="Foto Selfie" class="w-full h-full object-contain group-hover:scale-105 transition-transform duration-200">
                                            </a>
                                        @else
                                            <div class="text-center p-3">
                                                <svg class="w-7 h-7 mx-auto text-slate-400 mb-1" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/></svg>
                                                <span class="text-xs text-slate-600 font-semibold block">Tersimpan di Vault</span>
                                            </div>
                                        @endif
                                    </div>
                                </div>
                            </div>
                        </div>
                    @else
                        <div class="p-8 text-center text-slate-500">
                            <p class="text-xs font-semibold">Pengguna belum mengunggah dokumen identitas KTP dan foto selfie.</p>
                        </div>
                    @endif
                </div>

                @if($user->verification)
                    <div class="pt-3 border-t border-slate-100">
                        <a href="{{ route('admin.verifications.show', $user->verification->id) }}" 
                           class="w-full inline-flex justify-center items-center py-2.5 px-3.5 rounded-xl bg-slate-50 hover:bg-[#082032] hover:text-white border border-slate-200 text-xs font-bold text-slate-800 transition-all shadow-xs">
                            Buka Lembar Pemeriksaan KTP Lengkap &rarr;
                        </a>
                    </div>
                @endif
            </div>

            @if($user->active_role === 'assistant')
                <!-- 2. SKCK Card (Strictly for Assistant) -->
                <div class="bg-white rounded-2xl border border-slate-100 p-6 shadow-md space-y-4 flex flex-col justify-between">
                    <div>
                        <div class="flex items-center justify-between border-b border-slate-100 pb-3.5">
                            <div class="flex items-center gap-2">
                                <div class="w-7 h-7 rounded-lg bg-orange-50 text-[#FF6B35] flex items-center justify-center font-bold text-xs">2</div>
                                <h4 class="text-sm font-bold text-slate-900">Dokumen SKCK (Kepolisian)</h4>
                            </div>

                            @if($user->skck)
                                @if($user->skck->status === 'verified')
                                    <span class="inline-flex items-center gap-1 px-3 py-1 rounded-full text-xs font-bold bg-emerald-100 text-emerald-950 border border-emerald-300">
                                        Terverifikasi Sah
                                    </span>
                                @elseif($user->skck->status === 'pending')
                                    <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-bold bg-amber-100 text-amber-950 border border-amber-300">
                                        Menunggu Tinjauan
                                    </span>
                                @else
                                    <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-bold bg-rose-100 text-rose-950 border border-rose-300">
                                        Ditolak
                                    </span>
                                @endif
                            @else
                                <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-slate-100 text-slate-700 border border-slate-200">
                                    Belum Unggah SKCK
                                </span>
                            @endif
                        </div>

                        @if($user->skck)
                            <div class="space-y-3.5 pt-2">
                                <div class="flex items-center justify-between text-xs">
                                    <span class="text-slate-600 font-semibold">Status Dokumen:</span>
                                    <strong class="text-slate-900 uppercase font-mono bg-slate-100 px-2.5 py-0.5 rounded-lg border border-slate-200">{{ $user->skck->status }}</strong>
                                </div>
                                @if($user->skck->rejection_reason)
                                    <div class="p-3.5 bg-rose-50 border border-rose-200 text-rose-900 rounded-xl text-xs">
                                        <strong>Alasan Penolakan:</strong> {{ $user->skck->rejection_reason }}
                                    </div>
                                @endif

                                <div class="pt-3">
                                    @if($user->skck->file_path)
                                        <a href="{{ route('admin.file.preview', ['path' => $user->skck->file_path]) }}" target="_blank" 
                                           class="w-full inline-flex justify-center items-center gap-2 py-3 px-4 rounded-xl bg-orange-50 hover:bg-orange-100 border border-orange-200 text-xs font-bold text-orange-950 transition-colors shadow-xs">
                                            <svg class="w-4 h-4 text-[#FF6B35]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                                            </svg>
                                            <span>Buka & Periksa Berkas SKCK (PDF / Gambar) &rarr;</span>
                                        </a>
                                    @endif
                                </div>
                            </div>
                        @else
                            <div class="p-8 text-center text-slate-500">
                                <div class="w-12 h-12 rounded-2xl bg-slate-100 text-slate-400 mx-auto mb-2 flex items-center justify-center">
                                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
                                </div>
                                <p class="text-xs font-semibold text-slate-700">Asisten belum mengunggah dokumen SKCK dari kepolisian.</p>
                                <p class="text-[11px] text-slate-500 mt-1">Dokumen ini akan ditinjau setelah asisten mengunggah berkas kepolisian yang sah.</p>
                            </div>
                        @endif
                    </div>

                    @if($user->skck)
                        <!-- Approval / Rejection Action for SKCK -->
                        <div class="pt-3 border-t border-slate-100 flex items-center gap-2.5">
                            <form action="{{ route('admin.skck.approve', $user->skck->id) }}" method="POST" class="flex-1">
                                @csrf
                                <button type="submit" class="w-full py-2.5 px-3.5 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold transition-all shadow-sm">
                                    Setujui SKCK &check;
                                </button>
                            </form>
                            <form action="{{ route('admin.skck.reject', $user->skck->id) }}" method="POST" class="flex-1">
                                @csrf
                                <input type="hidden" name="reason" value="Dokumen SKCK buram, kedaluwarsa, atau tidak valid.">
                                <button type="submit" class="w-full py-2.5 px-3.5 rounded-xl border border-rose-300 text-rose-700 hover:bg-rose-50 text-xs font-bold transition-all">
                                    Tolak SKCK &times;
                                </button>
                            </form>
                        </div>
                    @endif
                </div>
            @endif
        </div>
    </div>

    <!-- Rating & Reviews Section (For Assistant) -->
    @if($user->active_role === 'assistant')
        <div class="bg-white rounded-2xl border border-slate-100 shadow-md overflow-hidden">
            <div class="px-6 py-4.5 border-b border-slate-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3 bg-gradient-to-r from-slate-50/70 to-white">
                <div>
                    <h3 class="text-base font-bold text-slate-900 tracking-tight">Ulasan & Rating Kinerja dari Majikan</h3>
                    <p class="text-xs text-slate-600 mt-0.5">Evaluasi kepuasan kerja majikan terhadap performa kerja asisten</p>
                </div>
                <div class="flex items-center gap-2 self-start sm:self-center">
                    <span class="text-xs font-bold text-slate-700">Rata-rata:</span>
                    <span class="inline-flex items-center gap-1 px-3 py-1 rounded-xl bg-amber-50 border border-amber-300 text-amber-950 font-mono font-bold text-xs">
                        ★ {{ $user->received_reviews_avg_rating ? number_format($user->received_reviews_avg_rating, 1) : '5.0' }}
                    </span>
                    <span class="text-xs text-slate-700 font-semibold">({{ $user->received_reviews_count ?? 0 }} ulasan)</span>
                </div>
            </div>

            @if($user->receivedReviews->isEmpty())
                <div class="p-12 text-center text-slate-500">
                    <svg class="w-10 h-10 mx-auto text-slate-300 mb-2" fill="currentColor" viewBox="0 0 20 20">
                        <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"/>
                    </svg>
                    <p class="text-xs font-semibold text-slate-700">Asisten ini belum menerima ulasan atau rating dari majikan.</p>
                </div>
            @else
                <div class="divide-y divide-slate-100">
                    @foreach($user->receivedReviews as $review)
                        <div class="p-6 hover:bg-sky-50/20 transition-colors">
                            <div class="flex items-start justify-between gap-4">
                                <div class="flex items-center gap-3">
                                    <div class="w-9 h-9 rounded-xl bg-[#082032] text-white flex items-center justify-center font-bold text-xs shrink-0 shadow-xs">
                                        {{ strtoupper(substr($review->reviewer->name ?? 'M', 0, 1)) }}
                                    </div>
                                    <div>
                                        <div class="font-bold text-xs text-slate-900">{{ $review->reviewer->name ?? 'Majikan' }}</div>
                                        <div class="text-[11px] text-slate-500 font-mono">{{ $review->created_at->format('d M Y, H:i') }} WIB</div>
                                    </div>
                                </div>
                                <div class="flex items-center gap-1 text-amber-500">
                                    @for($i = 1; $i <= 5; $i++)
                                        <svg class="w-4 h-4 {{ $i <= $review->rating ? 'fill-amber-500' : 'text-slate-200 fill-current' }}" viewBox="0 0 20 20">
                                            <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"/>
                                        </svg>
                                    @endfor
                                    <span class="font-mono font-bold text-xs text-slate-900 ml-1">{{ $review->rating }}.0</span>
                                </div>
                            </div>
                            <div class="mt-3 text-xs text-slate-800 pl-12 leading-relaxed font-medium">
                                "{{ $review->comment }}"
                            </div>
                        </div>
                    @endforeach
                </div>
            @endif
        </div>
    @endif

    <!-- Listings Section (For Seeker) -->
    @if($user->active_role === 'seeker')
        <div class="bg-white rounded-2xl border border-slate-100 shadow-md overflow-hidden">
            <div class="px-6 py-4.5 border-b border-slate-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3 bg-gradient-to-r from-slate-50/70 to-white">
                <div>
                    <h3 class="text-base font-bold text-slate-900 tracking-tight">Lowongan Pekerjaan yang Dipasang</h3>
                    <p class="text-xs text-slate-600 mt-0.5">Daftar lowongan kerja yang telah dipublikasikan oleh majikan ini</p>
                </div>
                <span class="text-xs text-slate-800 font-mono font-bold bg-slate-100 border border-slate-200 px-3 py-1 rounded-xl self-start sm:self-center">
                    Total: {{ $user->listings->count() }} lowongan
                </span>
            </div>

            @if($user->listings->isEmpty())
                <div class="p-12 text-center text-slate-500">
                    <p class="text-xs font-semibold text-slate-700">Majikan ini belum pernah memasang lowongan pekerjaan.</p>
                </div>
            @else
                <div class="overflow-x-auto">
                    <table class="w-full text-left text-xs text-slate-800 whitespace-nowrap">
                        <thead class="bg-slate-50/90 uppercase font-bold text-[11px] text-slate-700 border-b border-slate-200/80 tracking-wider">
                            <tr>
                                <th class="px-6 py-3.5 whitespace-nowrap">Judul Lowongan</th>
                                <th class="px-6 py-3.5 whitespace-nowrap">Kategori</th>
                                <th class="px-6 py-3.5 whitespace-nowrap">Anggaran Gaji</th>
                                <th class="px-6 py-3.5 whitespace-nowrap">Lokasi</th>
                                <th class="px-6 py-3.5 whitespace-nowrap">Status</th>
                                <th class="px-6 py-3.5 whitespace-nowrap">Tanggal Dibuat</th>
                            </tr>
                        </thead>
                        <tbody class="divide-y divide-slate-100">
                            @foreach($user->listings as $listing)
                                <tr class="hover:bg-sky-50/30 transition-colors">
                                    <td class="px-6 py-4 font-bold text-slate-900 whitespace-nowrap">{{ $listing->title }}</td>
                                    <td class="px-6 py-4 text-slate-700 whitespace-nowrap">{{ $listing->category->name ?? '-' }}</td>
                                    <td class="px-6 py-4 font-mono font-bold text-slate-900 whitespace-nowrap">Rp {{ number_format($listing->budget_min, 0, ',', '.') }} - {{ number_format($listing->budget_max, 0, ',', '.') }}</td>
                                    <td class="px-6 py-4 text-slate-700 whitespace-nowrap">{{ $listing->city ?? '-' }}</td>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-[10px] font-bold {{ $listing->status === 'open' ? 'bg-emerald-100 text-emerald-950 border border-emerald-300' : 'bg-slate-100 text-slate-700 border border-slate-200' }}">
                                            {{ strtoupper($listing->status) }}
                                        </span>
                                    </td>
                                    <td class="px-6 py-4 font-mono text-slate-600 whitespace-nowrap">{{ $listing->created_at->format('d M Y') }}</td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            @endif
        </div>
    @endif

    <!-- Applications History (For Assistant) -->
    @if($user->active_role === 'assistant')
        <div class="bg-white rounded-2xl border border-slate-100 shadow-md overflow-hidden">
            <div class="px-6 py-4.5 border-b border-slate-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3 bg-gradient-to-r from-slate-50/70 to-white">
                <div>
                    <h3 class="text-base font-bold text-slate-900 tracking-tight">Riwayat Lamaran Pekerjaan</h3>
                    <p class="text-xs text-slate-600 mt-0.5">Lowongan yang pernah dilamar oleh asisten ini</p>
                </div>
                <span class="text-xs text-slate-800 font-mono font-bold bg-slate-100 border border-slate-200 px-3 py-1 rounded-xl self-start sm:self-center">
                    Total: {{ $user->applications->count() }} lamaran
                </span>
            </div>

            @if($user->applications->isEmpty())
                <div class="p-12 text-center text-slate-500">
                    <p class="text-xs font-semibold text-slate-700">Asisten ini belum mengajukan lamaran pekerjaan.</p>
                </div>
            @else
                <div class="overflow-x-auto">
                    <table class="w-full text-left text-xs text-slate-800 whitespace-nowrap">
                        <thead class="bg-slate-50/90 uppercase font-bold text-[11px] text-slate-700 border-b border-slate-200/80 tracking-wider">
                            <tr>
                                <th class="px-6 py-3.5 whitespace-nowrap">Lowongan</th>
                                <th class="px-6 py-3.5 whitespace-nowrap">Kategori</th>
                                <th class="px-6 py-3.5 whitespace-nowrap">Tarif Diajukan</th>
                                <th class="px-6 py-3.5 whitespace-nowrap">Status Lamaran</th>
                                <th class="px-6 py-3.5 whitespace-nowrap">Waktu Melamar</th>
                            </tr>
                        </thead>
                        <tbody class="divide-y divide-slate-100">
                            @foreach($user->applications as $app)
                                <tr class="hover:bg-sky-50/30 transition-colors">
                                    <td class="px-6 py-4 font-bold text-slate-900 whitespace-nowrap">{{ $app->listing->title ?? '-' }}</td>
                                    <td class="px-6 py-4 text-slate-700 whitespace-nowrap">{{ $app->listing->category->name ?? '-' }}</td>
                                    <td class="px-6 py-4 font-mono font-bold text-[#FF6B35] whitespace-nowrap">Rp {{ number_format($app->proposed_rate, 0, ',', '.') }}</td>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-[10px] font-bold {{ $app->status === 'accepted' ? 'bg-emerald-100 text-emerald-950 border border-emerald-300' : ($app->status === 'pending' ? 'bg-amber-100 text-amber-950 border border-amber-300' : 'bg-slate-100 text-slate-700 border border-slate-200') }}">
                                            {{ strtoupper($app->status) }}
                                        </span>
                                    </td>
                                    <td class="px-6 py-4 font-mono text-slate-600 whitespace-nowrap">{{ $app->created_at->format('d M Y') }}</td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            @endif
        </div>
    @endif
</div>
@endsection
