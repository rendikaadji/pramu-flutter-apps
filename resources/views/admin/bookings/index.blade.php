@extends('admin.layout')

@section('title', 'Kontrak & Escrow')
@section('header', 'Monitoring Kontrak & Dana Escrow')

@section('content')
<div class="space-y-6">
    <div class="bg-white rounded-xl border border-[#E2D9CC] shadow-sm overflow-hidden">
        <div class="px-6 py-4 border-b border-[#E2D9CC]">
            <h3 class="text-base font-semibold text-[#1F1B16]">Daftar Kontrak Kerja & Status Escrow</h3>
            <p class="text-xs text-[#5A5146]">Melacak dana yang ditahan dan termin pembayaran per periode</p>
        </div>

        @if($bookings->isEmpty())
            <div class="p-12 text-center text-[#5A5146]">
                <p class="text-sm">Belum ada kontrak kerja yang dibuat.</p>
            </div>
        @else
            <div class="overflow-x-auto">
                <table class="w-full text-left text-sm text-[#1F1B16]">
                    <thead class="bg-[#FAF7F2] text-xs uppercase font-medium text-[#5A5146] border-b border-[#E2D9CC]">
                        <tr>
                            <th class="px-6 py-3">ID Kontrak</th>
                            <th class="px-6 py-3">Pencari (Majikan)</th>
                            <th class="px-6 py-3">Asisten</th>
                            <th class="px-6 py-3">Pekerjaan</th>
                            <th class="px-6 py-3">Total Kontrak</th>
                            <th class="px-6 py-3">Status Kontrak</th>
                            <th class="px-6 py-3">Periode & Escrow</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-[#E2D9CC]">
                        @foreach($bookings as $b)
                            <tr class="hover:bg-[#FAF7F2]/50 transition-colors">
                                <td class="px-6 py-4 font-mono text-xs font-semibold">{{ substr($b->id, 0, 10) }}...</td>
                                <td class="px-6 py-4 font-medium">{{ $b->seeker?->name ?? 'Pencari' }}</td>
                                <td class="px-6 py-4 font-medium">{{ $b->assistant?->name ?? 'Asisten' }}</td>
                                <td class="px-6 py-4 text-xs text-[#5A5146]">{{ $b->listing?->title ?? '-' }}</td>
                                <td class="px-6 py-4 font-mono text-xs font-bold text-[#1F1B16]">
                                    Rp{{ number_format($b->total_amount, 0, ',', '.') }}
                                </td>
                                <td class="px-6 py-4">
                                    <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium {{ $b->status === 'active' ? 'bg-[#E3F2EA] text-[#1B6E45]' : ($b->status === 'disputed' ? 'bg-[#FBE5E3] text-[#B3261E]' : 'bg-[#E4ECF7] text-[#244C7C]') }}">
                                        {{ ucfirst($b->status) }}
                                    </span>
                                </td>
                                <td class="px-6 py-4">
                                    <div class="flex items-center gap-1">
                                        @foreach($b->periods as $p)
                                            <span title="Periode #{{ $p->period_number }}: {{ $p->status }}" 
                                                  class="w-6 h-6 rounded flex items-center justify-center text-[10px] font-mono font-bold {{ $p->status === 'settled' ? 'bg-[#1B6E45] text-white' : ($p->status === 'paid' ? 'bg-[#244C7C] text-white' : ($p->status === 'disputed' ? 'bg-[#B3261E] text-white' : 'bg-[#E2D9CC] text-[#5A5146]')) }}">
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

            <div class="px-6 py-4 border-t border-[#E2D9CC]">
                {{ $bookings->links() }}
            </div>
        @endif
    </div>
</div>
@endsection
