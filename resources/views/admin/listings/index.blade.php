@extends('admin.layout')

@section('title', 'Lowongan Kerja Aktif')
@section('header', 'Kelola Lowongan Kerja Majikan')

@section('content')
<div class="space-y-6">
    <!-- Filter Tabs & Search Bar -->
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <!-- Tabs -->
        <div class="flex items-center gap-2 border-b border-[#E2D9CC] pb-1 text-xs">
            <a href="{{ route('admin.listings.index', ['status' => 'all', 'search' => $search]) }}" 
               class="px-3.5 py-2 rounded-lg font-medium transition-colors {{ $status === 'all' ? 'bg-[#244C7C] text-white' : 'text-[#5A5146] hover:bg-[#F3EEE6]' }}">
                Semua Lowongan ({{ $counts['all'] }})
            </a>
            <a href="{{ route('admin.listings.index', ['status' => 'open', 'search' => $search]) }}" 
               class="px-3.5 py-2 rounded-lg font-medium transition-colors {{ $status === 'open' ? 'bg-[#244C7C] text-white' : 'text-[#5A5146] hover:bg-[#F3EEE6]' }}">
                Tayang Aktif ({{ $counts['open'] }})
            </a>
            <a href="{{ route('admin.listings.index', ['status' => 'closed', 'search' => $search]) }}" 
               class="px-3.5 py-2 rounded-lg font-medium transition-colors {{ $status === 'closed' ? 'bg-[#244C7C] text-white' : 'text-[#5A5146] hover:bg-[#F3EEE6]' }}">
                Ditutup / Selesai ({{ $counts['closed'] }})
            </a>
        </div>

        <!-- Search Form -->
        <form method="GET" action="{{ route('admin.listings.index') }}" class="flex items-center gap-2">
            <input type="hidden" name="status" value="{{ $status }}">
            <div class="relative">
                <input type="text" name="search" value="{{ $search }}" placeholder="Cari judul, kota, area..." 
                       class="text-xs pl-8 pr-3 py-2 bg-white rounded-lg border border-[#E2D9CC] focus:border-[#244C7C] outline-none">
                <svg class="w-4 h-4 absolute left-2.5 top-1/2 -translate-y-1/2 text-[#8C8070]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                </svg>
            </div>
            <button type="submit" class="px-3 py-2 bg-[#FAF7F2] hover:bg-[#EAE4DC] border border-[#E2D9CC] rounded-lg text-xs font-semibold text-[#1F1B16]">
                Cari
            </button>
            @if($search)
                <a href="{{ route('admin.listings.index', ['status' => $status]) }}" class="text-xs text-[#B3261E] hover:underline">Reset</a>
            @endif
        </form>
    </div>

    <!-- Table Card -->
    <div class="bg-white rounded-2xl border border-[#E2D9CC] shadow-sm overflow-hidden">
        <div class="px-6 py-4 border-b border-[#E2D9CC] flex items-center justify-between">
            <div>
                <h3 class="text-sm font-bold text-[#1F1B16] uppercase tracking-wide">Daftar Lowongan Pekerjaan</h3>
                <p class="text-xs text-[#5A5146]">Monitoring penawaran kerja dari majikan pencari asisten</p>
            </div>
            <span class="text-xs text-[#5A5146] font-mono">Total: {{ $listings->total() }} lowongan</span>
        </div>

        @if($listings->isEmpty())
            <div class="p-12 text-center text-[#5A5146]">
                <p class="text-sm">Tidak ditemukan data lowongan kerja.</p>
            </div>
        @else
            <div class="overflow-x-auto">
                <table class="w-full text-left text-xs text-[#1F1B16]">
                    <thead class="bg-[#FAF7F2] uppercase font-semibold text-[#5A5146] border-b border-[#E2D9CC]">
                        <tr>
                            <th class="px-6 py-3.5">Judul Lowongan & Pembuat</th>
                            <th class="px-6 py-3.5">Kategori & Lokasi</th>
                            <th class="px-6 py-3.5">Tawaran Gaji</th>
                            <th class="px-6 py-3.5">Pelamar</th>
                            <th class="px-6 py-3.5">Biaya Iklan (Rp25k)</th>
                            <th class="px-6 py-3.5 text-right">Status</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-[#E2D9CC]/60">
                        @foreach($listings as $l)
                            <tr class="hover:bg-[#FAF7F2]/50 transition-colors">
                                <td class="px-6 py-4">
                                    <div class="font-bold text-[#1F1B16] text-sm">{{ $l->title }}</div>
                                    <div class="text-[11px] text-[#5A5146] mt-0.5">
                                        Oleh: <strong>{{ $l->user?->name ?? 'Majikan' }}</strong> ({{ $l->created_at->format('d M Y') }})
                                    </div>
                                </td>
                                <td class="px-6 py-4">
                                    <span class="inline-flex items-center px-2 py-0.5 rounded text-[11px] font-semibold bg-[#FAF7F2] text-[#244C7C] border border-[#E2D9CC]">
                                        {{ $l->category?->name ?? 'Layanan Rumah Tangga' }}
                                    </span>
                                    <div class="text-[11px] text-[#5A5146] mt-1">
                                        {{ $l->district }}, {{ $l->city }}
                                    </div>
                                </td>
                                <td class="px-6 py-4 font-mono font-bold text-[#1F1B16]">
                                    Rp{{ number_format($l->min_salary, 0, ',', '.') }} - Rp{{ number_format($l->max_salary, 0, ',', '.') }}
                                    <span class="block text-[10px] font-normal text-[#5A5146] font-sans">per bulan</span>
                                </td>
                                <td class="px-6 py-4">
                                    <span class="inline-flex items-center px-2 py-0.5 rounded-full text-[11px] font-semibold bg-[#E4ECF7] text-[#244C7C]">
                                        {{ $l->applications_count }} Pelamar
                                    </span>
                                </td>
                                <td class="px-6 py-4">
                                    @if($l->paid_at)
                                        <span class="inline-flex items-center gap-1 text-[11px] font-semibold text-[#1B6E45]">
                                            <svg class="w-3.5 h-3.5" fill="currentColor" viewBox="0 0 20 20">
                                                <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
                                            </svg>
                                            Lunas Rp25.000
                                        </span>
                                    @else
                                        <span class="text-[11px] text-[#9A4E1C] font-medium">Gratis / Promo</span>
                                    @endif
                                </td>
                                <td class="px-6 py-4 text-right">
                                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-[10px] font-bold {{ $l->status === 'open' ? 'bg-[#E3F2EA] text-[#1B6E45]' : 'bg-[#EAE4DC] text-[#5A5146]' }}">
                                        {{ strtoupper($l->status) }}
                                    </span>
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>

            <div class="px-6 py-4 border-t border-[#E2D9CC]">
                {{ $listings->links() }}
            </div>
        @endif
    </div>
</div>
@endsection
