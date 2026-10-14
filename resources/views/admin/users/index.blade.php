@extends('admin.layout')

@section('title', 'Daftar Majikan & Asisten')

@section('content')
<div class="space-y-6">

    <!-- Page Header (Canvas Text) -->
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 text-white">
        <div>
            <div class="flex items-center gap-2 mb-1.5">
                <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-white/10 text-cyan-200 border border-white/20 backdrop-blur-xs">
                    <span class="w-1.5 h-1.5 rounded-full bg-cyan-400"></span>
                    Basis Pengguna Terverifikasi
                </span>
            </div>
            <h1 class="text-2xl sm:text-3xl font-extrabold tracking-tight text-white">Kelola Pengguna</h1>
            <p class="text-xs sm:text-sm text-sky-100/90 mt-1 font-normal">Pengawasan akun majikan pencari asisten dan pekerja lapangan terdaftar</p>
        </div>
        <div class="flex items-center gap-2.5">
            <div class="flex items-center gap-2 text-xs text-white bg-white/10 border border-white/20 px-4 py-2 rounded-xl backdrop-blur-xs shadow-inner">
                <span class="text-sky-200 font-medium">Total Akun:</span>
                <strong class="text-white font-mono font-bold text-sm">{{ $users->total() }}</strong>
            </div>
        </div>
    </div>

    <!-- Filter & Search Card (Launchly White Card Style) -->
    <div class="bg-white rounded-2xl p-5 sm:p-6 shadow-md border border-slate-100">
        <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
            <!-- Role Tabs -->
            <div class="flex flex-wrap items-center gap-2">
                <a href="{{ route('admin.users.index', ['role' => 'all', 'search' => $search]) }}"
                   class="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-semibold transition-all {{ $role === 'all' ? 'bg-[#082032] text-white shadow-sm' : 'text-slate-700 bg-white hover:bg-slate-50 border border-slate-200/90 hover:border-slate-300' }}">
                    <span>Semua Pengguna</span>
                    <span class="ml-1 px-1.5 py-0.5 rounded-full text-[10px] font-bold font-mono {{ $role === 'all' ? 'bg-white/20 text-white' : 'bg-slate-100 text-slate-700 border border-slate-200' }}">
                        {{ $counts['all'] }}
                    </span>
                </a>
                <a href="{{ route('admin.users.index', ['role' => 'seeker', 'search' => $search]) }}"
                   class="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-semibold transition-all {{ $role === 'seeker' ? 'bg-[#0C5D8F] text-white shadow-sm shadow-[#0C5D8F]/30' : 'text-slate-700 bg-white hover:bg-slate-50 border border-slate-200/90 hover:border-slate-300' }}">
                    <span>Pencari / Majikan</span>
                    <span class="ml-1 px-1.5 py-0.5 rounded-full text-[10px] font-bold font-mono {{ $role === 'seeker' ? 'bg-white/20 text-white' : 'bg-sky-50 text-sky-950 border border-sky-200' }}">
                        {{ $counts['seeker'] }}
                    </span>
                </a>
                <a href="{{ route('admin.users.index', ['role' => 'assistant', 'search' => $search]) }}"
                   class="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-semibold transition-all {{ $role === 'assistant' ? 'bg-[#FF6B35] text-white shadow-sm shadow-[#FF6B35]/30' : 'text-slate-700 bg-white hover:bg-slate-50 border border-slate-200/90 hover:border-slate-300' }}">
                    <span>Asisten Rumah Tangga</span>
                    <span class="ml-1 px-1.5 py-0.5 rounded-full text-[10px] font-bold font-mono {{ $role === 'assistant' ? 'bg-white/20 text-white' : 'bg-orange-50 text-orange-950 border border-orange-200' }}">
                        {{ $counts['assistant'] }}
                    </span>
                </a>
            </div>

            <!-- Search Form -->
            <form method="GET" action="{{ route('admin.users.index') }}" class="flex items-center gap-2">
                <input type="hidden" name="role" value="{{ $role }}">
                <div class="relative w-full sm:w-64">
                    <svg class="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/></svg>
                    <input type="text" name="search" value="{{ $search }}" placeholder="Cari nama, email, no HP..."
                           class="w-full text-xs pl-9 pr-3.5 py-2 bg-slate-50 rounded-xl border border-slate-200 focus:bg-white focus:border-[#FF6B35] focus:ring-1 focus:ring-[#FF6B35] outline-none transition-all placeholder:text-slate-400 text-slate-900 font-medium">
                </div>
                <button type="submit" class="px-4 py-2 bg-[#082032] hover:bg-[#143F66] text-white rounded-xl text-xs font-bold transition-all shadow-sm">
                    Cari
                </button>
                @if($search)
                    <a href="{{ route('admin.users.index', ['role' => $role]) }}" class="text-xs text-rose-600 font-semibold hover:underline px-1">Reset</a>
                @endif
            </form>
        </div>
    </div>

    <!-- Table Card (Launchly White Card Style) -->
    <div class="bg-white rounded-2xl shadow-md border border-slate-100 overflow-hidden">
        <div class="px-6 py-4.5 border-b border-slate-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3 bg-gradient-to-r from-slate-50/70 to-white">
            <div>
                <h3 class="text-base font-bold text-slate-900 tracking-tight">Data Pengguna Terdaftar</h3>
                <p class="text-xs text-slate-600 mt-0.5">Pengawasan akun majikan pencari asisten dan pekerja lapangan</p>
            </div>
            <span class="text-xs font-mono font-bold text-slate-700 bg-slate-100 px-3 py-1.5 rounded-xl border border-slate-200/90 self-start sm:self-center">
                Total: {{ $users->total() }} akun
            </span>
        </div>

        @if($users->isEmpty())
            <div class="py-16 text-center text-slate-500">
                <p class="text-sm font-bold text-slate-800">Tidak ditemukan data pengguna yang cocok</p>
                <p class="text-xs text-slate-400 mt-1">Coba gunakan kata kunci pencarian lain.</p>
            </div>
        @else
            <div class="overflow-x-auto">
                <table class="w-full text-left text-xs text-slate-800 whitespace-nowrap">
                    <thead class="text-[11px] font-bold text-slate-700 uppercase tracking-wider bg-slate-50/90 border-b border-slate-200/80">
                        <tr>
                            <th class="px-6 py-3.5 whitespace-nowrap">Nama & Kontak</th>
                            <th class="px-6 py-3.5 whitespace-nowrap">Peran Aktif</th>
                            <th class="px-6 py-3.5 whitespace-nowrap">Status Dokumen</th>
                            <th class="px-6 py-3.5 whitespace-nowrap">Keahlian / Bio</th>
                            <th class="px-6 py-3.5 whitespace-nowrap">Bergabung</th>
                            <th class="px-6 py-3.5 text-right whitespace-nowrap">Aksi</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-100">
                        @foreach($users as $u)
                            <tr class="hover:bg-sky-50/35 transition-colors">
                                <td class="px-6 py-3.5 whitespace-nowrap">
                                    <div class="flex items-center gap-3">
                                        <div class="w-8 h-8 rounded-xl {{ $u->active_role === 'assistant' ? 'bg-[#FF6B35]' : 'bg-[#082032]' }} text-white flex items-center justify-center font-bold text-xs shrink-0 shadow-xs">
                                            {{ strtoupper(substr($u->name, 0, 1)) }}
                                        </div>
                                        <div>
                                            <div class="font-bold text-slate-900 text-xs">{{ $u->name }}</div>
                                            <div class="text-[11px] text-slate-500 font-mono mt-0.5">{{ $u->phone }} &bull; {{ $u->email }}</div>
                                        </div>
                                    </div>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold {{ $u->active_role === 'assistant' ? 'bg-orange-50 text-orange-950 border border-orange-300/80' : 'bg-sky-50 text-sky-950 border border-sky-300/80' }}">
                                        <span class="w-1.5 h-1.5 rounded-full {{ $u->active_role === 'assistant' ? 'bg-[#FF6B35]' : 'bg-[#0C5D8F]' }}"></span>
                                        {{ $u->active_role === 'assistant' ? 'Asisten Kerja' : 'Majikan (Pencari)' }}
                                    </span>
                                </td>
                                <td class="px-6 py-4 space-y-2 whitespace-nowrap">
                                    <div class="flex items-center gap-2">
                                        <span class="text-xs font-bold text-slate-700 w-12">KTP:</span>
                                        @if($u->is_verified || ($u->verification && $u->verification->status === 'verified'))
                                            <span class="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-bold bg-emerald-100 text-emerald-950 border border-emerald-300/80">Terverifikasi Sah</span>
                                        @elseif($u->verification && $u->verification->status === 'pending')
                                            <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-bold bg-amber-100 text-amber-950 border border-amber-300/80">Menunggu Tinjau</span>
                                        @else
                                            <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-slate-100 text-slate-700 border border-slate-200">Belum Unggah</span>
                                        @endif
                                    </div>
                                    <div class="flex items-center gap-2">
                                        <span class="text-xs font-bold text-slate-700 w-12">SKCK:</span>
                                        @if($u->active_role === 'seeker')
                                            <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-slate-100 text-slate-700 border border-slate-200">Tidak Diperlukan</span>
                                        @elseif($u->skck && $u->skck->status === 'verified')
                                            <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-bold bg-emerald-100 text-emerald-950 border border-emerald-300/80">Sah Polisi</span>
                                        @elseif($u->skck && $u->skck->status === 'pending')
                                            <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-bold bg-amber-100 text-amber-950 border border-amber-300/80">Menunggu</span>
                                        @else
                                            <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-slate-100 text-slate-700 border border-slate-200">Belum Ada</span>
                                        @endif
                                    </div>
                                </td>
                                <td class="px-6 py-4 max-w-xs">
                                    @if($u->active_role === 'assistant')
                                        <div class="flex items-center gap-1 font-bold text-slate-900 text-xs">
                                            <span class="text-amber-500">★</span>
                                            <span>{{ number_format($u->received_reviews_avg_rating ?? 0, 1) }}</span>
                                            <span class="text-slate-500 font-normal">({{ $u->received_reviews_count ?? 0 }} ulasan)</span>
                                        </div>
                                        <div class="text-xs text-slate-600 font-medium mt-0.5">
                                            {{ $u->assistantProfile?->experience_years ? $u->assistantProfile->experience_years . ' Thn Pengalaman' : 'Asisten Baru' }}
                                        </div>
                                    @else
                                        <span class="text-slate-500 italic text-xs">Profil Majikan</span>
                                    @endif
                                </td>
                                <td class="px-6 py-4 text-slate-600 font-mono text-xs whitespace-nowrap">
                                    {{ $u->created_at->format('d M Y') }}
                                </td>
                                <td class="px-6 py-4 text-right whitespace-nowrap">
                                    <a href="{{ route('admin.users.show', $u->id) }}" 
                                       class="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-[#082032] hover:bg-[#FF6B35] text-white font-bold text-xs transition-all shadow-sm group">
                                        <span>Lihat Detail</span>
                                        <svg class="w-3.5 h-3.5 transition-transform group-hover:translate-x-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>
                                    </a>
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>

            <div class="px-6 py-4 border-t border-slate-100 bg-slate-50/50">
                {{ $users->links() }}
            </div>
        @endif
    </div>
</div>
@endsection
