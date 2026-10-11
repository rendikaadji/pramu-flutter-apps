@extends('admin.layout')

@section('title', 'Keuangan & Bagi Hasil Platform')
@section('header', 'Keuangan, Escrow & Pendapatan Platform')

@section('content')
<div class="space-y-6">

    <!-- KPI Financial Cards -->
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <!-- Escrow Held -->
        <div class="bg-white p-5 rounded-2xl border border-[#E2D9CC] shadow-sm">
            <div class="text-xs font-semibold text-[#5A5146] uppercase tracking-wider">Escrow Tertahan Aman</div>
            <div class="mt-2 text-2xl font-extrabold text-[#1F1B16] font-mono">
                Rp{{ number_format($escrowHeld, 0, ',', '.') }}
            </div>
            <div class="mt-2 flex items-center gap-1.5 text-[11px] text-[#244C7C]">
                <span class="w-2 h-2 rounded-full bg-[#244C7C]"></span>
                Dana gaji menunggu kerja selesai
            </div>
        </div>

        <!-- Escrow Settled -->
        <div class="bg-white p-5 rounded-2xl border border-[#E2D9CC] shadow-sm">
            <div class="text-xs font-semibold text-[#5A5146] uppercase tracking-wider">Total Payout Dicairkan</div>
            <div class="mt-2 text-2xl font-extrabold text-[#1B6E45] font-mono">
                Rp{{ number_format($escrowSettled, 0, ',', '.') }}
            </div>
            <div class="mt-2 flex items-center gap-1.5 text-[11px] text-[#1B6E45]">
                <span class="w-2 h-2 rounded-full bg-[#1B6E45]"></span>
                Ditransfer ke rekening asisten
            </div>
        </div>

        <!-- Platform Fees -->
        <div class="bg-white p-5 rounded-2xl border border-[#E2D9CC] shadow-sm">
            <div class="text-xs font-semibold text-[#5A5146] uppercase tracking-wider">Fee Jasa Transaksi (10%)</div>
            <div class="mt-2 text-2xl font-extrabold text-[#9A4E1C] font-mono">
                Rp{{ number_format($platformFees, 0, ',', '.') }}
            </div>
            <div class="mt-2 flex items-center gap-1.5 text-[11px] text-[#9A4E1C]">
                <span class="w-2 h-2 rounded-full bg-[#9A4E1C]"></span>
                Bagi hasil 5% majikan + 5% asisten
            </div>
        </div>

        <!-- Listing Fees -->
        <div class="bg-white p-5 rounded-2xl border border-[#E2D9CC] shadow-sm">
            <div class="text-xs font-semibold text-[#5A5146] uppercase tracking-wider">Fee Pasang Lowongan</div>
            <div class="mt-2 text-2xl font-extrabold text-[#1F1B16] font-mono">
                Rp{{ number_format($listingFees, 0, ',', '.') }}
            </div>
            <div class="mt-2 flex items-center gap-1.5 text-[11px] text-[#5A5146]">
                <span class="w-2 h-2 rounded-full bg-[#5A5146]"></span>
                Tarif Rp25.000 per penayangan iklan
            </div>
        </div>
    </div>

    <!-- Settlement History Table -->
    <div class="bg-white rounded-2xl border border-[#E2D9CC] shadow-sm overflow-hidden">
        <div class="px-6 py-4 border-b border-[#E2D9CC] flex items-center justify-between">
            <div>
                <h3 class="text-sm font-bold text-[#1F1B16] uppercase tracking-wide">Riwayat Mutasi & Termin Pembayaran Escrow</h3>
                <p class="text-xs text-[#5A5146]">Pencatatan rincian gaji pokok, fee platform, dan hak bersih pekerja per periode</p>
            </div>
            <span class="inline-flex items-center gap-1 px-2.5 py-0.5 rounded text-xs font-semibold bg-[#E3F2EA] text-[#1B6E45]">
                Audit Otomatis Sistem
            </span>
        </div>

        @if($recentPeriods->isEmpty())
            <div class="p-12 text-center text-[#5A5146]">
                <p class="text-sm">Belum ada riwayat termin pembayaran.</p>
            </div>
        @else
            <div class="overflow-x-auto">
                <table class="w-full text-left text-xs text-[#1F1B16]">
                    <thead class="bg-[#FAF7F2] uppercase font-semibold text-[#5A5146] border-b border-[#E2D9CC]">
                        <tr>
                            <th class="px-6 py-3.5">Kontrak & Pihak Terlibat</th>
                            <th class="px-6 py-3.5">Termin Kerja</th>
                            <th class="px-6 py-3.5">Gaji Pokok Periode</th>
                            <th class="px-6 py-3.5">Fee Majikan (5%)</th>
                            <th class="px-6 py-3.5">Fee Asisten (5%)</th>
                            <th class="px-6 py-3.5">Hak Cair Asisten</th>
                            <th class="px-6 py-3.5 text-right">Status Escrow</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-[#E2D9CC]/60">
                        @foreach($recentPeriods as $period)
                            <tr class="hover:bg-[#FAF7F2]/50 transition-colors">
                                <td class="px-6 py-4">
                                    <div class="font-bold text-[#1F1B16]">
                                        {{ $period->booking?->seeker?->name ?? 'Majikan' }} &rarr; {{ $period->booking?->assistant?->name ?? 'Asisten' }}
                                    </div>
                                    <div class="text-[11px] font-mono text-[#5A5146] mt-0.5">
                                        Kontrak #{{ substr($period->booking_id, 0, 8) }}
                                    </div>
                                </td>
                                <td class="px-6 py-4">
                                    <span class="inline-flex items-center px-2 py-0.5 rounded text-[10px] font-mono font-bold bg-[#EAE4DC] text-[#1F1B16]">
                                        Periode {{ $period->period_number }}
                                    </span>
                                </td>
                                <td class="px-6 py-4 font-mono font-bold text-[#1F1B16]">
                                    Rp{{ number_format($period->amount, 0, ',', '.') }}
                                </td>
                                <td class="px-6 py-4 font-mono text-[#9A4E1C]">
                                    +Rp{{ number_format($period->seeker_fee, 0, ',', '.') }}
                                </td>
                                <td class="px-6 py-4 font-mono text-[#9A4E1C]">
                                    -Rp{{ number_format($period->assistant_fee, 0, ',', '.') }}
                                </td>
                                <td class="px-6 py-4 font-mono font-bold text-[#1B6E45]">
                                    Rp{{ number_format($period->total_payout, 0, ',', '.') }}
                                </td>
                                <td class="px-6 py-4 text-right">
                                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-[10px] font-bold {{ $period->status === 'settled' ? 'bg-[#E3F2EA] text-[#1B6E45]' : ($period->status === 'paid' ? 'bg-[#E4ECF7] text-[#244C7C]' : 'bg-[#FFF1D6] text-[#8A5200]') }}">
                                        {{ strtoupper(str_replace('_', ' ', $period->status)) }}
                                    </span>
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>

            <div class="px-6 py-4 border-t border-[#E2D9CC]">
                {{ $recentPeriods->links() }}
            </div>
        @endif
    </div>
</div>
@endsection
