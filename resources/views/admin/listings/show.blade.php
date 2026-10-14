@extends('admin.layout')

@section('title', 'Tinjau Lowongan: ' . $listing->title)
@section('header', 'Detail Lowongan Kerja')

@section('content')
<div class="max-w-6xl space-y-5">
    <!-- Breadcrumb & Back Navigation -->
    <div class="flex items-center justify-between gap-4">
        <a href="{{ route('admin.listings.index') }}" 
           class="inline-flex items-center gap-2 text-xs font-semibold text-white/90 hover:text-white bg-white/10 hover:bg-white/15 px-3.5 py-2 rounded-xl border border-white/15 backdrop-blur-xs transition-all shadow-xs">
            <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"/>
            </svg>
            <span>Kembali ke Daftar Lowongan Kerja</span>
        </a>
        <div class="hidden sm:flex items-center gap-2 text-xs text-cyan-200/90 font-mono">
            <span>Lowongan</span>
            <span class="text-cyan-400">&bull;</span>
            <span class="text-white font-semibold">Tinjau Detail</span>
        </div>
    </div>

    <!-- Main Header Card (Compact & Balanced Layout) -->
    <div class="bg-white rounded-2xl border border-slate-100 p-5 sm:p-6 shadow-md">
        <div class="flex flex-col lg:flex-row lg:items-center justify-between gap-5">
            <!-- Left: Badges, Title, & Metadata -->
            <div class="space-y-2 flex-1 min-w-0">
                <!-- Badges Row (Compact) -->
                <div class="flex flex-wrap items-center gap-1.5">
                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-bold bg-cyan-50 text-cyan-900 border border-cyan-300">
                        {{ $listing->category?->name ?? 'Layanan Rumah Tangga' }}
                    </span>

                    @if($listing->status === 'open')
                        <span class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-bold bg-emerald-100 text-emerald-950 border border-emerald-300">
                            <span class="w-1.5 h-1.5 rounded-full bg-emerald-600 animate-pulse"></span>
                            Tayang Aktif
                        </span>
                    @elseif(in_array($listing->status, ['draft', 'awaiting_payment']))
                        <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-bold bg-amber-100 text-amber-950 border border-amber-300">
                            Draf / Belum Bayar
                        </span>
                    @else
                        <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-bold bg-slate-100 text-slate-800 border border-slate-200">
                            Ditutup
                        </span>
                    @endif

                    @if($listing->require_skck)
                        <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-bold bg-orange-50 text-orange-950 border border-orange-300">
                            Wajib SKCK Kepolisian
                        </span>
                    @endif

                    @if($listing->paid_at)
                        <span class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-bold bg-emerald-100 text-emerald-950 border border-emerald-300">
                            <svg class="w-3.5 h-3.5 text-emerald-700" fill="currentColor" viewBox="0 0 20 20">
                                <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
                            </svg>
                            Iklan Lunas Rp25.000
                        </span>
                    @else
                        <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-slate-100 text-slate-700 border border-slate-200">
                            Belum Bayar Iklan
                        </span>
                    @endif
                </div>

                <!-- Title (Crisp, not overflowing) -->
                <h1 class="text-xl sm:text-2xl font-black text-slate-900 tracking-tight leading-snug pt-0.5">{{ $listing->title }}</h1>

                <!-- Metadata Row (Single horizontal flow) -->
                <div class="flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-slate-600 pt-0.5">
                    <div>ID: <strong class="text-slate-900 font-mono">#{{ substr($listing->id, 0, 8) }}</strong></div>
                    <span class="text-slate-300">&bull;</span>
                    <div>Dibuat: <strong class="text-slate-900 font-mono">{{ $listing->created_at->format('d M Y, H:i') }} WIB</strong></div>
                    @if($listing->expires_at)
                        <span class="text-slate-300">&bull;</span>
                        <div>Masa Tayang: <strong class="text-slate-900 font-mono">{{ $listing->expires_at->format('d M Y') }}</strong></div>
                    @endif
                    <span class="text-slate-300">&bull;</span>
                    <div>Total Pelamar: <strong class="text-slate-900 font-mono">{{ $listing->applications->count() }} asisten</strong></div>
                </div>
            </div>

            <!-- Right: Budget Box (Clean & Integrated) -->
            <div class="p-4 sm:p-5 bg-slate-50/90 rounded-2xl border border-slate-200/90 shrink-0 text-left lg:text-right shadow-xs min-w-[260px]">
                <span class="text-[10px] font-bold text-slate-500 uppercase tracking-wider block">Anggaran Gaji yang Ditawarkan</span>
                <div class="text-xl sm:text-2xl font-black font-mono text-slate-900 mt-0.5">
                    Rp {{ number_format($listing->budget_min, 0, ',', '.') }} - {{ number_format($listing->budget_max, 0, ',', '.') }}
                </div>
                <div class="text-xs text-slate-600 font-medium mt-1 flex items-center justify-start lg:justify-end gap-1.5">
                    <span>Periode: <strong class="text-slate-800">{{ $listing->period_type === 'monthly' ? 'Bulanan' : ($listing->period_type === 'daily' ? 'Harian' : ucfirst($listing->period_type)) }}</strong></span>
                    <span>&bull;</span>
                    <span>Siklus: <strong class="text-slate-800">{{ ucfirst($listing->billing_cycle ?? 'bulanan') }}</strong></span>
                </div>
            </div>
        </div>
    </div>

    <!-- 2 Column Details: Employer Profile & Job Specifications -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-5 items-start">
        <!-- Column 1: Employer Profile Card (1/3 width, hugs natural height - no blank gap!) -->
        <div class="bg-white rounded-2xl border border-slate-100 p-5 sm:p-6 shadow-md space-y-4 lg:self-start">
            <div class="flex items-center justify-between border-b border-slate-100 pb-3">
                <div class="flex items-center gap-2">
                    <div class="w-6 h-6 rounded-lg bg-sky-50 text-[#0C5D8F] flex items-center justify-center font-bold text-xs">
                        <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/></svg>
                    </div>
                    <h3 class="text-xs font-bold text-slate-900 uppercase tracking-wider">Pembuat Lowongan (Majikan)</h3>
                </div>

                @if($listing->user && ($listing->user->is_verified || ($listing->user->verification && $listing->user->verification->status === 'verified')))
                    <span class="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-emerald-100 text-emerald-950 border border-emerald-300">
                        KTP Sah
                    </span>
                @else
                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-amber-100 text-amber-950 border border-amber-300">
                        Belum Terverifikasi
                    </span>
                @endif
            </div>

            @if($listing->user)
                <div class="flex items-center gap-3 pt-0.5">
                    <div class="w-12 h-12 rounded-2xl bg-[#082032] text-white flex items-center justify-center font-black text-lg shadow-sm shrink-0 border border-slate-700/20">
                        {{ strtoupper(substr($listing->user->name, 0, 1)) }}
                    </div>
                    <div>
                        <h4 class="font-extrabold text-sm text-slate-900">{{ $listing->user->name }}</h4>
                        <p class="text-xs text-slate-600 mt-0.5">{{ $listing->user->active_role === 'seeker' ? 'Pemberi Kerja / Majikan' : 'Pengguna Platform' }}</p>
                    </div>
                </div>

                <div class="space-y-2 text-xs border-t border-slate-100 pt-3">
                    <div class="flex items-center justify-between">
                        <span class="text-slate-600 font-semibold">Nomor HP:</span>
                        <span class="font-mono font-bold text-slate-900">{{ $listing->user->phone }}</span>
                    </div>
                    <div class="flex items-center justify-between">
                        <span class="text-slate-600 font-semibold">Email:</span>
                        <span class="font-mono text-slate-800 font-medium truncate max-w-[180px]" title="{{ $listing->user->email }}">{{ $listing->user->email }}</span>
                    </div>
                    <div class="flex items-center justify-between">
                        <span class="text-slate-600 font-semibold">Terdaftar Sejak:</span>
                        <span class="font-mono text-slate-800">{{ $listing->user->created_at->format('d M Y') }}</span>
                    </div>
                    <div class="flex items-center justify-between">
                        <span class="text-slate-600 font-semibold">Total Lowongan:</span>
                        <span class="font-mono text-slate-900 font-bold">{{ $listing->user->listings->count() }} lowongan</span>
                    </div>
                </div>

                <div class="pt-2 border-t border-slate-100">
                    <a href="{{ route('admin.users.show', $listing->user->id) }}" 
                       class="w-full inline-flex justify-center items-center gap-2 py-2 px-3 rounded-xl bg-slate-50 hover:bg-[#082032] hover:text-white border border-slate-200 hover:border-[#082032] text-xs font-bold text-slate-800 transition-all shadow-xs group">
                        <span>Lihat Profil Majikan Selengkapnya</span>
                        <span class="text-slate-400 group-hover:text-white transition-colors">&rarr;</span>
                    </a>
                </div>
            @else
                <p class="text-xs text-slate-500 italic py-3">Data pengguna pembuat lowongan tidak ditemukan.</p>
            @endif
        </div>

        <!-- Column 2: Job Specifications & Requirements (2/3 width) -->
        <div class="lg:col-span-2 bg-white rounded-2xl border border-slate-100 p-5 sm:p-6 shadow-md space-y-5">
            <div>
                <div class="flex items-center gap-2 mb-2.5">
                    <div class="w-6 h-6 rounded-lg bg-orange-50 text-[#FF6B35] flex items-center justify-center font-bold text-xs">
                        <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
                    </div>
                    <h3 class="text-xs font-bold text-slate-900 uppercase tracking-wider">Deskripsi & Rincian Pekerjaan</h3>
                </div>

                <div class="p-4 bg-slate-50/80 rounded-xl border border-slate-200/80 text-xs sm:text-sm text-slate-800 leading-relaxed whitespace-pre-line font-medium">
                    {{ $listing->description }}
                </div>
            </div>

            <!-- Parameters Grid (Compact 2x2) -->
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-3.5 border-t border-slate-100 pt-4">
                <div class="p-3 bg-slate-50/80 rounded-xl border border-slate-200/80">
                    <span class="text-[10px] font-bold text-slate-500 uppercase tracking-wider block">Lokasi & Wilayah Penempatan</span>
                    <span class="text-xs font-bold text-slate-900 mt-0.5 block">{{ $listing->city_name ?? 'Nasional / Seluruh Wilayah' }}</span>
                </div>

                <div class="p-3 bg-slate-50/80 rounded-xl border border-slate-200/80">
                    <span class="text-[10px] font-bold text-slate-500 uppercase tracking-wider block">Tanggal Mulai Bekerja</span>
                    <span class="text-xs font-bold font-mono text-slate-900 mt-0.5 block">
                        {{ $listing->start_date ? $listing->start_date->format('d M Y') : 'Segera' }}
                    </span>
                </div>

                <div class="p-3 bg-slate-50/80 rounded-xl border border-slate-200/80">
                    <span class="text-[10px] font-bold text-slate-500 uppercase tracking-wider block">Periode Kontrak</span>
                    <span class="text-xs font-bold text-slate-900 mt-0.5 block">
                        {{ $listing->period_count }} {{ ucfirst($listing->period_type) }}
                    </span>
                </div>

                <div class="p-3 bg-slate-50/80 rounded-xl border border-slate-200/80">
                    <span class="text-[10px] font-bold text-slate-500 uppercase tracking-wider block">Persyaratan Dokumen SKCK</span>
                    <span class="text-xs font-bold text-slate-900 mt-0.5 block">
                        {{ $listing->require_skck ? 'Wajib SKCK Kepolisian Sah' : 'Tidak Diwajibkan SKCK' }}
                    </span>
                </div>
            </div>

            <!-- Screening Questions if available -->
            @if(!empty($listing->screening_questions) && is_array($listing->screening_questions))
                <div class="border-t border-slate-100 pt-4 space-y-2.5">
                    <h4 class="text-xs font-bold text-slate-900 uppercase tracking-wider flex items-center gap-2">
                        <span class="w-1.5 h-1.5 rounded-full bg-[#FF6B35]"></span>
                        Pertanyaan Skrining untuk Calon Pelamar
                    </h4>
                    <ul class="space-y-2 text-xs text-slate-700">
                        @foreach($listing->screening_questions as $index => $question)
                            <li class="flex items-start gap-2.5 p-3 bg-slate-50 rounded-xl border border-slate-200/80 font-medium">
                                <span class="font-bold text-[#FF6B35] font-mono shrink-0">{{ $index + 1 }}.</span>
                                <span>{{ $question }}</span>
                            </li>
                        @endforeach
                    </ul>
                </div>
            @endif
        </div>
    </div>

    <!-- Applicants Section -->
    <div class="bg-white rounded-2xl border border-slate-100 shadow-md overflow-hidden">
        <div class="px-6 py-4.5 border-b border-slate-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3 bg-gradient-to-r from-slate-50/70 to-white">
            <div class="flex items-center gap-3">
                <div class="w-8 h-8 rounded-xl bg-orange-50 text-[#FF6B35] flex items-center justify-center font-bold text-xs shrink-0">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"/></svg>
                </div>
                <div>
                    <h3 class="text-base font-bold text-slate-900 tracking-tight">Daftar Asisten yang Melamar</h3>
                    <p class="text-xs text-slate-600 mt-0.5">Para pekerja rumah tangga yang mengajukan penawaran kerja untuk lowongan ini</p>
                </div>
            </div>
            <span class="text-xs text-slate-800 font-mono font-bold bg-slate-100 border border-slate-200 px-3 py-1.5 rounded-xl self-start sm:self-center">
                Total: {{ $listing->applications->count() }} pelamar
            </span>
        </div>

        @if($listing->applications->isEmpty())
            <div class="p-12 text-center text-slate-500">
                <div class="w-12 h-12 rounded-2xl bg-slate-100 text-slate-400 mx-auto mb-2 flex items-center justify-center">
                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"/></svg>
                </div>
                <p class="text-xs font-semibold text-slate-700">Belum ada asisten yang mengajukan lamaran untuk lowongan ini.</p>
                <p class="text-[11px] text-slate-500 mt-1">Lamaran dari asisten yang berminat akan otomatis tampil pada tabel ini.</p>
            </div>
        @else
            <div class="overflow-x-auto">
                <table class="w-full text-left text-xs text-slate-800 whitespace-nowrap">
                    <thead class="bg-slate-50/90 uppercase font-bold text-[11px] text-slate-700 border-b border-slate-200/80 tracking-wider">
                        <tr>
                            <th class="px-6 py-3.5 whitespace-nowrap">Nama Asisten</th>
                            <th class="px-6 py-3.5 whitespace-nowrap">Tarif Diajukan</th>
                            <th class="px-6 py-3.5 whitespace-nowrap">Pengalaman Kerja</th>
                            <th class="px-6 py-3.5 whitespace-nowrap">Pesan Singkat</th>
                            <th class="px-6 py-3.5 whitespace-nowrap">Status Lamaran</th>
                            <th class="px-6 py-3.5 whitespace-nowrap">Waktu Melamar</th>
                            <th class="px-6 py-3.5 text-right whitespace-nowrap">Aksi Profil</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-100">
                        @foreach($listing->applications as $app)
                            <tr class="hover:bg-sky-50/30 transition-colors">
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <div class="flex items-center gap-3">
                                        <div class="w-8 h-8 rounded-xl bg-[#082032] text-white flex items-center justify-center font-bold text-xs shrink-0 shadow-xs">
                                            {{ strtoupper(substr($app->user->name ?? 'A', 0, 1)) }}
                                        </div>
                                        <div>
                                            <div class="font-bold text-slate-900">{{ $app->user->name ?? 'Asisten' }}</div>
                                            <div class="text-[11px] text-slate-500 font-mono mt-0.5">{{ $app->user->phone ?? '-' }}</div>
                                        </div>
                                    </div>
                                </td>
                                <td class="px-6 py-4 font-mono font-bold text-[#FF6B35] whitespace-nowrap">
                                    Rp {{ number_format($app->proposed_rate, 0, ',', '.') }}
                                </td>
                                <td class="px-6 py-4 text-slate-700 whitespace-nowrap">
                                    {{ $app->user?->assistantProfile?->experience_years ? $app->user->assistantProfile->experience_years . ' Tahun' : 'Asisten Baru' }}
                                </td>
                                <td class="px-6 py-4 max-w-xs text-slate-700 truncate whitespace-nowrap font-medium" title="{{ $app->message }}">
                                    {{ $app->message ?? '-' }}
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-[10px] font-bold {{ $app->status === 'accepted' ? 'bg-emerald-100 text-emerald-950 border border-emerald-300' : ($app->status === 'pending' ? 'bg-amber-100 text-amber-950 border border-amber-300' : 'bg-slate-100 text-slate-700 border border-slate-200') }}">
                                        {{ strtoupper($app->status) }}
                                    </span>
                                </td>
                                <td class="px-6 py-4 font-mono text-slate-600 whitespace-nowrap">
                                    {{ $app->created_at->format('d M Y') }}
                                </td>
                                <td class="px-6 py-4 text-right whitespace-nowrap">
                                    @if($app->user)
                                        <a href="{{ route('admin.users.show', $app->user->id) }}" 
                                           class="inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl bg-[#082032] hover:bg-[#FF6B35] text-white text-xs font-bold transition-all shadow-xs group">
                                            <span>Lihat Detail</span>
                                            <svg class="w-3.5 h-3.5 transition-transform group-hover:translate-x-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>
                                        </a>
                                    @endif
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
