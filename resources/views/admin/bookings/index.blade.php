@extends('admin.layout')

@section('title', 'Daftar Kontrak Kerja')

@section('content')
<div class="space-y-6">

    {{-- Page Hero Header on Ocean Canvas --}}
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
            <div class="flex items-center gap-2 mb-1">
                <span class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-white/10 text-sky-200 border border-white/15 backdrop-blur-xs">
                    <span class="w-1.5 h-1.5 rounded-full bg-cyan-400"></span>
                    Sistem Perjanjian & Escrow
                </span>
            </div>
            <h1 class="text-2xl font-bold text-white tracking-tight">Daftar Kontrak Kerja</h1>
            <p class="text-sm text-sky-100/90 mt-0.5">Pengawasan perjanjian kerja resmi antara majikan dan asisten beserta proteksi escrow</p>
        </div>
        <div class="flex items-center gap-2">
            <div class="flex items-center gap-2 text-xs text-white bg-white/10 border border-white/15 px-3.5 py-2 rounded-xl backdrop-blur-xs shadow-inner">
                <span class="text-sky-200 font-medium">Total Kontrak:</span>
                <strong class="font-bold font-mono text-white text-sm">{{ $bookings->total() }}</strong>
            </div>
        </div>
    </div>

    {{-- Penjelasan Edukatif Sistem Escrow & Termin --}}
    <div class="bg-white rounded-2xl border border-slate-100 p-6 shadow-md text-xs text-slate-600 space-y-3.5">
        <div class="flex items-center gap-2 text-slate-900 font-bold text-xs uppercase tracking-wider">
            <div class="w-6 h-6 rounded-lg bg-sky-50 text-[#0C5D8F] flex items-center justify-center shrink-0">
                <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                </svg>
            </div>
            <span>Panduan Periode Kerja & Titip Gaji (Escrow):</span>
        </div>
        <p class="leading-relaxed text-slate-600">
            <strong class="text-slate-900">Escrow</strong> adalah rekening penampungan aman Pramu di mana gaji dititipkan terlebih dahulu oleh majikan sebelum periode kerja dimulai. 
            Gaji aman dan baru dicairkan ke rekening asisten setelah periode kerja tersebut tuntas diverifikasi tanpa sengketa.
        </p>
        <div class="flex flex-wrap items-center gap-3 pt-3 border-t border-slate-100">
            <span class="text-xs font-bold text-slate-700 uppercase tracking-wider">Status Termin:</span>
            <span class="inline-flex items-center gap-1.5 text-xs text-emerald-950 font-semibold bg-emerald-100 px-2.5 py-1 rounded-lg border border-emerald-300/80">
                <span class="w-4 h-4 rounded-md bg-emerald-600 text-white flex items-center justify-center text-[10px] font-bold">1</span>
                Dicairkan (Settled)
            </span>
            <span class="inline-flex items-center gap-1.5 text-xs text-sky-950 font-semibold bg-sky-100 px-2.5 py-1 rounded-lg border border-sky-300/80">
                <span class="w-4 h-4 rounded-md bg-[#0C5D8F] text-white flex items-center justify-center text-[10px] font-bold">2</span>
                Tertahan Aman (Held/Paid)
            </span>
            <span class="inline-flex items-center gap-1.5 text-xs text-rose-950 font-semibold bg-rose-100 px-2.5 py-1 rounded-lg border border-rose-300/80">
                <span class="w-4 h-4 rounded-md bg-rose-600 text-white flex items-center justify-center text-[10px] font-bold">!</span>
                Ada Sengketa (Disputed)
            </span>
            <span class="inline-flex items-center gap-1.5 text-xs text-slate-800 font-semibold bg-slate-100 px-2.5 py-1 rounded-lg border border-slate-300/80">
                <span class="w-4 h-4 rounded-md bg-slate-300 text-slate-700 flex items-center justify-center text-[10px] font-bold">-</span>
                Menunggu Pembayaran
            </span>
        </div>
    </div>

    {{-- Contracts Table Card --}}
    <div class="bg-white rounded-2xl border border-slate-100 shadow-md overflow-hidden">
        <div class="px-6 py-4.5 border-b border-slate-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3 bg-gradient-to-r from-slate-50/50 to-white">
            <div>
                <h3 class="text-base font-bold text-slate-900 tracking-tight">Daftar Kontrak Kerja & Status Escrow</h3>
                <p class="text-xs text-slate-500 mt-0.5">Melacak dana yang ditahan dan termin pembayaran per periode</p>
            </div>
            <span class="text-xs text-slate-600 font-mono bg-slate-100/80 border border-slate-200 px-3 py-1 rounded-xl self-start sm:self-center">
                {{ $bookings->total() }} kontrak aktif
            </span>
        </div>

        @if($bookings->isEmpty())
            <div class="p-16 text-center">
                <div class="w-14 h-14 rounded-2xl bg-slate-100 flex items-center justify-center mx-auto mb-3.5 text-slate-400">
                    <svg class="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4"/>
                    </svg>
                </div>
                <h4 class="text-sm font-bold text-slate-900">Belum ada kontrak kerja</h4>
                <p class="text-xs text-slate-500 mt-1 max-w-sm mx-auto">Kontrak kerja akan muncul saat ada kesepakatan kerja antara majikan dan asisten.</p>
            </div>
        @else
            <div class="overflow-x-auto">
                <table class="w-full text-left text-xs text-slate-800 whitespace-nowrap">
                    <thead class="bg-slate-50/90 border-b border-slate-200/80">
                        <tr>
                            <th class="px-6 py-3.5 text-[11px] font-bold text-slate-700 uppercase tracking-wider whitespace-nowrap">ID Kontrak</th>
                            <th class="px-6 py-3.5 text-[11px] font-bold text-slate-700 uppercase tracking-wider whitespace-nowrap">Pencari (Majikan)</th>
                            <th class="px-6 py-3.5 text-[11px] font-bold text-slate-700 uppercase tracking-wider whitespace-nowrap">Asisten</th>
                            <th class="px-6 py-3.5 text-[11px] font-bold text-slate-700 uppercase tracking-wider whitespace-nowrap">Pekerjaan</th>
                            <th class="px-6 py-3.5 text-[11px] font-bold text-slate-700 uppercase tracking-wider whitespace-nowrap">Total Kontrak</th>
                            <th class="px-6 py-3.5 text-[11px] font-bold text-slate-700 uppercase tracking-wider whitespace-nowrap">Status Kontrak</th>
                            <th class="px-6 py-3.5 text-[11px] font-bold text-slate-700 uppercase tracking-wider whitespace-nowrap">Periode & Escrow</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-100">
                        @foreach($bookings as $b)
                            <tr class="hover:bg-sky-50/30 transition-colors">
                                <td class="px-6 py-4 font-mono text-[11px] font-bold text-slate-500">
                                    {{ substr($b->id, 0, 10) }}...
                                </td>
                                <td class="px-6 py-4">
                                    <div class="font-bold text-slate-900">{{ $b->seeker?->name ?? 'Pencari' }}</div>
                                    <div class="text-[11px] text-slate-500 font-mono mt-0.5">{{ $b->seeker?->phone ?? '-' }}</div>
                                </td>
                                <td class="px-6 py-4">
                                    <div class="font-bold text-slate-900">{{ $b->assistant?->name ?? 'Asisten' }}</div>
                                    <div class="text-[11px] text-slate-500 font-mono mt-0.5">{{ $b->assistant?->phone ?? '-' }}</div>
                                </td>
                                <td class="px-6 py-4 text-slate-600">
                                    <span class="font-medium text-slate-900">{{ $b->listing?->title ?? '-' }}</span>
                                </td>
                                <td class="px-6 py-4 font-mono font-bold text-slate-900 whitespace-nowrap">
                                    Rp{{ number_format($b->total_amount, 0, ',', '.') }}
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-[10px] font-bold {{ $b->status === 'active' ? 'bg-emerald-50 text-emerald-700 border border-emerald-200/60' : ($b->status === 'disputed' ? 'bg-rose-50 text-rose-700 border border-rose-200/60' : 'bg-sky-50 text-sky-700 border border-sky-200/60') }}">
                                        @if($b->status === 'active')
                                            <span class="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse"></span>
                                        @endif
                                        {{ ucfirst($b->status) }}
                                    </span>
                                </td>
                                <td class="px-6 py-4">
                                    <div class="flex items-center gap-1.5 flex-wrap">
                                        @foreach($b->periods as $p)
                                            <span title="Periode #{{ $p->period_number }}: {{ $p->status }}" 
                                                  class="w-6.5 h-6.5 rounded-lg flex items-center justify-center text-[10px] font-mono font-bold transition-all hover:scale-110 shadow-2xs {{ $p->status === 'settled' ? 'bg-emerald-600 text-white' : ($p->status === 'paid' ? 'bg-[#0C5D8F] text-white' : ($p->status === 'disputed' ? 'bg-rose-600 text-white' : 'bg-slate-200 text-slate-700')) }}">
                                                {{ $p->period_number }}
                                            </span>
                                        @endforeach
                                    </div>
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>

            <div class="px-6 py-4 border-t border-slate-100 bg-slate-50/40">
                {{ $bookings->links() }}
            </div>
        @endif
    </div>
</div>
@endsection
