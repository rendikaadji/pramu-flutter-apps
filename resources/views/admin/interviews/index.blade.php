@extends('admin.layout')

@section('title', 'Jadwal Wawancara Online')
@section('header', 'Jadwal Wawancara Online (Google Meet)')

@section('content')
<div class="space-y-6">
    <!-- Filter Tabs -->
    <div class="flex items-center gap-2 border-b border-[#E2D9CC] pb-1 text-xs">
        <a href="{{ route('admin.interviews.index', ['status' => 'all']) }}" 
           class="px-3.5 py-2 rounded-lg font-medium transition-colors {{ $status === 'all' ? 'bg-[#244C7C] text-white' : 'text-[#5A5146] hover:bg-[#F3EEE6]' }}">
            Semua Jadwal
        </a>
        <a href="{{ route('admin.interviews.index', ['status' => 'confirmed']) }}" 
           class="px-3.5 py-2 rounded-lg font-medium transition-colors {{ $status === 'confirmed' ? 'bg-[#244C7C] text-white' : 'text-[#5A5146] hover:bg-[#F3EEE6]' }}">
            Terkonfirmasi
        </a>
        <a href="{{ route('admin.interviews.index', ['status' => 'proposed']) }}" 
           class="px-3.5 py-2 rounded-lg font-medium transition-colors {{ $status === 'proposed' ? 'bg-[#244C7C] text-white' : 'text-[#5A5146] hover:bg-[#F3EEE6]' }}">
            Menunggu Respon
        </a>
        <a href="{{ route('admin.interviews.index', ['status' => 'completed']) }}" 
           class="px-3.5 py-2 rounded-lg font-medium transition-colors {{ $status === 'completed' ? 'bg-[#244C7C] text-white' : 'text-[#5A5146] hover:bg-[#F3EEE6]' }}">
            Selesai Dilaksanakan
        </a>
    </div>

    <!-- Table Card -->
    <div class="bg-white rounded-2xl border border-[#E2D9CC] shadow-sm overflow-hidden">
        <div class="px-6 py-4 border-b border-[#E2D9CC] flex items-center justify-between">
            <div>
                <h3 class="text-sm font-bold text-[#1F1B16] uppercase tracking-wide">Daftar Sesi Wawancara Live</h3>
                <p class="text-xs text-[#5A5146]">Monitoring pertemuan tatap muka virtual calon pekerja dan majikan</p>
            </div>
            <span class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded text-xs font-semibold bg-[#E3F2EA] text-[#1B6E45]">
                <span class="w-1.5 h-1.5 rounded-full bg-[#1B6E45]"></span>
                Google Meet Terintegrasi
            </span>
        </div>

        @if($interviews->isEmpty())
            <div class="p-12 text-center text-[#5A5146]">
                <p class="text-sm">Tidak ada jadwal wawancara untuk kategori ini.</p>
            </div>
        @else
            <div class="overflow-x-auto">
                <table class="w-full text-left text-xs text-[#1F1B16]">
                    <thead class="bg-[#FAF7F2] uppercase font-semibold text-[#5A5146] border-b border-[#E2D9CC]">
                        <tr>
                            <th class="px-6 py-3.5">Kandidat Asisten</th>
                            <th class="px-6 py-3.5">Pihak Majikan</th>
                            <th class="px-6 py-3.5">Lowongan Terkait</th>
                            <th class="px-6 py-3.5">Waktu Wawancara</th>
                            <th class="px-6 py-3.5">Status Sesi</th>
                            <th class="px-6 py-3.5 text-right">Aksi</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-[#E2D9CC]/60">
                        @foreach($interviews as $i)
                            <tr class="hover:bg-[#FAF7F2]/50 transition-colors">
                                <td class="px-6 py-4">
                                    <div class="font-bold text-[#1F1B16] text-sm">
                                        {{ $i->application?->user?->name ?? 'Kandidat Asisten' }}
                                    </div>
                                    <div class="text-[11px] text-[#5A5146] font-mono">
                                        {{ $i->application?->user?->phone ?? '-' }}
                                    </div>
                                </td>
                                <td class="px-6 py-4">
                                    <div class="font-semibold text-[#1F1B16]">
                                        {{ $i->application?->listing?->user?->name ?? 'Majikan' }}
                                    </div>
                                    <div class="text-[11px] text-[#5A5146]">
                                        {{ $i->application?->listing?->user?->email ?? '-' }}
                                    </div>
                                </td>
                                <td class="px-6 py-4 text-[#5A5146]">
                                    {{ Str::limit($i->application?->listing?->title ?? 'Pramu ART', 30) }}
                                </td>
                                <td class="px-6 py-4 font-mono">
                                    @if($i->scheduled_at)
                                        <div class="font-bold text-[#1F1B16]">{{ $i->scheduled_at->format('d M Y') }}</div>
                                        <div class="text-[11px] text-[#244C7C] font-semibold">{{ $i->scheduled_at->format('H:i') }} WIB</div>
                                    @else
                                        <span class="text-[#8C8070] italic">Belum dijadwalkan</span>
                                    @endif
                                </td>
                                <td class="px-6 py-4">
                                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-[10px] font-bold {{ $i->status === 'confirmed' ? 'bg-[#E3F2EA] text-[#1B6E45]' : ($i->status === 'proposed' ? 'bg-[#FFF1D6] text-[#8A5200]' : 'bg-[#EAE4DC] text-[#5A5146]') }}">
                                        {{ strtoupper($i->status) }}
                                    </span>
                                </td>
                                <td class="px-6 py-4 text-right">
                                    @if($i->meeting_link)
                                        <a href="{{ $i->meeting_link }}" target="_blank" rel="noopener noreferrer" 
                                           class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-[#1B6E45] text-white font-semibold hover:bg-[#155434] transition-colors text-xs">
                                            <span>Gabung Meet</span>
                                            <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
                                            </svg>
                                        </a>
                                    @else
                                        <span class="text-[11px] text-[#8C8070] italic">Link Menunggu</span>
                                    @endif
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>

            <div class="px-6 py-4 border-t border-[#E2D9CC]">
                {{ $interviews->links() }}
            </div>
        @endif
    </div>
</div>
@endsection
