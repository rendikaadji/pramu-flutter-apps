@extends('admin.layout')

@section('title', 'Jadwal Wawancara Online')

@section('content')
<div class="space-y-6">

    {{-- Page Hero Header on Ocean Canvas --}}
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
            <div class="flex items-center gap-2 mb-1">
                <span class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-white/10 text-sky-200 border border-white/15 backdrop-blur-xs">
                    <span class="w-1.5 h-1.5 rounded-full bg-emerald-400"></span>
                    Fitur Video Interaktif
                </span>
            </div>
            <h1 class="text-2xl font-bold text-white tracking-tight">Jadwal Wawancara Online</h1>
            <p class="text-sm text-sky-100/90 mt-0.5">Pertemuan tatap muka virtual calon asisten dan majikan via Google Meet</p>
        </div>
        <div class="flex items-center gap-2">
            <div class="flex items-center gap-2 text-xs text-emerald-300 bg-white/10 border border-white/15 px-3.5 py-2 rounded-xl backdrop-blur-xs shadow-inner font-semibold">
                <span class="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
                <span>Google Meet Terintegrasi</span>
            </div>
        </div>
    </div>

    {{-- Filter Tabs Card --}}
    <div class="bg-white rounded-2xl border border-slate-100 p-5 shadow-md">
        <div class="flex flex-wrap items-center gap-2">
            <span class="text-[11px] font-bold text-slate-500 uppercase tracking-wider mr-1">Status Sesi:</span>
            <a href="{{ route('admin.interviews.index', ['status' => 'all']) }}" 
               class="px-3.5 py-2 rounded-xl text-xs font-semibold transition-all {{ $status === 'all' ? 'bg-[#082032] text-white shadow-sm' : 'text-slate-600 bg-slate-50 border border-slate-200/80 hover:bg-slate-100' }}">
                Semua Jadwal ({{ $counts['all'] ?? $interviews->total() }})
            </a>
            <a href="{{ route('admin.interviews.index', ['status' => 'confirmed']) }}" 
               class="px-3.5 py-2 rounded-xl text-xs font-semibold transition-all {{ $status === 'confirmed' ? 'bg-[#FF6B35] text-white shadow-sm' : 'text-slate-600 bg-slate-50 border border-slate-200/80 hover:bg-slate-100' }}">
                Terkonfirmasi ({{ $counts['confirmed'] ?? 0 }})
            </a>
            <a href="{{ route('admin.interviews.index', ['status' => 'completed']) }}" 
               class="px-3.5 py-2 rounded-xl text-xs font-semibold transition-all {{ $status === 'completed' ? 'bg-[#082032] text-white shadow-sm' : 'text-slate-600 bg-slate-50 border border-slate-200/80 hover:bg-slate-100' }}">
                Selesai Dilaksanakan ({{ $counts['done'] ?? 0 }})
            </a>
        </div>
    </div>

    {{-- Table Card --}}
    <div class="bg-white rounded-2xl border border-slate-100 shadow-md overflow-hidden">
        <div class="px-6 py-4.5 border-b border-slate-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3 bg-gradient-to-r from-slate-50/50 to-white">
            <div>
                <h3 class="text-base font-bold text-slate-900 tracking-tight">Daftar Sesi Wawancara Live</h3>
                <p class="text-xs text-slate-500 mt-0.5">Monitoring pertemuan online antara kandidat pekerja dan majikan</p>
            </div>
            <span class="text-xs text-slate-600 font-mono bg-slate-100/80 border border-slate-200 px-3 py-1 rounded-xl self-start sm:self-center">
                {{ $interviews->total() }} sesi terdaftar
            </span>
        </div>

        @if($interviews->isEmpty())
            <div class="p-16 text-center">
                <div class="w-14 h-14 rounded-2xl bg-slate-100 flex items-center justify-center mx-auto mb-3.5 text-slate-400">
                    <svg class="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"/>
                    </svg>
                </div>
                <h4 class="text-sm font-bold text-slate-900">Tidak ada jadwal wawancara</h4>
                <p class="text-xs text-slate-500 mt-1 max-w-sm mx-auto">Belum ada sesi wawancara yang sesuai dengan filter ini.</p>
            </div>
        @else
            <div class="overflow-x-auto">
                <table class="w-full text-left text-xs text-slate-800 whitespace-nowrap">
                    <thead class="bg-slate-50/90 border-b border-slate-200/80">
                        <tr>
                            <th class="px-6 py-3.5 text-[11px] font-bold text-slate-700 uppercase tracking-wider whitespace-nowrap">Kandidat Asisten</th>
                            <th class="px-6 py-3.5 text-[11px] font-bold text-slate-700 uppercase tracking-wider whitespace-nowrap">Pihak Majikan</th>
                            <th class="px-6 py-3.5 text-[11px] font-bold text-slate-700 uppercase tracking-wider whitespace-nowrap">Lowongan Terkait</th>
                            <th class="px-6 py-3.5 text-[11px] font-bold text-slate-700 uppercase tracking-wider whitespace-nowrap">Waktu Wawancara</th>
                            <th class="px-6 py-3.5 text-[11px] font-bold text-slate-700 uppercase tracking-wider whitespace-nowrap">Status Sesi</th>
                            <th class="px-6 py-3.5 text-[11px] font-bold text-slate-700 uppercase tracking-wider text-right whitespace-nowrap">Aksi</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-100">
                        @foreach($interviews as $i)
                            <tr class="hover:bg-sky-50/30 transition-colors">
                                <td class="px-6 py-4">
                                    <div class="flex items-center gap-3">
                                        <div class="w-9 h-9 rounded-xl bg-gradient-to-br from-amber-500 to-[#FF6B35] text-white flex items-center justify-center font-bold text-xs shrink-0 shadow-xs">
                                            {{ strtoupper(substr($i->application?->user?->name ?? 'A', 0, 1)) }}
                                        </div>
                                        <div>
                                            <div class="font-bold text-slate-900">
                                                {{ $i->application?->user?->name ?? 'Kandidat Asisten' }}
                                            </div>
                                            <div class="text-[11px] text-slate-500 font-mono mt-0.5">
                                                {{ $i->application?->user?->phone ?? '-' }}
                                            </div>
                                        </div>
                                    </div>
                                </td>
                                <td class="px-6 py-4">
                                    <div class="flex items-center gap-3">
                                        <div class="w-9 h-9 rounded-xl bg-[#082032] text-white flex items-center justify-center font-bold text-xs shrink-0 shadow-xs">
                                            {{ strtoupper(substr($i->application?->listing?->user?->name ?? 'M', 0, 1)) }}
                                        </div>
                                        <div>
                                            <div class="font-bold text-slate-900">
                                                {{ $i->application?->listing?->user?->name ?? 'Majikan' }}
                                            </div>
                                            <div class="text-[11px] text-slate-500 font-mono mt-0.5">
                                                {{ $i->application?->listing?->user?->email ?? '-' }}
                                            </div>
                                        </div>
                                    </div>
                                </td>
                                <td class="px-6 py-4 text-slate-600">
                                    <div class="font-semibold text-slate-900">
                                        {{ Str::limit($i->application?->listing?->title ?? 'Pramu ART', 32) }}
                                    </div>
                                    <div class="text-[11px] text-slate-400 mt-0.5">
                                        {{ $i->application?->listing?->city_name ?? 'Area Lokasi' }}
                                    </div>
                                </td>
                                <td class="px-6 py-4 font-mono whitespace-nowrap">
                                    @php
                                        $slot = $i->confirmed_slot ?? $i->scheduled_at;
                                    @endphp
                                    @if($slot)
                                        <div class="font-bold text-slate-900">{{ \Carbon\Carbon::parse($slot)->format('d M Y') }}</div>
                                        <div class="text-xs text-[#0C5D8F] font-semibold">{{ \Carbon\Carbon::parse($slot)->format('H:i') }} WIB</div>
                                    @else
                                        <span class="text-slate-400 italic">Belum dijadwalkan</span>
                                    @endif
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-[10px] font-bold {{ $i->status === 'confirmed' ? 'bg-emerald-50 text-emerald-700 border border-emerald-200/60' : ($i->status === 'proposed' ? 'bg-amber-50 text-amber-700 border border-amber-200/60' : 'bg-slate-100 text-slate-600 border border-slate-200') }}">
                                        @if($i->status === 'confirmed')
                                            <span class="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse"></span>
                                        @endif
                                        {{ strtoupper($i->status) }}
                                    </span>
                                </td>
                                <td class="px-6 py-4 text-right whitespace-nowrap">
                                    @php
                                        $meetUrl = $i->meeting_url ?? $i->meeting_link;
                                    @endphp
                                    <div class="flex items-center justify-end gap-2">
                                        @if($meetUrl)
                                            <a href="{{ $meetUrl }}" target="_blank" rel="noopener noreferrer" 
                                               class="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-semibold shadow-sm transition-all text-xs">
                                                <span>Masuk Meet</span>
                                                <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
                                                </svg>
                                            </a>
                                        @else
                                            <form action="{{ route('admin.interviews.generate-meet', $i->id) }}" method="POST" class="inline">
                                                @csrf
                                                <button type="submit" 
                                                        class="inline-flex items-center gap-1.5 px-3 py-2 rounded-xl bg-[#082032] hover:bg-[#143F66] text-white text-xs font-semibold shadow-sm transition-all">
                                                    <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
                                                    </svg>
                                                    Buat Link Meet
                                                </button>
                                            </form>
                                        @endif
                                    </div>
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>

            <div class="px-6 py-4 border-t border-slate-100 bg-slate-50/40">
                {{ $interviews->links() }}
            </div>
        @endif
    </div>
</div>
@endsection
