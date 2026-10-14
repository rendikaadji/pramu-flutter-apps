@extends('admin.layout')

@section('title', 'Keuangan & Bagi Hasil Platform')

@section('content')
<div class="space-y-6">

    {{-- Page Hero Header on Ocean Canvas --}}
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
            <div class="flex items-center gap-2 mb-1">
                <span class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-white/10 text-sky-200 border border-white/15 backdrop-blur-xs">
                    <span class="w-1.5 h-1.5 rounded-full bg-cyan-400"></span>
                    Sirkulasi Keuangan
                </span>
            </div>
            <h1 class="text-2xl font-bold text-white tracking-tight">Keuangan & Bagi Hasil Platform</h1>
            <p class="text-sm text-sky-100/90 mt-0.5">Monitoring dana titipan gaji (escrow), pencairan upah pekerja, dan pendapatan bagi hasil platform</p>
        </div>
        <div class="flex items-center gap-2">
            <div class="flex items-center gap-2 text-xs text-emerald-300 bg-white/10 border border-white/15 px-3.5 py-2 rounded-xl backdrop-blur-xs shadow-inner font-semibold">
                <svg class="w-4 h-4 text-emerald-400" fill="currentColor" viewBox="0 0 20 20">
                    <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"/>
                </svg>
                <span>Audit Otomatis Sistem</span>
            </div>
        </div>
    </div>

    {{-- 4 Launchly Dark Glass Financial KPI Cards --}}
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <!-- Escrow Held -->
        <div class="bg-[#0B3559]/80 backdrop-blur-md rounded-2xl p-5 border border-white/10 shadow-lg text-white flex flex-col justify-between">
            <div class="flex items-start justify-between">
                <div>
                    <span class="text-[11px] font-bold text-sky-200 uppercase tracking-wider">Escrow Tertahan</span>
                    <div class="mt-2 text-2xl font-extrabold font-mono text-white tracking-tight">
                        Rp{{ number_format($escrowHeld, 0, ',', '.') }}
                    </div>
                </div>
                <div class="w-10 h-10 rounded-xl bg-cyan-500/20 text-cyan-400 border border-cyan-400/30 flex items-center justify-center shrink-0">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"/>
                    </svg>
                </div>
            </div>
            <div class="mt-4 flex items-center gap-1.5 text-[11px] text-sky-200/80 pt-3 border-t border-white/10">
                <span class="w-1.5 h-1.5 rounded-full bg-cyan-400"></span>
                <span>Dana gaji menunggu kerja tuntas</span>
            </div>
        </div>

        <!-- Escrow Settled -->
        <div class="bg-[#0B3559]/80 backdrop-blur-md rounded-2xl p-5 border border-white/10 shadow-lg text-white flex flex-col justify-between">
            <div class="flex items-start justify-between">
                <div>
                    <span class="text-[11px] font-bold text-emerald-300 uppercase tracking-wider">Payout Dicairkan</span>
                    <div class="mt-2 text-2xl font-extrabold font-mono text-white tracking-tight">
                        Rp{{ number_format($escrowSettled, 0, ',', '.') }}
                    </div>
                </div>
                <div class="w-10 h-10 rounded-xl bg-emerald-500/20 text-emerald-400 border border-emerald-400/30 flex items-center justify-center shrink-0">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
                    </svg>
                </div>
            </div>
            <div class="mt-4 flex items-center gap-1.5 text-[11px] text-emerald-300/80 pt-3 border-t border-white/10">
                <span class="w-1.5 h-1.5 rounded-full bg-emerald-400"></span>
                <span>Ditransfer ke rekening asisten</span>
            </div>
        </div>

        <!-- Platform Fees -->
        <div class="bg-[#0B3559]/80 backdrop-blur-md rounded-2xl p-5 border border-white/10 shadow-lg text-white flex flex-col justify-between">
            <div class="flex items-start justify-between">
                <div>
                    <span class="text-[11px] font-bold text-amber-300 uppercase tracking-wider">Fee Transaksi (10%)</span>
                    <div class="mt-2 text-2xl font-extrabold font-mono text-white tracking-tight">
                        Rp{{ number_format($platformFees, 0, ',', '.') }}
                    </div>
                </div>
                <div class="w-10 h-10 rounded-xl bg-amber-500/20 text-amber-400 border border-amber-400/30 flex items-center justify-center shrink-0">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>
                </div>
            </div>
            <div class="mt-4 flex items-center gap-1.5 text-[11px] text-amber-300/80 pt-3 border-t border-white/10">
                <span class="w-1.5 h-1.5 rounded-full bg-amber-400"></span>
                <span>5% majikan + 5% asisten</span>
            </div>
        </div>

        <!-- Listing Fees -->
        <div class="bg-[#0B3559]/80 backdrop-blur-md rounded-2xl p-5 border border-white/10 shadow-lg text-white flex flex-col justify-between">
            <div class="flex items-start justify-between">
                <div>
                    <span class="text-[11px] font-bold text-orange-300 uppercase tracking-wider">Fee Iklan Lowongan</span>
                    <div class="mt-2 text-2xl font-extrabold font-mono text-white tracking-tight">
                        Rp{{ number_format($listingFees, 0, ',', '.') }}
                    </div>
                </div>
                <div class="w-10 h-10 rounded-xl bg-[#FF6B35]/20 text-[#FF6B35] border border-[#FF6B35]/30 flex items-center justify-center shrink-0">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5.882V19.24a1.76 1.76 0 01-3.417.592l-2.147-6.15M18 13a3 3 0 100-6M5.436 13.683A4.001 4.001 0 017 6h1.832c4.1 0 7.625-1.234 9.168-3v14c-1.543-1.766-5.067-3-9.168-3H7a3.988 3.988 0 01-1.564-.317z"/>
                    </svg>
                </div>
            </div>
            <div class="mt-4 flex items-center gap-1.5 text-[11px] text-orange-200/80 pt-3 border-t border-white/10">
                <span class="w-1.5 h-1.5 rounded-full bg-[#FF6B35]"></span>
                <span>Tarif Rp25.000 per pasang iklan</span>
            </div>
        </div>
    </div>

    {{-- Settlement History Table Card --}}
    <div class="bg-white rounded-2xl border border-slate-100 shadow-md overflow-hidden">
        <div class="px-6 py-4.5 border-b border-slate-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3 bg-gradient-to-r from-slate-50/50 to-white">
            <div>
                <h3 class="text-base font-bold text-slate-900 tracking-tight">Riwayat Mutasi & Termin Pembayaran Escrow</h3>
                <p class="text-xs text-slate-500 mt-0.5">Pencatatan rincian gaji pokok, fee platform, dan hak bersih pekerja per periode</p>
            </div>
            <span class="text-xs text-slate-600 font-mono bg-slate-100/80 border border-slate-200 px-3 py-1 rounded-xl self-start sm:self-center">
                {{ $recentPeriods->total() }} transaksi tercatat
            </span>
        </div>

        @if($recentPeriods->isEmpty())
            <div class="p-16 text-center">
                <div class="w-14 h-14 rounded-2xl bg-slate-100 flex items-center justify-center mx-auto mb-3.5 text-slate-400">
                    <svg class="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>
                </div>
                <h4 class="text-sm font-bold text-slate-900">Belum ada riwayat mutasi</h4>
                <p class="text-xs text-slate-500 mt-1 max-w-sm mx-auto">Data pencairan escrow akan tampil saat kontrak kerja mencapai termin pembayaran.</p>
            </div>
        @else
            <div class="overflow-x-auto">
                <table class="w-full text-left text-xs text-slate-800 whitespace-nowrap">
                    <thead class="bg-slate-50/90 border-b border-slate-200/80">
                        <tr>
                            <th class="px-6 py-3.5 text-[11px] font-bold text-slate-700 uppercase tracking-wider whitespace-nowrap">Kontrak & Pihak Terlibat</th>
                            <th class="px-6 py-3.5 text-[11px] font-bold text-slate-700 uppercase tracking-wider whitespace-nowrap">Termin Kerja</th>
                            <th class="px-6 py-3.5 text-[11px] font-bold text-slate-700 uppercase tracking-wider whitespace-nowrap">Gaji Pokok Periode</th>
                            <th class="px-6 py-3.5 text-[11px] font-bold text-slate-700 uppercase tracking-wider whitespace-nowrap">Fee Majikan (5%)</th>
                            <th class="px-6 py-3.5 text-[11px] font-bold text-slate-700 uppercase tracking-wider whitespace-nowrap">Fee Asisten (5%)</th>
                            <th class="px-6 py-3.5 text-[11px] font-bold text-slate-700 uppercase tracking-wider whitespace-nowrap">Hak Cair Asisten</th>
                            <th class="px-6 py-3.5 text-[11px] font-bold text-slate-700 uppercase tracking-wider text-right whitespace-nowrap">Status Escrow</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-100">
                        @foreach($recentPeriods as $period)
                            <tr class="hover:bg-sky-50/30 transition-colors">
                                <td class="px-6 py-4">
                                    <div class="font-bold text-slate-900 flex items-center gap-1.5">
                                        <span>{{ $period->booking?->seeker?->name ?? 'Majikan' }}</span>
                                        <span class="text-slate-400">&rarr;</span>
                                        <span class="text-[#0C5D8F]">{{ $period->booking?->assistant?->name ?? 'Asisten' }}</span>
                                    </div>
                                    <div class="text-[11px] font-mono text-slate-500 mt-0.5">
                                        Kontrak #{{ substr($period->booking_id, 0, 8) }}
                                    </div>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <span class="inline-flex items-center px-2.5 py-1 rounded-lg text-xs font-mono font-bold bg-slate-100 border border-slate-200 text-slate-800">
                                        Periode {{ $period->period_number }}
                                    </span>
                                </td>
                                <td class="px-6 py-4 font-mono font-bold text-slate-900 whitespace-nowrap">
                                    Rp{{ number_format($period->amount, 0, ',', '.') }}
                                </td>
                                <td class="px-6 py-4 font-mono text-amber-700 whitespace-nowrap">
                                    +Rp{{ number_format($period->seeker_fee, 0, ',', '.') }}
                                </td>
                                <td class="px-6 py-4 font-mono text-amber-700 whitespace-nowrap">
                                    -Rp{{ number_format($period->assistant_fee, 0, ',', '.') }}
                                </td>
                                <td class="px-6 py-4 font-mono font-bold text-emerald-700 whitespace-nowrap">
                                    Rp{{ number_format($period->total_payout, 0, ',', '.') }}
                                </td>
                                <td class="px-6 py-4 text-right whitespace-nowrap">
                                    <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-[10px] font-bold {{ $period->status === 'settled' ? 'bg-emerald-50 text-emerald-700 border border-emerald-200/60' : ($period->status === 'paid' ? 'bg-sky-50 text-sky-700 border border-sky-200/60' : 'bg-amber-50 text-amber-700 border border-amber-200/60') }}">
                                        @if($period->status === 'settled')
                                            <span class="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse"></span>
                                        @endif
                                        {{ strtoupper(str_replace('_', ' ', $period->status)) }}
                                    </span>
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>

            <div class="px-6 py-4 border-t border-slate-100 bg-slate-50/40">
                {{ $recentPeriods->links() }}
            </div>
        @endif
    </div>
</div>
@endsection
