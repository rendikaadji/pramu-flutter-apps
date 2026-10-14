@extends('admin.layout')

@section('title', 'Verifikasi KTP & Identitas')

@section('content')
<div class="space-y-6">

    <!-- Page Header (Canvas Text) -->
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 text-white">
        <div>
            <div class="flex items-center gap-2 mb-1.5">
                <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-white/10 text-cyan-200 border border-white/20 backdrop-blur-xs">
                    <span class="w-1.5 h-1.5 rounded-full bg-cyan-400"></span>
                    Keamanan & Kepatuhan Platform
                </span>
            </div>
            <h1 class="text-2xl sm:text-3xl font-extrabold tracking-tight text-white">Pemeriksaan KTP & Identitas</h1>
            <p class="text-xs sm:text-sm text-sky-100/90 mt-1 font-normal">Verifikasi dokumen identitas resmi calon asisten dan majikan baru</p>
        </div>
        <div class="flex items-center gap-2.5">
            <div class="flex items-center gap-2 text-xs text-white bg-white/10 border border-white/20 px-4 py-2 rounded-xl backdrop-blur-xs shadow-inner">
                <svg class="w-4 h-4 text-cyan-300" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
                <span class="text-sky-200 font-medium">Total Berkas:</span>
                <strong class="text-white font-mono font-bold text-sm">{{ $verifications->total() }}</strong>
            </div>
        </div>
    </div>

    <!-- Filter & Search Card (Launchly White Card Style) -->
    <div class="bg-white rounded-2xl p-5 sm:p-6 shadow-md border border-slate-100 space-y-4">
        <!-- Top Row: Status Tabs & Search Form -->
        <div class="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
            <!-- Status Tabs -->
            <div class="flex flex-wrap items-center gap-2">
                <span class="text-xs font-bold text-slate-700 uppercase tracking-wider mr-1">Status:</span>
                @foreach(['pending' => 'Menunggu Tinjauan', 'verified' => 'Terverifikasi', 'rejected' => 'Ditolak', 'all' => 'Semua Riwayat'] as $key => $label)
                    <a href="{{ route('admin.verifications.index', ['status' => $key, 'role' => $role ?? 'all', 'search' => $search]) }}"
                       class="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-semibold transition-all {{ $status === $key ? 'bg-[#FF6B35] text-white shadow-sm shadow-[#FF6B35]/30' : 'text-slate-700 bg-white hover:bg-slate-50 border border-slate-200/90 hover:border-slate-300' }}">
                        <span>{{ $label }}</span>
                        @if(isset($statusCounts[$key]))
                            <span class="ml-1 px-1.5 py-0.5 rounded-full text-[10px] font-bold font-mono {{ $status === $key ? 'bg-white/25 text-white' : 'bg-slate-100 text-slate-700 border border-slate-200' }}">
                                {{ $statusCounts[$key] }}
                            </span>
                        @endif
                    </a>
                @endforeach
            </div>

            <!-- Search Bar -->
            <form method="GET" action="{{ route('admin.verifications.index') }}" class="flex items-center gap-2 shrink-0">
                <input type="hidden" name="status" value="{{ $status }}">
                <input type="hidden" name="role" value="{{ $role }}">
                <div class="relative w-full sm:w-64">
                    <svg class="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/></svg>
                    <input type="text" name="search" value="{{ $search }}" placeholder="Cari NIK, nama, no HP..."
                           class="w-full text-xs pl-9 pr-3.5 py-2 bg-slate-50 rounded-xl border border-slate-200 focus:bg-white focus:border-[#FF6B35] focus:ring-1 focus:ring-[#FF6B35] outline-none transition-all placeholder:text-slate-400 text-slate-900 font-medium">
                </div>
                <button type="submit" class="px-4 py-2 bg-[#082032] hover:bg-[#143F66] text-white rounded-xl text-xs font-bold transition-all shadow-sm">
                    Cari
                </button>
                @if($search)
                    <a href="{{ route('admin.verifications.index', ['status' => $status, 'role' => $role]) }}" class="text-xs text-rose-600 font-semibold hover:underline px-1">
                        Reset
                    </a>
                @endif
            </form>
        </div>

        <div class="border-t border-slate-100"></div>

        <!-- Bottom Row: Role Filters -->
        <div class="flex flex-wrap items-center gap-2">
            <span class="text-xs font-bold text-slate-700 uppercase tracking-wider mr-1">Filter Peran:</span>
            <a href="{{ route('admin.verifications.index', ['status' => $status, 'role' => 'all', 'search' => $search]) }}"
               class="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-semibold transition-all {{ ($role ?? 'all') === 'all' ? 'bg-[#082032] text-white shadow-sm' : 'text-slate-700 bg-white hover:bg-slate-50 border border-slate-200/90 hover:border-slate-300' }}">
               <span>Semua Peran</span>
               <span class="ml-1 px-1.5 py-0.5 rounded-full text-[10px] font-bold font-mono {{ ($role ?? 'all') === 'all' ? 'bg-white/20 text-white' : 'bg-slate-100 text-slate-700 border border-slate-200' }}">
                   {{ $roleCounts['all'] ?? $verifications->total() }}
               </span>
            </a>
            <a href="{{ route('admin.verifications.index', ['status' => $status, 'role' => 'assistant', 'search' => $search]) }}"
               class="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-semibold transition-all {{ ($role ?? 'all') === 'assistant' ? 'bg-[#FF6B35] text-white shadow-sm shadow-[#FF6B35]/30' : 'text-slate-700 bg-white hover:bg-slate-50 border border-slate-200/90 hover:border-slate-300' }}">
               <span>Peran Asisten</span>
               <span class="ml-1 px-1.5 py-0.5 rounded-full text-[10px] font-bold font-mono {{ ($role ?? 'all') === 'assistant' ? 'bg-white/20 text-white' : 'bg-orange-50 text-orange-950 border border-orange-200' }}">
                   {{ $roleCounts['assistant'] ?? 0 }}
               </span>
            </a>
            <a href="{{ route('admin.verifications.index', ['status' => $status, 'role' => 'seeker', 'search' => $search]) }}"
               class="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-semibold transition-all {{ ($role ?? 'all') === 'seeker' ? 'bg-[#0C5D8F] text-white shadow-sm shadow-[#0C5D8F]/30' : 'text-slate-700 bg-white hover:bg-slate-50 border border-slate-200/90 hover:border-slate-300' }}">
               <span>Peran Pencari</span>
               <span class="ml-1 px-1.5 py-0.5 rounded-full text-[10px] font-bold font-mono {{ ($role ?? 'all') === 'seeker' ? 'bg-white/20 text-white' : 'bg-sky-50 text-sky-950 border border-sky-200' }}">
                   {{ $roleCounts['seeker'] ?? 0 }}
               </span>
            </a>
        </div>
    </div>

    <!-- Table Card (Launchly White Card Style) -->
    <div class="bg-white rounded-2xl shadow-md border border-slate-100 overflow-hidden">
        <div class="px-6 py-4.5 border-b border-slate-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3 bg-gradient-to-r from-slate-50/70 to-white">
            <div class="flex items-center gap-3">
                <div class="w-9 h-9 rounded-xl bg-orange-50 border border-orange-200/80 text-[#FF6B35] flex items-center justify-center shrink-0">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V8a2 2 0 00-2-2h-5m-4 0V5a2 2 0 114 0v1m-4 0a2 2 0 104 0m-5 8a2 2 0 100-4 2 2 0 000 4zm0 0c1.306 0 2.417.835 2.83 2M9 14a3.001 3.001 0 00-2.83 2M15 11h3m-3 4h2"/></svg>
                </div>
                <div>
                    <h3 class="text-base font-bold text-slate-900 tracking-tight">Daftar Pengajuan Verifikasi</h3>
                    <p class="text-xs text-slate-600 mt-0.5">Pemeriksaan NIK dan foto KTP pemohon secara teliti</p>
                </div>
            </div>
            <span class="text-xs font-mono font-bold text-slate-700 bg-slate-100 px-3 py-1.5 rounded-xl border border-slate-200/90 self-start sm:self-center">
                {{ $verifications->total() }} berkas terdaftar
            </span>
        </div>

        @if($verifications->isEmpty())
            <div class="py-16 text-center">
                <div class="w-14 h-14 rounded-2xl bg-slate-100 border border-slate-200 flex items-center justify-center mx-auto mb-3.5 text-slate-400">
                    <svg class="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
                </div>
                <h4 class="text-sm font-bold text-slate-900">Tidak ada data verifikasi untuk kategori ini</h4>
                <p class="text-xs text-slate-500 mt-1 max-w-sm mx-auto">Coba ganti filter status atau filter peran di atas.</p>
            </div>
        @else
            <div class="overflow-x-auto">
                <table class="w-full text-left text-xs text-slate-800 whitespace-nowrap">
                    <thead class="text-[11px] font-bold text-slate-700 uppercase tracking-wider bg-slate-50/90 border-b border-slate-200/80">
                        <tr>
                            <th class="px-6 py-3.5 whitespace-nowrap">Nama Pemohon</th>
                            <th class="px-6 py-3.5 whitespace-nowrap">No. HP & Email</th>
                            <th class="px-6 py-3.5 whitespace-nowrap">NIK (16 Digit)</th>
                            <th class="px-6 py-3.5 whitespace-nowrap">Peran</th>
                            <th class="px-6 py-3.5 whitespace-nowrap">Status</th>
                            <th class="px-6 py-3.5 whitespace-nowrap">Waktu Masuk</th>
                            <th class="px-6 py-3.5 text-right whitespace-nowrap">Aksi</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-100">
                        @foreach($verifications as $v)
                            <tr class="hover:bg-sky-50/35 transition-colors">
                                <td class="px-6 py-3.5 whitespace-nowrap">
                                    <div class="flex items-center gap-3">
                                        <div class="w-8 h-8 rounded-xl bg-[#082032] text-white flex items-center justify-center font-bold text-xs shrink-0 shadow-xs">
                                            {{ strtoupper(substr($v->user->name, 0, 1)) }}
                                        </div>
                                        <span class="font-bold text-slate-900 text-xs">{{ $v->user->name }}</span>
                                    </div>
                                </td>
                                <td class="px-6 py-3.5 whitespace-nowrap">
                                    <div class="font-semibold text-slate-900 font-mono text-xs">{{ $v->user->phone }}</div>
                                    <div class="text-[11px] text-slate-500 font-mono mt-0.5">{{ $v->user->email }}</div>
                                </td>
                                <td class="px-6 py-3.5 whitespace-nowrap">
                                    <span class="inline-flex items-center px-2.5 py-1 rounded-lg bg-slate-100 border border-slate-200/80 text-xs font-bold font-mono text-slate-800 tracking-wider">
                                        {{ $v->nik }}
                                    </span>
                                </td>
                                <td class="px-6 py-3.5 whitespace-nowrap">
                                    <span class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-bold {{ $v->user->active_role === 'assistant' ? 'bg-orange-50 text-orange-950 border border-orange-300/80' : 'bg-sky-50 text-sky-950 border border-sky-300/80' }}">
                                        <span class="w-1.5 h-1.5 rounded-full {{ $v->user->active_role === 'assistant' ? 'bg-[#FF6B35]' : 'bg-[#0C5D8F]' }}"></span>
                                        {{ $v->user->active_role === 'assistant' ? 'Asisten' : 'Pencari' }}
                                    </span>
                                </td>
                                <td class="px-6 py-3.5 whitespace-nowrap">
                                    @if($v->status === 'pending')
                                        <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-amber-100 text-amber-950 border border-amber-300/90">
                                            <span class="w-1.5 h-1.5 rounded-full bg-amber-600 animate-pulse"></span>
                                            Menunggu
                                        </span>
                                    @elseif($v->status === 'verified')
                                        <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-emerald-100 text-emerald-950 border border-emerald-300/90">
                                            <span class="w-1.5 h-1.5 rounded-full bg-emerald-600"></span>
                                            Terverifikasi
                                        </span>
                                    @else
                                        <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-rose-100 text-rose-950 border border-rose-300/90">
                                            <span class="w-1.5 h-1.5 rounded-full bg-rose-600"></span>
                                            Ditolak
                                        </span>
                                    @endif
                                </td>
                                <td class="px-6 py-3.5 whitespace-nowrap">
                                    <div class="font-medium text-slate-800 text-xs">{{ $v->created_at->format('d M Y') }}</div>
                                    <div class="text-[11px] text-slate-500 font-mono mt-0.5">{{ $v->created_at->format('H:i') }} WIB</div>
                                </td>
                                <td class="px-6 py-3.5 text-right whitespace-nowrap">
                                    <a href="{{ route('admin.verifications.show', $v->id) }}"
                                       class="inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl bg-[#082032] hover:bg-[#FF6B35] text-white text-xs font-bold transition-all shadow-xs group">
                                       <span>Periksa Berkas</span>
                                       <svg class="w-3.5 h-3.5 transition-transform group-hover:translate-x-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>
                                    </a>
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>

            <div class="px-6 py-4 border-t border-slate-100 bg-slate-50/50">
                {{ $verifications->links() }}
            </div>
        @endif
    </div>
</div>
@endsection
