@extends('admin.layout')

@section('title', 'Laporan & Sengketa')

@section('content')
<div class="space-y-6">

    {{-- Page Hero Header on Ocean Canvas --}}
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
            <div class="flex items-center gap-2 mb-1">
                <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-white/10 text-cyan-200 border border-white/15 backdrop-blur-xs">
                    <span class="w-1.5 h-1.5 rounded-full bg-rose-400 animate-pulse"></span>
                    Mediasi & Resolusi Kasus
                </span>
            </div>
            <h1 class="text-2xl sm:text-3xl font-black text-white tracking-tight">Pusat Mediasi & Sengketa</h1>
            <p class="text-xs sm:text-sm text-cyan-100/90 mt-0.5">Penanganan laporan keluhan, mediasi sengketa kerja, dan perlindungan keadilan pengguna platform</p>
        </div>
        <div class="flex items-center gap-2 shrink-0">
            <div class="flex items-center gap-2.5 text-xs text-white bg-white/10 border border-white/15 px-4 py-2.5 rounded-xl backdrop-blur-xs shadow-inner">
                <span class="text-cyan-200 font-medium">Total Kasus Terdaftar:</span>
                <strong class="font-bold font-mono text-white text-sm">{{ $reports->total() }}</strong>
            </div>
        </div>
    </div>

    {{-- Filter Pelapor & Status Toolbar Card --}}
    <div class="bg-white rounded-2xl border border-slate-100 p-5 shadow-md space-y-3.5">
        <div class="flex flex-col md:flex-row md:items-center justify-between gap-3.5">
            <!-- Filter Pelapor Role Tabs -->
            <div class="flex flex-wrap items-center gap-2">
                <span class="text-[11px] font-bold text-slate-600 uppercase tracking-wider mr-1">Filter Pelapor:</span>
                
                <a href="{{ route('admin.reports.index', ['role' => 'all', 'status' => $status ?? 'all', 'search' => $search ?? '']) }}" 
                   class="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-bold transition-all {{ ($role ?? 'all') === 'all' ? 'bg-[#082032] text-white shadow-sm' : 'text-slate-700 bg-slate-50 border border-slate-200/90 hover:bg-slate-100' }}">
                    <span>Semua Pelapor</span>
                    <span class="px-1.5 py-0.5 rounded-full text-[10px] font-mono {{ ($role ?? 'all') === 'all' ? 'bg-white/20 text-white' : 'bg-slate-200 text-slate-700' }}">
                        {{ $roleCounts['all'] ?? 0 }}
                    </span>
                </a>

                <a href="{{ route('admin.reports.index', ['role' => 'assistant', 'status' => $status ?? 'all', 'search' => $search ?? '']) }}" 
                   class="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-bold transition-all {{ ($role ?? 'all') === 'assistant' ? 'bg-[#FF6B35] text-white shadow-sm shadow-[#FF6B35]/30' : 'text-slate-700 bg-slate-50 border border-slate-200/90 hover:bg-slate-100' }}">
                    <span>Dari Asisten (ART)</span>
                    <span class="px-1.5 py-0.5 rounded-full text-[10px] font-mono {{ ($role ?? 'all') === 'assistant' ? 'bg-white/20 text-white' : 'bg-orange-100 text-orange-950 border border-orange-200' }}">
                        {{ $roleCounts['assistant'] ?? 0 }}
                    </span>
                </a>

                <a href="{{ route('admin.reports.index', ['role' => 'seeker', 'status' => $status ?? 'all', 'search' => $search ?? '']) }}" 
                   class="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-bold transition-all {{ ($role ?? 'all') === 'seeker' ? 'bg-[#0C5D8F] text-white shadow-sm shadow-[#0C5D8F]/30' : 'text-slate-700 bg-slate-50 border border-slate-200/90 hover:bg-slate-100' }}">
                    <span>Dari Pencari (Majikan)</span>
                    <span class="px-1.5 py-0.5 rounded-full text-[10px] font-mono {{ ($role ?? 'all') === 'seeker' ? 'bg-white/20 text-white' : 'bg-sky-100 text-sky-950 border border-sky-200' }}">
                        {{ $roleCounts['seeker'] ?? 0 }}
                    </span>
                </a>
            </div>

            <!-- Filter Status (Open vs Resolved) -->
            <div class="flex items-center gap-2 self-start md:self-center">
                <span class="text-[11px] font-bold text-slate-600 uppercase tracking-wider">Status:</span>
                <a href="{{ route('admin.reports.index', ['role' => $role ?? 'all', 'status' => 'all', 'search' => $search ?? '']) }}"
                   class="px-3 py-1.5 rounded-lg text-xs font-bold transition-all {{ ($status ?? 'all') === 'all' ? 'bg-slate-900 text-white' : 'text-slate-600 hover:bg-slate-100' }}">
                    Semua
                </a>
                <a href="{{ route('admin.reports.index', ['role' => $role ?? 'all', 'status' => 'open', 'search' => $search ?? '']) }}"
                   class="px-3 py-1.5 rounded-lg text-xs font-bold transition-all {{ ($status ?? 'all') === 'open' ? 'bg-amber-500 text-white shadow-xs' : 'text-slate-600 hover:bg-slate-100' }}">
                    Aktif
                </a>
                <a href="{{ route('admin.reports.index', ['role' => $role ?? 'all', 'status' => 'resolved', 'search' => $search ?? '']) }}"
                   class="px-3 py-1.5 rounded-lg text-xs font-bold transition-all {{ ($status ?? 'all') === 'resolved' ? 'bg-emerald-600 text-white shadow-xs' : 'text-slate-600 hover:bg-slate-100' }}">
                    Selesai
                </a>
            </div>
        </div>
    </div>

    {{-- Reports List Card --}}
    <div class="bg-white rounded-2xl border border-slate-100 shadow-md overflow-hidden">
        <div class="px-6 py-4.5 border-b border-slate-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3 bg-gradient-to-r from-slate-50/70 to-white">
            <div class="flex items-center gap-3">
                <div class="w-8 h-8 rounded-xl bg-orange-50 text-[#FF6B35] flex items-center justify-center font-bold text-xs shrink-0">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/></svg>
                </div>
                <div>
                    <h3 class="text-base font-bold text-slate-900 tracking-tight">Daftar Kasus & Laporan Terdaftar</h3>
                    <p class="text-xs text-slate-600 mt-0.5">Tinjau kronologi masalah untuk memberikan keputusan mediasi yang adil</p>
                </div>
            </div>
            <span class="text-xs text-slate-800 font-mono font-bold bg-slate-100 border border-slate-200 px-3 py-1.5 rounded-xl self-start sm:self-center">
                {{ $reports->total() }} sengketa
            </span>
        </div>

        @if($reports->isEmpty())
            <div class="p-16 text-center">
                <div class="w-14 h-14 rounded-2xl bg-slate-100 flex items-center justify-center mx-auto mb-3.5 text-slate-400">
                    <svg class="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>
                </div>
                <h4 class="text-sm font-bold text-slate-900">Tidak ada laporan sengketa aktif</h4>
                <p class="text-xs text-slate-500 mt-1 max-w-sm mx-auto">Semua sengketa telah selesai dimediasi atau belum ada keluhan baru masuk.</p>
            </div>
        @else
            <div class="divide-y divide-slate-100">
                @foreach($reports as $r)
                    <div class="p-6 sm:p-7 space-y-4 hover:bg-sky-50/15 transition-colors">
                        {{-- Top Header Row: Case ID, Role Pill, Category, Status, Timestamp --}}
                        <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                            <div class="flex flex-wrap items-center gap-2">
                                <span class="text-xs font-mono font-bold text-slate-800 bg-slate-100 px-2.5 py-1 rounded-lg border border-slate-200">
                                    #{{ substr($r->id, 0, 8) }}
                                </span>

                                @if($r->reporter?->active_role === 'assistant')
                                    <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-bold bg-orange-50 text-orange-950 border border-orange-300">
                                        Laporan dari Asisten (ART)
                                    </span>
                                @elseif($r->reporter?->active_role === 'seeker')
                                    <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-bold bg-sky-50 text-sky-950 border border-sky-300">
                                        Laporan dari Pencari (Majikan)
                                    </span>
                                @endif

                                <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold bg-slate-100 text-slate-800 border border-slate-200">
                                    Kategori: {{ ucfirst($r->category) }}
                                </span>

                                @if($r->status === 'resolved')
                                    <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-emerald-100 text-emerald-950 border border-emerald-300">
                                        <svg class="w-3.5 h-3.5 text-emerald-700" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"/></svg>
                                        Status: Selesai Dimediasi
                                    </span>
                                @else
                                    <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-amber-100 text-amber-950 border border-amber-300">
                                        <span class="w-1.5 h-1.5 rounded-full bg-amber-600 animate-pulse"></span>
                                        Status: {{ ucfirst(str_replace('_', ' ', $r->status)) }}
                                    </span>
                                @endif
                            </div>

                            <span class="text-xs text-slate-700 font-mono font-bold whitespace-nowrap self-start sm:self-auto">
                                {{ $r->created_at->format('d M Y, H:i') }} WIB
                            </span>
                        </div>

                        {{-- Involved Parties Card (Pelapor vs Dilaporkan) --}}
                        <div class="grid grid-cols-1 sm:grid-cols-2 gap-3.5">
                            <!-- Pelapor Box -->
                            <div class="p-4 bg-slate-50/90 rounded-xl border border-slate-200/80 flex items-center justify-between gap-3">
                                <div class="flex items-center gap-3 min-w-0">
                                    <div class="w-10 h-10 rounded-xl bg-[#082032] text-white flex items-center justify-center font-bold text-xs shrink-0 shadow-xs">
                                        {{ strtoupper(substr($r->reporter?->name ?? 'P', 0, 1)) }}
                                    </div>
                                    <div class="min-w-0">
                                        <div class="flex items-center gap-1.5">
                                            <span class="text-[11px] font-bold text-slate-600 uppercase tracking-wider">Pelapor:</span>
                                            <span class="text-[10px] font-semibold px-1.5 py-0.2 rounded {{ $r->reporter?->active_role === 'assistant' ? 'bg-orange-100 text-orange-900' : 'bg-sky-100 text-sky-900' }}">
                                                {{ $r->reporter?->active_role === 'assistant' ? 'Asisten' : 'Majikan' }}
                                            </span>
                                        </div>
                                        <h4 class="font-extrabold text-xs sm:text-sm text-slate-900 truncate mt-0.5">{{ $r->reporter?->name ?? 'User' }}</h4>
                                        <p class="text-[11px] text-slate-500 font-mono mt-0.5">{{ $r->reporter?->phone ?? '-' }}</p>
                                    </div>
                                </div>
                                @if($r->reporter)
                                    <a href="{{ route('admin.users.show', $r->reporter->id) }}" 
                                       class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-[#082032] hover:bg-[#FF6B35] text-white text-xs font-bold transition-all shadow-xs shrink-0 group">
                                        <span>Profil</span>
                                        <svg class="w-3.5 h-3.5 transition-transform group-hover:translate-x-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>
                                    </a>
                                @endif
                            </div>

                            <!-- Dilaporkan Box -->
                            <div class="p-4 bg-slate-50/90 rounded-xl border border-slate-200/80 flex items-center justify-between gap-3">
                                <div class="flex items-center gap-3 min-w-0">
                                    <div class="w-10 h-10 rounded-xl bg-[#082032] text-white flex items-center justify-center font-bold text-xs shrink-0 shadow-xs">
                                        {{ strtoupper(substr($r->reported?->name ?? 'D', 0, 1)) }}
                                    </div>
                                    <div class="min-w-0">
                                        <div class="flex items-center gap-1.5">
                                            <span class="text-[11px] font-bold text-slate-600 uppercase tracking-wider">Dilaporkan:</span>
                                            <span class="text-[10px] font-semibold px-1.5 py-0.2 rounded {{ $r->reported?->active_role === 'assistant' ? 'bg-orange-100 text-orange-900' : 'bg-sky-100 text-sky-900' }}">
                                                {{ $r->reported?->active_role === 'assistant' ? 'Asisten' : 'Majikan' }}
                                            </span>
                                        </div>
                                        <h4 class="font-extrabold text-xs sm:text-sm text-slate-900 truncate mt-0.5">{{ $r->reported?->name ?? 'User' }}</h4>
                                        <p class="text-[11px] text-slate-500 font-mono mt-0.5">{{ $r->reported?->phone ?? '-' }}</p>
                                    </div>
                                </div>
                                @if($r->reported)
                                    <a href="{{ route('admin.users.show', $r->reported->id) }}" 
                                       class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-[#082032] hover:bg-[#FF6B35] text-white text-xs font-bold transition-all shadow-xs shrink-0 group">
                                        <span>Profil</span>
                                        <svg class="w-3.5 h-3.5 transition-transform group-hover:translate-x-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>
                                    </a>
                                @endif
                            </div>
                        </div>

                        {{-- Uraian Masalah (Issue Chronology) --}}
                        <div class="p-4 bg-slate-50/90 rounded-xl border border-slate-200/80 space-y-1.5">
                            <div class="flex items-center gap-2">
                                <svg class="w-4 h-4 text-[#FF6B35]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 8h10M7 12h4m1 8l-4-4H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-3l-4 4z"/></svg>
                                <span class="font-bold text-slate-700 text-xs uppercase tracking-wider">Uraian Masalah & Kronologi Pelapor:</span>
                            </div>
                            <p class="text-slate-900 text-xs sm:text-sm leading-relaxed whitespace-pre-line pl-6 font-medium">
                                {{ $r->description }}
                            </p>
                        </div>

                        {{-- Chat Consent Notice & Contract Reference --}}
                        <div class="flex flex-wrap items-center gap-3 text-xs pt-0.5">
                            @if($r->share_chat_consent && $r->consent_expires_at && $r->consent_expires_at->isFuture())
                                <span class="inline-flex items-center gap-2 px-3 py-1.5 rounded-xl bg-sky-50 text-sky-900 font-semibold text-xs border border-sky-200">
                                    <svg class="w-4 h-4 text-sky-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"/>
                                    </svg>
                                    Persetujuan berbagi riwayat obrolan aktif hingga {{ $r->consent_expires_at->format('d M Y') }}
                                </span>
                            @else
                                <span class="inline-flex items-center gap-1.5 text-slate-500 text-xs">
                                    <svg class="w-3.5 h-3.5 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"/></svg>
                                    Riwayat obrolan privat (tidak dibagikan).
                                </span>
                            @endif

                            @if($r->booking)
                                <span class="text-slate-500 font-mono text-[11px] bg-slate-100 px-2.5 py-1 rounded-lg border border-slate-200">
                                    Kontrak Terkait: #{{ substr($r->booking_id, 0, 8) }}
                                </span>
                            @endif
                        </div>

                        {{-- Resolution Decision Form or Official Display --}}
                        @if($r->status !== 'resolved')
                            <div class="pt-2 border-t border-slate-100">
                                <form action="{{ route('admin.reports.resolve', $r->id) }}" method="POST" class="space-y-3">
                                    @csrf
                                    <!-- Quick Decision Suggestions -->
                                    <div class="flex flex-wrap items-center gap-1.5">
                                        <span class="text-[10px] font-bold text-slate-500 uppercase tracking-wider mr-1">Opsi Putusan Cepat:</span>
                                        <button type="button" onclick="setDecision('{{ $r->id }}', 'Majikan diinstruksikan mentransfer kompensasi lembur sesuai perjanjian kerja.')"
                                                class="px-2.5 py-1 rounded-lg bg-slate-50 hover:bg-slate-100 border border-slate-200 text-slate-700 text-[11px] font-medium transition-all">
                                            + Bayar Kompensasi Lembur
                                        </button>
                                        <button type="button" onclick="setDecision('{{ $r->id }}', 'Kontrak dibatalkan secara damai tanpa sanksi denda bagi kedua belah pihak.')"
                                                class="px-2.5 py-1 rounded-lg bg-slate-50 hover:bg-slate-100 border border-slate-200 text-slate-700 text-[11px] font-medium transition-all">
                                            + Batalkan Kontrak Tanpa Penalti
                                        </button>
                                        <button type="button" onclick="setDecision('{{ $r->id }}', 'Pemberian sanksi teguran resmi dan mediasi klarifikasi etika kerja.')"
                                                class="px-2.5 py-1 rounded-lg bg-slate-50 hover:bg-slate-100 border border-slate-200 text-slate-700 text-[11px] font-medium transition-all">
                                            + Teguran Resmi & Klarifikasi
                                        </button>
                                    </div>

                                    <div class="flex flex-col sm:flex-row gap-2.5">
                                        <input type="text" id="decision-input-{{ $r->id }}" name="decision" required placeholder="Tuliskan putusan sengketa & arahan mediasi admin..."
                                               class="flex-1 text-xs px-4 py-2.5 rounded-xl border border-slate-200 bg-slate-50/70 focus:bg-white focus:border-[#FF6B35] focus:ring-1 focus:ring-[#FF6B35] outline-none transition-all placeholder:text-slate-400 text-slate-900 font-medium">
                                        <button type="submit" 
                                                class="px-5 py-2.5 bg-[#082032] hover:bg-[#FF6B35] text-white text-xs font-bold rounded-xl transition-all whitespace-nowrap shadow-xs flex items-center justify-center gap-1.5">
                                            <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M5 13l4 4L19 7"/></svg>
                                            <span>Selesaikan Kasus</span>
                                        </button>
                                    </div>
                                </form>
                            </div>
                        @else
                            <div class="p-4 bg-emerald-50 border border-emerald-200 text-emerald-950 rounded-xl text-xs space-y-1">
                                <div class="flex items-center gap-2">
                                    <svg class="w-4 h-4 text-emerald-700" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/></svg>
                                    <strong class="font-bold text-emerald-900 uppercase tracking-wider text-[11px]">Keputusan Akhir Mediasi:</strong>
                                </div>
                                <p class="pl-6 font-semibold text-emerald-950 leading-relaxed">{{ $r->decision }}</p>
                            </div>
                        @endif
                    </div>
                @endforeach
            </div>

            <div class="px-6 py-4 border-t border-slate-100 bg-slate-50/40">
                {{ $reports->links() }}
            </div>
        @endif
    </div>
</div>

<script>
    function setDecision(reportId, text) {
        const input = document.getElementById('decision-input-' + reportId);
        if (input) {
            input.value = text;
            input.focus();
        }
    }
</script>
@endsection
