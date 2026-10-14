@extends('admin.layout')

@section('title', 'Lowongan Kerja Aktif')

@section('content')
<div class="space-y-6">

    {{-- Page Hero Header on Ocean Canvas --}}
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
            <div class="flex items-center gap-2 mb-1">
                <span class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-white/10 text-sky-200 border border-white/15 backdrop-blur-xs">
                    <span class="w-1.5 h-1.5 rounded-full bg-cyan-400"></span>
                    Marketplace Tenaga Kerja
                </span>
            </div>
            <h1 class="text-2xl font-bold text-white tracking-tight">Lowongan Kerja</h1>
            <p class="text-sm text-sky-100/90 mt-0.5">Monitoring penawaran kerja dari majikan pencari asisten secara real-time</p>
        </div>
        <div class="flex items-center gap-3">
            <div class="flex items-center gap-2 text-xs text-white bg-white/10 border border-white/15 px-3.5 py-2 rounded-xl backdrop-blur-xs shadow-inner">
                <span class="text-sky-200 font-medium">Total:</span>
                <span class="font-bold font-mono text-white text-sm">{{ $listings->total() }}</span>
                <span class="text-sky-200">lowongan</span>
            </div>
        </div>
    </div>

    {{-- Filter Tabs & Search Bar Card --}}
    <div class="bg-white rounded-2xl border border-slate-100 p-5 shadow-md">
        <div class="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
            {{-- Tabs --}}
            <div class="flex flex-wrap items-center gap-2">
                <a href="{{ route('admin.listings.index', ['status' => 'all', 'search' => $search]) }}" 
                   class="px-3.5 py-2 rounded-xl text-xs font-semibold transition-all {{ $status === 'all' ? 'bg-[#082032] text-white shadow-sm' : 'text-slate-600 bg-slate-50 border border-slate-200/80 hover:bg-slate-100' }}">
                    Semua ({{ $counts['all'] }})
                </a>
                <a href="{{ route('admin.listings.index', ['status' => 'open', 'search' => $search]) }}" 
                   class="px-3.5 py-2 rounded-xl text-xs font-semibold transition-all {{ $status === 'open' ? 'bg-[#FF6B35] text-white shadow-sm' : 'text-slate-600 bg-slate-50 border border-slate-200/80 hover:bg-slate-100' }}">
                    Tayang Aktif ({{ $counts['open'] }})
                </a>
                <a href="{{ route('admin.listings.index', ['status' => 'draft', 'search' => $search]) }}" 
                   class="px-3.5 py-2 rounded-xl text-xs font-semibold transition-all {{ $status === 'draft' ? 'bg-[#082032] text-white shadow-sm' : 'text-slate-600 bg-slate-50 border border-slate-200/80 hover:bg-slate-100' }}">
                    Draf / Belum Bayar ({{ $counts['draft'] ?? 0 }})
                </a>
            </div>

            {{-- Search Form --}}
            <form method="GET" action="{{ route('admin.listings.index') }}" class="flex items-center gap-2.5">
                <input type="hidden" name="status" value="{{ $status }}">
                <div class="relative flex-1 sm:w-64">
                    <svg class="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
                    </svg>
                    <input type="text" name="search" value="{{ $search }}" placeholder="Cari judul, kota, area..." 
                           class="w-full text-xs pl-9 pr-3.5 py-2 bg-slate-50 rounded-xl border border-slate-200 focus:bg-white focus:border-[#FF6B35] focus:ring-1 focus:ring-[#FF6B35] outline-none transition-all placeholder:text-slate-400 text-slate-800">
                </div>
                <button type="submit" class="px-4 py-2 bg-[#FF6B35] hover:bg-[#fa5a1f] text-white rounded-xl text-xs font-semibold transition-all shadow-sm">
                    Cari
                </button>
                @if($search)
                    <a href="{{ route('admin.listings.index', ['status' => $status]) }}" class="text-xs text-rose-600 font-medium hover:underline px-1">
                        Reset
                    </a>
                @endif
            </form>
        </div>
    </div>

    {{-- Main Listings Table Card --}}
    <div class="bg-white rounded-2xl border border-slate-100 shadow-md overflow-hidden">
        <div class="px-6 py-4.5 border-b border-slate-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3 bg-gradient-to-r from-slate-50/50 to-white">
            <div>
                <h3 class="text-base font-bold text-slate-900 tracking-tight">Daftar Lowongan Pekerjaan</h3>
                <p class="text-xs text-slate-500 mt-0.5">Penawaran kerja dari majikan yang sedang aktif maupun draf</p>
            </div>
            <span class="text-xs text-slate-600 font-mono bg-slate-100/80 border border-slate-200 px-3 py-1 rounded-xl self-start sm:self-center">
                {{ $listings->total() }} lowongan ditemukan
            </span>
        </div>

        @if($listings->isEmpty())
            <div class="p-16 text-center">
                <div class="w-14 h-14 rounded-2xl bg-slate-100 flex items-center justify-center mx-auto mb-3.5 text-slate-400">
                    <svg class="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"/>
                    </svg>
                </div>
                <h4 class="text-sm font-bold text-slate-900">Tidak ditemukan data lowongan kerja</h4>
                <p class="text-xs text-slate-500 mt-1 max-w-sm mx-auto">Coba sesuaikan kata kunci pencarian atau ganti filter status di tab atas.</p>
            </div>
        @else
            <div class="overflow-x-auto">
                <table class="w-full text-left text-xs text-slate-800 whitespace-nowrap">
                    <thead class="bg-slate-50/90 border-b border-slate-200/80">
                        <tr>
                            <th class="px-6 py-3.5 text-[11px] font-bold text-slate-700 uppercase tracking-wider whitespace-nowrap">Judul Lowongan & Pembuat</th>
                            <th class="px-6 py-3.5 text-[11px] font-bold text-slate-700 uppercase tracking-wider whitespace-nowrap">Kategori & Lokasi</th>
                            <th class="px-6 py-3.5 text-[11px] font-bold text-slate-700 uppercase tracking-wider whitespace-nowrap">Tawaran Gaji</th>
                            <th class="px-6 py-3.5 text-[11px] font-bold text-slate-700 uppercase tracking-wider whitespace-nowrap">Pelamar</th>
                            <th class="px-6 py-3.5 text-[11px] font-bold text-slate-700 uppercase tracking-wider whitespace-nowrap">Biaya Iklan (Rp25k)</th>
                            <th class="px-6 py-3.5 text-[11px] font-bold text-slate-700 uppercase tracking-wider whitespace-nowrap">Status</th>
                            <th class="px-6 py-3.5 text-[11px] font-bold text-slate-700 uppercase tracking-wider text-right whitespace-nowrap">Aksi</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-100">
                        @foreach($listings as $l)
                            <tr class="hover:bg-sky-50/30 transition-colors">
                                <td class="px-6 py-4">
                                    <div class="font-bold text-slate-900 text-sm hover:text-[#0C5D8F] transition-colors">
                                        {{ $l->title }}
                                    </div>
                                    <div class="text-[11px] text-slate-600 mt-0.5 flex items-center gap-1.5">
                                        <span>Oleh: <strong class="text-slate-800 font-semibold">{{ $l->user?->name ?? 'Majikan' }}</strong></span>
                                        <span>&bull;</span>
                                        <span class="font-mono text-slate-500">{{ $l->created_at->format('d M Y') }}</span>
                                    </div>
                                </td>
                                <td class="px-6 py-4">
                                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-lg text-[11px] font-semibold bg-cyan-50 text-cyan-800 border border-cyan-200/60">
                                        {{ $l->category?->name ?? 'Layanan Rumah Tangga' }}
                                    </span>
                                    <div class="text-[11px] text-slate-500 mt-1 flex items-center gap-1">
                                        <svg class="w-3 h-3 text-slate-400 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"/>
                                        </svg>
                                        <span>{{ $l->city_name ?? ($l->district . ', ' . $l->city) }}</span>
                                    </div>
                                </td>
                                <td class="px-6 py-4 font-mono whitespace-nowrap">
                                    <div class="font-bold text-slate-900">
                                        Rp{{ number_format($l->budget_min ?? $l->min_salary ?? 0, 0, ',', '.') }} - Rp{{ number_format($l->budget_max ?? $l->max_salary ?? 0, 0, ',', '.') }}
                                    </div>
                                    <span class="text-[10px] text-slate-400 font-sans">per bulan</span>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <span class="inline-flex items-center px-2.5 py-1 rounded-full text-[11px] font-semibold bg-sky-50 text-sky-700 border border-sky-100">
                                        {{ $l->applications_count }} Pelamar
                                    </span>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    @if($l->paid_at)
                                        <span class="inline-flex items-center gap-1.5 text-xs font-semibold text-emerald-700">
                                            <svg class="w-4 h-4 text-emerald-600" fill="currentColor" viewBox="0 0 20 20">
                                                <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
                                            </svg>
                                            Lunas Rp25.000
                                        </span>
                                    @else
                                        <span class="text-xs text-amber-700 font-medium bg-amber-50 px-2 py-0.5 rounded-md border border-amber-200/50">
                                            Gratis / Promo
                                        </span>
                                    @endif
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-[11px] font-bold {{ $l->status === 'open' ? 'bg-emerald-50 text-emerald-700 border border-emerald-200/60' : 'bg-slate-100 text-slate-600 border border-slate-200' }}">
                                        @if($l->status === 'open')
                                            <span class="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse"></span>
                                        @endif
                                        {{ strtoupper($l->status) }}
                                    </span>
                                </td>
                                <td class="px-6 py-4 text-right whitespace-nowrap">
                                    <a href="{{ route('admin.listings.show', $l->id) }}" 
                                       class="inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl bg-[#082032] hover:bg-[#FF6B35] text-white text-xs font-bold transition-all shadow-xs group">
                                        <span>Lihat Detail</span>
                                        <svg class="w-3.5 h-3.5 transition-transform group-hover:translate-x-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
                                        </svg>
                                    </a>
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>

            <div class="px-6 py-4 border-t border-slate-100 bg-slate-50/40">
                {{ $listings->links() }}
            </div>
        @endif
    </div>
</div>
@endsection
