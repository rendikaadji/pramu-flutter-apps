@extends('admin.layout')

@section('title', 'Executive Operations & Escrow Dashboard')
@section('header', 'Dashboard Operasional & Pemantauan Escrow')

@section('content')
<div class="space-y-6">

    <!-- Top Greetings & Quick Action Bar -->
    <div class="bg-white rounded-2xl border border-[#E2D9CC] p-5 lg:p-6 shadow-sm flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
            <div class="flex items-center gap-2">
                <span class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-[#E3F2EA] text-[#1B6E45]">
                    <span class="w-1.5 h-1.5 rounded-full bg-[#1B6E45] animate-pulse"></span>
                    Sistem Operasional Aktif
                </span>
                <span class="text-xs text-[#5A5146] font-mono">Xendit Escrow API v2 • Terkoneksi</span>
            </div>
            <h2 class="mt-2 text-xl lg:text-2xl font-bold text-[#1F1B16] tracking-tight">
                Selamat Datang kembali, Administrator Pramu
            </h2>
            <p class="text-xs sm:text-sm text-[#5A5146] mt-0.5">
                Pantau verifikasi identitas (KTP/SKCK), transaksi penampung escrow, jadwal Google Meet, dan aktivitas tenaga kerja secara real-time.
            </p>
        </div>

        <div class="flex items-center gap-2.5 flex-wrap">
            <div class="inline-flex items-center rounded-lg border border-[#E2D9CC] bg-[#FAF7F2] p-1 text-xs">
                <button type="button" class="px-3 py-1 font-medium bg-white rounded-md shadow-xs text-[#1F1B16]">Bulan Ini</button>
                <button type="button" class="px-3 py-1 font-medium text-[#5A5146] hover:text-[#1F1B16]">Kuartal Ini</button>
                <button type="button" class="px-3 py-1 font-medium text-[#5A5146] hover:text-[#1F1B16]">Tahun Ini</button>
            </div>
            <a href="{{ route('admin.verifications.index') }}" 
               class="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-lg bg-[#244C7C] text-white text-xs font-semibold shadow-xs hover:bg-[#1a385c] transition-colors">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                Antrean KTP ({{ $stats['pending_verifications'] }})
            </a>
        </div>
    </div>

    <!-- ROW 1: Employee Status & Overview Statistics (Equivalent to SmartHR Header Cards) -->
    <div class="grid grid-cols-1 lg:grid-cols-12 gap-6">

        <!-- Card 1: Status & Tipe Pengguna (Employee Status & Type equivalent) - 5 cols -->
        <div class="lg:col-span-5 bg-white rounded-2xl border border-[#E2D9CC] p-5 lg:p-6 shadow-sm flex flex-col justify-between">
            <div>
                <div class="flex items-center justify-between pb-3 border-b border-[#E2D9CC]/60">
                    <div>
                        <h3 class="text-sm font-bold text-[#1F1B16] uppercase tracking-wide">Status & Tipe Pengguna</h3>
                        <p class="text-xs text-[#5A5146]">Komposisi tenaga kerja & majikan terdaftar</p>
                    </div>
                    <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-semibold bg-[#E4ECF7] text-[#244C7C]">
                        {{ $stats['total_users'] }} Total Akun
                    </span>
                </div>

                <!-- Big metric -->
                <div class="mt-4 flex items-baseline justify-between">
                    <div>
                        <div class="text-3xl font-extrabold text-[#1F1B16] font-mono tracking-tight">
                            {{ $stats['total_assistants'] }}
                        </div>
                        <div class="text-xs font-medium text-[#5A5146] mt-0.5">Total Asisten Terdaftar</div>
                    </div>
                    <div class="text-right">
                        <div class="text-xl font-bold text-[#244C7C] font-mono">
                            {{ $stats['total_seekers'] }}
                        </div>
                        <div class="text-xs font-medium text-[#5A5146] mt-0.5">Pencari / Majikan</div>
                    </div>
                </div>

                <!-- Segmented Stacked Progress Bar (SmartHR Style) -->
                @php
                    $total = max($stats['total_users'], 1);
                    $pctVerified = round(($stats['verified_users'] / $total) * 100);
                    $pctPending = round(($stats['pending_verifications'] / $total) * 100);
                    $pctUnverified = max(0, 100 - $pctVerified - $pctPending);
                @endphp
                <div class="mt-5 space-y-1.5">
                    <div class="flex justify-between text-xs text-[#5A5146]">
                        <span class="font-medium text-[#1F1B16]">Tingkat Kelengkapan Verifikasi</span>
                        <span class="font-mono font-semibold text-[#1B6E45]">{{ $pctVerified }}% Terverifikasi</span>
                    </div>
                    <div class="w-full h-3 rounded-full bg-[#EAE4DC] overflow-hidden flex shadow-inner">
                        <div style="width: {{ $pctVerified }}%" class="bg-[#1B6E45] h-full transition-all duration-500" title="Terverifikasi KTP/SKCK: {{ $stats['verified_users'] }}"></div>
                        <div style="width: {{ $pctPending }}%" class="bg-[#9A4E1C] h-full transition-all duration-500" title="Menunggu Review KTP: {{ $stats['pending_verifications'] }}"></div>
                        <div style="width: {{ $pctUnverified }}%" class="bg-[#244C7C]/40 h-full transition-all duration-500" title="Belum Unggah Berkas"></div>
                    </div>
                </div>

                <!-- Breakdown Legend -->
                <div class="mt-5 grid grid-cols-3 gap-2 pt-4 border-t border-[#E2D9CC]/60 text-center">
                    <div class="p-2 rounded-lg bg-[#FAF7F2]">
                        <div class="flex items-center justify-center gap-1 text-[11px] font-medium text-[#1B6E45]">
                            <span class="w-2 h-2 rounded-full bg-[#1B6E45]"></span> Lolos
                        </div>
                        <div class="mt-1 text-sm font-bold text-[#1F1B16] font-mono">{{ $stats['verified_users'] }}</div>
                        <div class="text-[10px] text-[#5A5146]">KTP & SKCK Sah</div>
                    </div>
                    <div class="p-2 rounded-lg bg-[#FAF7F2]">
                        <div class="flex items-center justify-center gap-1 text-[11px] font-medium text-[#9A4E1C]">
                            <span class="w-2 h-2 rounded-full bg-[#9A4E1C]"></span> Antrean
                        </div>
                        <div class="mt-1 text-sm font-bold text-[#1F1B16] font-mono">{{ $stats['pending_verifications'] }}</div>
                        <div class="text-[10px] text-[#5A5146]">Menunggu Review</div>
                    </div>
                    <div class="p-2 rounded-lg bg-[#FAF7F2]">
                        <div class="flex items-center justify-center gap-1 text-[11px] font-medium text-[#5A5146]">
                            <span class="w-2 h-2 rounded-full bg-[#5A5146]"></span> Pending
                        </div>
                        <div class="mt-1 text-sm font-bold text-[#1F1B16] font-mono">{{ max(0, $stats['total_users'] - $stats['verified_users'] - $stats['pending_verifications']) }}</div>
                        <div class="text-[10px] text-[#5A5146]">Belum Submit</div>
                    </div>
                </div>
            </div>

            <div class="mt-4 pt-3 border-t border-[#E2D9CC]/60 flex items-center justify-between text-xs">
                <span class="text-[#5A5146]">Verifikasi wajib sebelum mulai melamar</span>
                <a href="{{ route('admin.verifications.index') }}" class="font-semibold text-[#244C7C] hover:underline">
                    Periksa Berkas &rarr;
                </a>
            </div>
        </div>

        <!-- Card 2: Ringkasan Finansial Escrow & Revenue (Overview Statistics equivalent) - 7 cols -->
        <div class="lg:col-span-7 bg-white rounded-2xl border border-[#E2D9CC] p-5 lg:p-6 shadow-sm flex flex-col justify-between">
            <div>
                <div class="flex items-center justify-between pb-3 border-b border-[#E2D9CC]/60">
                    <div>
                        <h3 class="text-sm font-bold text-[#1F1B16] uppercase tracking-wide">Ringkasan Finansial Escrow & Kas</h3>
                        <p class="text-xs text-[#5A5146]">Sistem rekening penampung aman berizin resmi</p>
                    </div>
                    <span class="inline-flex items-center gap-1 px-2.5 py-0.5 rounded text-xs font-semibold bg-[#E3F2EA] text-[#1B6E45]">
                        <svg class="w-3.5 h-3.5" fill="currentColor" viewBox="0 0 20 20">
                            <path fill-rule="evenodd" d="M10 1.944A11.954 11.954 0 012.166 5C2.056 5.649 2 6.319 2 7c0 5.225 3.34 9.67 8 11.317C14.66 16.67 18 12.225 18 7c0-.682-.057-1.35-.166-2.001A11.954 11.954 0 0110 1.944zM11 14a1 1 0 11-2 0 1 1 0 012 0zm0-7a1 1 0 10-2 0v4a1 1 0 102 0V7z" clip-rule="evenodd" />
                        </svg>
                        Rekening Penampung Aman
                    </span>
                </div>

                <!-- 4 KPI Sub-grid (SmartHR Style) -->
                <div class="mt-4 grid grid-cols-1 sm:grid-cols-2 gap-3.5">
                    <!-- KPI 1: Escrow Held -->
                    <div class="p-4 rounded-xl bg-[#FAF7F2] border border-[#E2D9CC]/70 hover:border-[#244C7C]/40 transition-colors">
                        <div class="flex items-center justify-between">
                            <span class="text-xs font-medium text-[#5A5146]">Dana Escrow Ditahan</span>
                            <span class="px-2 py-0.5 text-[10px] font-semibold rounded bg-[#E4ECF7] text-[#244C7C]">Tertahan</span>
                        </div>
                        <div class="mt-2 text-2xl font-bold font-mono text-[#1F1B16]">
                            Rp{{ number_format($stats['escrow_held'], 0, ',', '.') }}
                        </div>
                        <p class="mt-1 text-[11px] text-[#5A5146]">Aman hingga masa kerja diverifikasi majikan</p>
                    </div>

                    <!-- KPI 2: Escrow Settled -->
                    <div class="p-4 rounded-xl bg-[#FAF7F2] border border-[#E2D9CC]/70 hover:border-[#1B6E45]/40 transition-colors">
                        <div class="flex items-center justify-between">
                            <span class="text-xs font-medium text-[#5A5146]">Dana Sukses Dicairkan</span>
                            <span class="px-2 py-0.5 text-[10px] font-semibold rounded bg-[#E3F2EA] text-[#1B6E45]">Payout</span>
                        </div>
                        <div class="mt-2 text-2xl font-bold font-mono text-[#1B6E45]">
                            Rp{{ number_format($stats['escrow_settled'], 0, ',', '.') }}
                        </div>
                        <p class="mt-1 text-[11px] text-[#5A5146]">Ditransfer otomatis ke rekening asisten</p>
                    </div>

                    <!-- KPI 3: Platform Fees (5% + 5%) -->
                    <div class="p-4 rounded-xl bg-[#FAF7F2] border border-[#E2D9CC]/70 hover:border-[#9A4E1C]/40 transition-colors">
                        <div class="flex items-center justify-between">
                            <span class="text-xs font-medium text-[#5A5146]">Pendapatan Fee Platform</span>
                            <span class="px-2 py-0.5 text-[10px] font-semibold rounded bg-[#F8E9DC] text-[#9A4E1C]">5% + 5% Fee</span>
                        </div>
                        <div class="mt-2 text-2xl font-bold font-mono text-[#9A4E1C]">
                            Rp{{ number_format($stats['platform_fees'], 0, ',', '.') }}
                        </div>
                        <p class="mt-1 text-[11px] text-[#5A5146]">Biaya jasa sistem operasional per kontrak</p>
                    </div>

                    <!-- KPI 4: Listing Fees -->
                    <div class="p-4 rounded-xl bg-[#FAF7F2] border border-[#E2D9CC]/70 hover:border-[#5A5146]/40 transition-colors">
                        <div class="flex items-center justify-between">
                            <span class="text-xs font-medium text-[#5A5146]">Biaya Publikasi Lowongan</span>
                            <span class="px-2 py-0.5 text-[10px] font-semibold rounded bg-[#EAE4DC] text-[#5A5146]">Rp25k / Iklan</span>
                        </div>
                        <div class="mt-2 text-2xl font-bold font-mono text-[#1F1B16]">
                            Rp{{ number_format($stats['listing_fees'], 0, ',', '.') }}
                        </div>
                        <p class="mt-1 text-[11px] text-[#5A5146]">Dari {{ $stats['open_listings'] }} lowongan aktif tayang</p>
                    </div>
                </div>
            </div>

            <div class="mt-4 pt-3 border-t border-[#E2D9CC]/60 flex items-center justify-between text-xs">
                <span class="text-[#5A5146] flex items-center gap-1.5">
                    <span class="w-2 h-2 rounded-full bg-[#1B6E45]"></span>
                    SLA Pencairan Dana: Rata-rata 2.4 Jam setelah persetujuan
                </span>
                <a href="{{ route('admin.bookings.index') }}" class="font-semibold text-[#244C7C] hover:underline">
                    Rincian Kontrak Escrow &rarr;
                </a>
            </div>
        </div>
    </div>

    <!-- ROW 2: Trend Analytics & Category Distribution (Attendance Trend & Top Distribution) -->
    <div class="grid grid-cols-1 lg:grid-cols-12 gap-6">

        <!-- Card 3: Tren Escrow & Payout Mingguan (Attendance Trend equivalent) - 8 cols -->
        <div class="lg:col-span-8 bg-white rounded-2xl border border-[#E2D9CC] p-5 lg:p-6 shadow-sm">
            <div class="flex flex-col sm:flex-row sm:items-center justify-between pb-4 border-b border-[#E2D9CC]/60 gap-2">
                <div>
                    <h3 class="text-sm font-bold text-[#1F1B16] uppercase tracking-wide">Tren Escrow Inflow & Settlement Mingguan</h3>
                    <p class="text-xs text-[#5A5146]">Perbandingan volume setoran majikan vs pencairan upah asisten</p>
                </div>
                <div class="flex items-center gap-4 text-xs">
                    <div class="flex items-center gap-1.5">
                        <span class="w-3 h-3 rounded bg-[#244C7C]"></span>
                        <span class="text-[#5A5146] font-medium">Inflow (Setoran Masuk)</span>
                    </div>
                    <div class="flex items-center gap-1.5">
                        <span class="w-3 h-3 rounded bg-[#1B6E45]"></span>
                        <span class="text-[#5A5146] font-medium">Settlement (Dicairkan)</span>
                    </div>
                </div>
            </div>

            <!-- Stylized SVG Bar Chart Visualization -->
            <div class="mt-6">
                <div class="h-56 w-full flex items-end justify-between gap-3 sm:gap-6 px-2 pb-2 border-b border-[#E2D9CC]">
                    @php
                        $days = [
                            ['day' => 'Sen', 'inflow' => 85, 'payout' => 60, 'in_val' => 'Rp4.2M', 'out_val' => 'Rp3.0M'],
                            ['day' => 'Sel', 'inflow' => 65, 'payout' => 45, 'in_val' => 'Rp3.1M', 'out_val' => 'Rp2.2M'],
                            ['day' => 'Rab', 'inflow' => 95, 'payout' => 80, 'in_val' => 'Rp4.8M', 'out_val' => 'Rp4.0M'],
                            ['day' => 'Kam', 'inflow' => 70, 'payout' => 50, 'in_val' => 'Rp3.5M', 'out_val' => 'Rp2.5M'],
                            ['day' => 'Jum', 'inflow' => 100, 'payout' => 90, 'in_val' => 'Rp5.2M', 'out_val' => 'Rp4.5M'],
                            ['day' => 'Sab', 'inflow' => 80, 'payout' => 70, 'in_val' => 'Rp4.0M', 'out_val' => 'Rp3.5M'],
                            ['day' => 'Min', 'inflow' => 55, 'payout' => 40, 'in_val' => 'Rp2.8M', 'out_val' => 'Rp2.0M'],
                        ];
                    @endphp

                    @foreach($days as $item)
                        <div class="flex-1 flex flex-col items-center gap-2 group relative">
                            <!-- Tooltip hover -->
                            <div class="opacity-0 group-hover:opacity-100 transition-opacity absolute -top-12 z-10 bg-[#1F1B16] text-white text-[10px] font-mono py-1 px-2 rounded pointer-events-none whitespace-nowrap shadow-md">
                                In: {{ $item['in_val'] }} | Out: {{ $item['out_val'] }}
                            </div>

                            <!-- Dual bars -->
                            <div class="w-full flex items-end justify-center gap-1 sm:gap-2 h-44">
                                <div style="height: {{ $item['inflow'] }}%" 
                                     class="w-full max-w-[18px] bg-[#244C7C] rounded-t-sm group-hover:brightness-110 transition-all"></div>
                                <div style="height: {{ $item['payout'] }}%" 
                                     class="w-full max-w-[18px] bg-[#1B6E45] rounded-t-sm group-hover:brightness-110 transition-all"></div>
                            </div>
                            <span class="text-xs font-medium text-[#5A5146]">{{ $item['day'] }}</span>
                        </div>
                    @endforeach
                </div>

                <!-- Footer Summary KPI -->
                <div class="mt-4 grid grid-cols-3 gap-4 text-xs text-[#5A5146] pt-2">
                    <div>
                        <span class="block text-[11px] uppercase tracking-wider text-[#5A5146]">Volume Inflow Minggu Ini</span>
                        <span class="text-base font-bold text-[#244C7C] font-mono">Rp27.600.000</span>
                    </div>
                    <div>
                        <span class="block text-[11px] uppercase tracking-wider text-[#5A5146]">Volume Pencairan Bersih</span>
                        <span class="text-base font-bold text-[#1B6E45] font-mono">Rp21.700.000</span>
                    </div>
                    <div>
                        <span class="block text-[11px] uppercase tracking-wider text-[#5A5146]">Rasio Retensi Escrow</span>
                        <span class="text-base font-bold text-[#1F1B16] font-mono">99.8% Sukses</span>
                    </div>
                </div>
            </div>
        </div>

        <!-- Card 4: Distribusi Kategori Layanan (Top Distribution equivalent) - 4 cols -->
        <div class="lg:col-span-4 bg-white rounded-2xl border border-[#E2D9CC] p-5 lg:p-6 shadow-sm flex flex-col justify-between">
            <div>
                <div class="flex items-center justify-between pb-3 border-b border-[#E2D9CC]/60">
                    <div>
                        <h3 class="text-sm font-bold text-[#1F1B16] uppercase tracking-wide">Distribusi Kategori Layanan</h3>
                        <p class="text-xs text-[#5A5146]">Peminatan pencari & lowongan aktif</p>
                    </div>
                    <span class="text-xs font-semibold text-[#5A5146]">{{ $categories->count() }} Kategori</span>
                </div>

                <div class="mt-4 space-y-4">
                    @forelse($categories as $category)
                        @php
                            $catTotal = max($stats['open_listings'], 1);
                            $percentage = min(100, round(($category->listings_count / $catTotal) * 100));
                        @endphp
                        <div>
                            <div class="flex justify-between items-center text-xs mb-1.5">
                                <span class="font-medium text-[#1F1B16]">{{ $category->name }}</span>
                                <span class="text-[#5A5146] font-mono text-[11px]">
                                    <strong class="text-[#1F1B16]">{{ $category->listings_count }}</strong> Lowongan ({{ $percentage }}%)
                                </span>
                            </div>
                            <div class="w-full bg-[#EAE4DC] h-2 rounded-full overflow-hidden">
                                <div class="bg-[#244C7C] h-full rounded-full transition-all duration-300" 
                                     style="width: {{ max(10, $percentage) }}%"></div>
                            </div>
                        </div>
                    @empty
                        <div class="p-6 text-center text-xs text-[#5A5146]">
                            Belum ada data kategori lowongan.
                        </div>
                    @endforelse
                </div>
            </div>

            <div class="mt-6 pt-3 border-t border-[#E2D9CC]/60 flex items-center justify-between text-xs">
                <span class="text-[#5A5146]">Kategori tertinggi: Asisten Rumah Tangga</span>
                <span class="font-semibold text-[#1B6E45]">Permintaan Tinggi</span>
            </div>
        </div>
    </div>

    <!-- ROW 3: Operational Funnel & Live Interaction Widgets -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">

        <!-- Card 5: Funnel Rekrutmen & Pelamar (Recruitment Statistics equivalent) -->
        <div class="bg-white rounded-2xl border border-[#E2D9CC] p-5 lg:p-6 shadow-sm flex flex-col justify-between">
            <div>
                <div class="flex items-center justify-between pb-3 border-b border-[#E2D9CC]/60">
                    <div>
                        <h3 class="text-sm font-bold text-[#1F1B16] uppercase tracking-wide">Funnel Rekrutmen Tenaga Kerja</h3>
                        <p class="text-xs text-[#5A5146]">Tahapan lamaran hingga kontrak kerja</p>
                    </div>
                    <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-semibold bg-[#FAF7F2] text-[#5A5146] border border-[#E2D9CC]">
                        Alur Terverifikasi
                    </span>
                </div>

                <div class="mt-4 space-y-3">
                    <!-- Stage 1 -->
                    <div class="p-3 rounded-xl bg-[#FAF7F2] border border-[#E2D9CC]/60 flex items-center justify-between">
                        <div class="flex items-center gap-3">
                            <span class="w-7 h-7 rounded-lg bg-[#E4ECF7] text-[#244C7C] flex items-center justify-center text-xs font-bold font-mono">1</span>
                            <div>
                                <div class="text-xs font-semibold text-[#1F1B16]">Total Lamaran Masuk</div>
                                <div class="text-[11px] text-[#5A5146]">Diajukan oleh asisten terverifikasi</div>
                            </div>
                        </div>
                        <span class="text-base font-bold font-mono text-[#1F1B16]">{{ $stats['total_applications'] }}</span>
                    </div>

                    <!-- Stage 2 -->
                    <div class="p-3 rounded-xl bg-[#FAF7F2] border border-[#E2D9CC]/60 flex items-center justify-between">
                        <div class="flex items-center gap-3">
                            <span class="w-7 h-7 rounded-lg bg-[#F8E9DC] text-[#9A4E1C] flex items-center justify-center text-xs font-bold font-mono">2</span>
                            <div>
                                <div class="text-xs font-semibold text-[#1F1B16]">Lolos Seleksi Majikan</div>
                                <div class="text-[11px] text-[#5A5146]">Shortlisted oleh pembuat lowongan</div>
                            </div>
                        </div>
                        <span class="text-base font-bold font-mono text-[#9A4E1C]">{{ $stats['shortlisted_applications'] }}</span>
                    </div>

                    <!-- Stage 3 -->
                    <div class="p-3 rounded-xl bg-[#FAF7F2] border border-[#E2D9CC]/60 flex items-center justify-between">
                        <div class="flex items-center gap-3">
                            <span class="w-7 h-7 rounded-lg bg-[#E3F2EA] text-[#1B6E45] flex items-center justify-center text-xs font-bold font-mono">3</span>
                            <div>
                                <div class="text-xs font-semibold text-[#1F1B16]">Wawancara Google Meet</div>
                                <div class="text-[11px] text-[#5A5146]">Sesi tatap muka online terjadwal</div>
                            </div>
                        </div>
                        <span class="text-base font-bold font-mono text-[#1B6E45]">{{ $stats['interview_count'] }}</span>
                    </div>

                    <!-- Stage 4 -->
                    <div class="p-3 rounded-xl bg-[#FAF7F2] border border-[#E2D9CC]/60 flex items-center justify-between">
                        <div class="flex items-center gap-3">
                            <span class="w-7 h-7 rounded-lg bg-[#244C7C] text-white flex items-center justify-center text-xs font-bold font-mono">4</span>
                            <div>
                                <div class="text-xs font-semibold text-[#1F1B16]">Kontrak Escrow Diterbitkan</div>
                                <div class="text-[11px] text-[#5A5146]">Kedua belah pihak sepakat bekerja</div>
                            </div>
                        </div>
                        <span class="text-base font-bold font-mono text-[#244C7C]">{{ $stats['active_bookings'] }}</span>
                    </div>
                </div>
            </div>

            <div class="mt-4 pt-3 border-t border-[#E2D9CC]/60 text-xs text-[#5A5146] flex items-center justify-between">
                <span>Rasio Konversi Pelamar ke Kontrak</span>
                <span class="font-bold text-[#1B6E45] font-mono">75.0%</span>
            </div>
        </div>

        <!-- Card 6: Jadwal Wawancara Google Meet Terjadwal (Upcoming Interview equivalent) -->
        <div class="bg-white rounded-2xl border border-[#E2D9CC] p-5 lg:p-6 shadow-sm flex flex-col justify-between">
            <div>
                <div class="flex items-center justify-between pb-3 border-b border-[#E2D9CC]/60">
                    <div>
                        <h3 class="text-sm font-bold text-[#1F1B16] uppercase tracking-wide">Wawancara Google Meet Terdekat</h3>
                        <p class="text-xs text-[#5A5146]">Jadwal interview live online</p>
                    </div>
                    <span class="inline-flex items-center gap-1 px-2 py-0.5 rounded text-xs font-semibold bg-[#E4ECF7] text-[#244C7C]">
                        <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
                        </svg>
                        Meet Link Ready
                    </span>
                </div>

                <div class="mt-4 space-y-3">
                    @forelse($upcomingInterviews as $interview)
                        <div class="p-3.5 rounded-xl border border-[#E2D9CC] bg-[#FAF7F2] hover:bg-white transition-colors">
                            <div class="flex items-start justify-between gap-2">
                                <div>
                                    <div class="text-xs font-bold text-[#1F1B16]">
                                        {{ $interview->application?->user?->name ?? 'Kandidat Asisten' }}
                                    </div>
                                    <div class="text-[11px] text-[#5A5146]">
                                        Lowongan: {{ Str::limit($interview->application?->listing?->title ?? 'Pramu ART Rumah Tangga', 26) }}
                                    </div>
                                </div>
                                <span class="px-2 py-0.5 rounded text-[10px] font-semibold bg-[#E3F2EA] text-[#1B6E45]">
                                    {{ ucfirst($interview->status) }}
                                </span>
                            </div>

                            <div class="mt-2.5 flex items-center justify-between text-xs pt-2 border-t border-[#E2D9CC]/50">
                                <div class="flex items-center gap-1.5 text-[#5A5146] text-[11px] font-mono">
                                    <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                                    </svg>
                                    {{ $interview->scheduled_at ? $interview->scheduled_at->format('d M, H:i') : 'Segera' }} WIB
                                </div>
                                @if($interview->meeting_link)
                                    <a href="{{ $interview->meeting_link }}" target="_blank" rel="noopener noreferrer"
                                       class="inline-flex items-center gap-1 px-2.5 py-1 rounded bg-[#1B6E45] text-white text-[11px] font-medium hover:bg-[#155434] transition-colors">
                                        <span>Gabung Meet</span>
                                        <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
                                        </svg>
                                    </a>
                                @else
                                    <span class="text-[11px] text-[#5A5146] italic">Link sedang digenerate</span>
                                @endif
                            </div>
                        </div>
                    @empty
                        <div class="p-6 text-center text-xs text-[#5A5146] bg-[#FAF7F2] rounded-xl border border-dashed border-[#E2D9CC]">
                            Belum ada jadwal wawancara aktif saat ini.
                        </div>
                    @endforelse
                </div>
            </div>

            <div class="mt-4 pt-3 border-t border-[#E2D9CC]/60 text-xs text-right">
                <span class="text-[#5A5146]">Google Meet API sync otomatis</span>
            </div>
        </div>

        <!-- Card 7: Antrean Persetujuan Cepat KTP & Identitas (Pending Approvals equivalent) -->
        <div class="bg-white rounded-2xl border border-[#E2D9CC] p-5 lg:p-6 shadow-sm flex flex-col justify-between">
            <div>
                <div class="flex items-center justify-between pb-3 border-b border-[#E2D9CC]/60">
                    <div>
                        <h3 class="text-sm font-bold text-[#1F1B16] uppercase tracking-wide">Persetujuan Cepat Identitas KTP</h3>
                        <p class="text-xs text-[#5A5146]">Tinjau dan setujui langsung dari dashboard</p>
                    </div>
                    <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-semibold bg-[#F8E9DC] text-[#9A4E1C]">
                        {{ $pendingVerifications->count() }} Antrean
                    </span>
                </div>

                <div class="mt-4 space-y-3">
                    @forelse($pendingVerifications->take(3) as $verif)
                        <div class="p-3.5 rounded-xl border border-[#E2D9CC] bg-[#FAF7F2]">
                            <div class="flex items-center justify-between">
                                <div class="flex items-center gap-2.5">
                                    <div class="w-8 h-8 rounded-full bg-[#244C7C] text-white flex items-center justify-center font-bold text-xs">
                                        {{ strtoupper(substr($verif->user->name, 0, 1)) }}
                                    </div>
                                    <div>
                                        <div class="text-xs font-bold text-[#1F1B16]">{{ $verif->user->name }}</div>
                                        <div class="text-[10px] text-[#5A5146] font-mono">
                                            NIK: {{ substr($verif->nik, 0, 6) }}****** ({{ ucfirst($verif->user->active_role) }})
                                        </div>
                                    </div>
                                </div>
                                <span class="text-[10px] text-[#5A5146]">{{ $verif->created_at->diffForHumans() }}</span>
                            </div>

                            <div class="mt-3 flex items-center justify-end gap-2 pt-2 border-t border-[#E2D9CC]/50">
                                <a href="{{ route('admin.verifications.show', $verif->id) }}" 
                                   class="px-2.5 py-1 rounded border border-[#E2D9CC] bg-white text-xs font-medium text-[#1F1B16] hover:bg-[#FAF7F2]">
                                    Tinjau
                                </a>
                                <form action="{{ route('admin.verifications.approve', $verif->id) }}" method="POST" class="inline">
                                    @csrf
                                    <button type="submit" 
                                            onclick="return confirm('Konfirmasi persetujuan verifikasi KTP untuk {{ $verif->user->name }}?')"
                                            class="px-3 py-1 rounded bg-[#1B6E45] text-white text-xs font-semibold hover:bg-[#155434] transition-colors">
                                        Setujui
                                    </button>
                                </form>
                            </div>
                        </div>
                    @empty
                        <div class="p-6 text-center text-xs text-[#5A5146] bg-[#FAF7F2] rounded-xl border border-dashed border-[#E2D9CC]">
                            Semua berkas identitas telah selesai ditinjau.
                        </div>
                    @endforelse
                </div>
            </div>

            <div class="mt-4 pt-3 border-t border-[#E2D9CC]/60 flex items-center justify-between text-xs">
                <span class="text-[#5A5146]">Pemeriksaan sesuai standar Dukcapil</span>
                <a href="{{ route('admin.verifications.index') }}" class="font-semibold text-[#244C7C] hover:underline">
                    Buka Antrean Lengkap &rarr;
                </a>
            </div>
        </div>
    </div>

    <!-- ROW 4: Live Contracts & Dispute Oversight (Late Arrivals & Disputes equivalent) -->
    <div class="grid grid-cols-1 lg:grid-cols-12 gap-6">

        <!-- Card 8: Kontrak Escrow Aktif Berjalan (8 cols) -->
        <div class="lg:col-span-8 bg-white rounded-2xl border border-[#E2D9CC] p-5 lg:p-6 shadow-sm overflow-hidden">
            <div class="flex items-center justify-between pb-3 border-b border-[#E2D9CC]/60">
                <div>
                    <h3 class="text-sm font-bold text-[#1F1B16] uppercase tracking-wide">Aktivitas Kontrak Escrow & Masa Kerja Berjalan</h3>
                    <p class="text-xs text-[#5A5146]">Pemantauan periode kerja dan jaminan dana tertahan</p>
                </div>
                <a href="{{ route('admin.bookings.index') }}" class="text-xs font-semibold text-[#244C7C] hover:underline">
                    Semua Kontrak &rarr;
                </a>
            </div>

            <div class="mt-4 overflow-x-auto">
                <table class="w-full text-left text-xs text-[#1F1B16]">
                    <thead class="bg-[#FAF7F2] uppercase font-semibold text-[#5A5146] border-b border-[#E2D9CC]">
                        <tr>
                            <th class="px-4 py-3">Pencari (Majikan)</th>
                            <th class="px-4 py-3">Tenaga Asisten</th>
                            <th class="px-4 py-3">Kategori</th>
                            <th class="px-4 py-3">Nilai Kontrak</th>
                            <th class="px-4 py-3">Periode Escrow</th>
                            <th class="px-4 py-3 text-right">Status</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-[#E2D9CC]/60">
                        @forelse($activeBookings as $booking)
                            <tr class="hover:bg-[#FAF7F2]/60 transition-colors">
                                <td class="px-4 py-3 font-semibold">{{ $booking->seeker?->name ?? 'Majikan' }}</td>
                                <td class="px-4 py-3 font-medium">{{ $booking->assistant?->name ?? 'Asisten' }}</td>
                                <td class="px-4 py-3 text-[#5A5146]">{{ $booking->listing?->category?->name ?? 'Layanan Rumah Tangga' }}</td>
                                <td class="px-4 py-3 font-mono font-bold text-[#244C7C]">
                                    Rp{{ number_format($booking->total_agreed_rate, 0, ',', '.') }}
                                </td>
                                <td class="px-4 py-3">
                                    <span class="inline-flex items-center px-2 py-0.5 rounded text-[10px] font-mono font-medium bg-[#EAE4DC] text-[#1F1B16]">
                                        {{ $booking->periods?->count() ?? 1 }} Periode
                                    </span>
                                </td>
                                <td class="px-4 py-3 text-right">
                                    <span class="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-semibold {{ $booking->status === 'active' ? 'bg-[#E3F2EA] text-[#1B6E45]' : 'bg-[#E4ECF7] text-[#244C7C]' }}">
                                        {{ strtoupper($booking->status) }}
                                    </span>
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="6" class="px-4 py-8 text-center text-xs text-[#5A5146]">
                                    Belum ada kontrak berjalan yang aktif saat ini.
                                </td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>

        <!-- Card 9: Sengketa & Perlindungan Mediasi (4 cols) -->
        <div class="lg:col-span-4 bg-white rounded-2xl border border-[#E2D9CC] p-5 lg:p-6 shadow-sm flex flex-col justify-between">
            <div>
                <div class="flex items-center justify-between pb-3 border-b border-[#E2D9CC]/60">
                    <div>
                        <h3 class="text-sm font-bold text-[#1F1B16] uppercase tracking-wide">Pusat Mediasi & Sengketa</h3>
                        <p class="text-xs text-[#5A5146]">Perlindungan hak kedua pihak</p>
                    </div>
                    @if($stats['open_disputes'] > 0)
                        <span class="px-2 py-0.5 rounded text-xs font-semibold bg-[#FBE5E3] text-[#B3261E]">
                            {{ $stats['open_disputes'] }} Butuh Aksi
                        </span>
                    @else
                        <span class="px-2 py-0.5 rounded text-xs font-semibold bg-[#E3F2EA] text-[#1B6E45]">
                            Aman
                        </span>
                    @endif
                </div>

                <div class="mt-4 space-y-3">
                    @forelse($recentReports as $report)
                        <div class="p-3.5 rounded-xl border border-[#E2D9CC] bg-[#FAF7F2]">
                            <div class="flex items-center justify-between">
                                <span class="text-xs font-bold text-[#B3261E]">Laporan #{{ substr($report->id, 0, 8) }}</span>
                                <span class="text-[10px] text-[#5A5146]">{{ $report->created_at->diffForHumans() }}</span>
                            </div>
                            <div class="mt-1 text-xs text-[#1F1B16] line-clamp-2">
                                {{ $report->reason }}
                            </div>
                            <div class="mt-2.5 flex items-center justify-between text-[11px] pt-2 border-t border-[#E2D9CC]/50">
                                <span class="text-[#5A5146]">Pelapor: {{ $report->reporter?->name ?? 'Pengguna' }}</span>
                                <a href="{{ route('admin.reports.index') }}" class="font-semibold text-[#244C7C] hover:underline">
                                    Mediasi &rarr;
                                </a>
                            </div>
                        </div>
                    @empty
                        <div class="p-6 text-center text-xs text-[#5A5146] bg-[#FAF7F2] rounded-xl border border-dashed border-[#E2D9CC]">
                            Tidak ada sengketa atau keluhan yang sedang berlangsung. Tingkat kepuasan 100%.
                        </div>
                    @endforelse
                </div>
            </div>

            <div class="mt-4 pt-3 border-t border-[#E2D9CC]/60 text-xs text-[#5A5146]">
                <p class="text-[11px] leading-relaxed">
                    Sesuai PRD, inspeksi riwayat chat hanya dapat diakses dengan persetujuan 7 hari (chat consent) kedua belah pihak.
                </p>
            </div>
        </div>
    </div>

</div>
@endsection

