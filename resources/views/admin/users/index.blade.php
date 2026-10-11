@extends('admin.layout')

@section('title', 'Daftar Majikan & Asisten')
@section('header', 'Kelola Pengguna: Majikan & Asisten')

@section('content')
<div class="space-y-6">
    <!-- Filter Tabs & Search Bar -->
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <!-- Tabs -->
        <div class="flex items-center gap-2 border-b border-[#E2D9CC] pb-1 text-xs">
            <a href="{{ route('admin.users.index', ['role' => 'all', 'search' => $search]) }}" 
               class="px-3.5 py-2 rounded-lg font-medium transition-colors {{ $role === 'all' ? 'bg-[#244C7C] text-white' : 'text-[#5A5146] hover:bg-[#F3EEE6]' }}">
                Semua Pengguna ({{ $counts['all'] }})
            </a>
            <a href="{{ route('admin.users.index', ['role' => 'seeker', 'search' => $search]) }}" 
               class="px-3.5 py-2 rounded-lg font-medium transition-colors {{ $role === 'seeker' ? 'bg-[#244C7C] text-white' : 'text-[#5A5146] hover:bg-[#F3EEE6]' }}">
                Pencari / Majikan ({{ $counts['seeker'] }})
            </a>
            <a href="{{ route('admin.users.index', ['role' => 'assistant', 'search' => $search]) }}" 
               class="px-3.5 py-2 rounded-lg font-medium transition-colors {{ $role === 'assistant' ? 'bg-[#244C7C] text-white' : 'text-[#5A5146] hover:bg-[#F3EEE6]' }}">
                Asisten Rumah Tangga ({{ $counts['assistant'] }})
            </a>
        </div>

        <!-- Search Form -->
        <form method="GET" action="{{ route('admin.users.index') }}" class="flex items-center gap-2">
            <input type="hidden" name="role" value="{{ $role }}">
            <div class="relative">
                <input type="text" name="search" value="{{ $search }}" placeholder="Cari nama, email, no HP..." 
                       class="text-xs pl-8 pr-3 py-2 bg-white rounded-lg border border-[#E2D9CC] focus:border-[#244C7C] outline-none">
                <svg class="w-4 h-4 absolute left-2.5 top-1/2 -translate-y-1/2 text-[#8C8070]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                </svg>
            </div>
            <button type="submit" class="px-3 py-2 bg-[#FAF7F2] hover:bg-[#EAE4DC] border border-[#E2D9CC] rounded-lg text-xs font-semibold text-[#1F1B16]">
                Cari
            </button>
            @if($search)
                <a href="{{ route('admin.users.index', ['role' => $role]) }}" class="text-xs text-[#B3261E] hover:underline">Reset</a>
            @endif
        </form>
    </div>

    <!-- Users Table Card -->
    <div class="bg-white rounded-2xl border border-[#E2D9CC] shadow-sm overflow-hidden">
        <div class="px-6 py-4 border-b border-[#E2D9CC] flex items-center justify-between">
            <div>
                <h3 class="text-sm font-bold text-[#1F1B16] uppercase tracking-wide">Data Pengguna Terdaftar</h3>
                <p class="text-xs text-[#5A5146]">Pengawasan akun majikan pencari asisten dan pekerja lapangan</p>
            </div>
            <span class="text-xs text-[#5A5146] font-mono">Total: {{ $users->total() }} akun</span>
        </div>

        @if($users->isEmpty())
            <div class="p-12 text-center text-[#5A5146]">
                <p class="text-sm">Tidak ditemukan data pengguna yang cocok.</p>
            </div>
        @else
            <div class="overflow-x-auto">
                <table class="w-full text-left text-xs text-[#1F1B16]">
                    <thead class="bg-[#FAF7F2] uppercase font-semibold text-[#5A5146] border-b border-[#E2D9CC]">
                        <tr>
                            <th class="px-6 py-3.5">Nama & Kontak</th>
                            <th class="px-6 py-3.5">Peran Aktif</th>
                            <th class="px-6 py-3.5">Status KTP Dukcapil</th>
                            <th class="px-6 py-3.5">Keahlian / Bio</th>
                            <th class="px-6 py-3.5">Bergabung</th>
                            <th class="px-6 py-3.5 text-right">Aksi</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-[#E2D9CC]/60">
                        @foreach($users as $u)
                            <tr class="hover:bg-[#FAF7F2]/50 transition-colors">
                                <td class="px-6 py-4">
                                    <div class="flex items-center gap-3">
                                        <div class="w-8 h-8 rounded-full bg-[#244C7C] text-white flex items-center justify-center font-bold text-xs">
                                            {{ strtoupper(substr($u->name, 0, 1)) }}
                                        </div>
                                        <div>
                                            <div class="font-bold text-[#1F1B16] text-sm">{{ $u->name }}</div>
                                            <div class="text-[11px] text-[#5A5146] font-mono">{{ $u->phone }} &bull; {{ $u->email }}</div>
                                        </div>
                                    </div>
                                </td>
                                <td class="px-6 py-4">
                                    <span class="inline-flex items-center px-2 py-0.5 rounded text-[11px] font-semibold {{ $u->active_role === 'assistant' ? 'bg-[#F8E9DC] text-[#9A4E1C]' : 'bg-[#E4ECF7] text-[#244C7C]' }}">
                                        {{ $u->active_role === 'assistant' ? 'Asisten Kerja' : 'Majikan (Pencari)' }}
                                    </span>
                                </td>
                                <td class="px-6 py-4">
                                    @if($u->is_verified)
                                        <span class="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-semibold bg-[#E3F2EA] text-[#1B6E45]">
                                            <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
                                                <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
                                            </svg>
                                            Terverifikasi Sah
                                        </span>
                                    @elseif($u->verification && $u->verification->status === 'pending')
                                        <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-[11px] font-semibold bg-[#FFF1D6] text-[#8A5200]">
                                            Menunggu Tinjau KTP
                                        </span>
                                    @else
                                        <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-[11px] font-medium bg-[#EAE4DC] text-[#5A5146]">
                                            Belum Unggah KTP
                                        </span>
                                    @endif
                                </td>
                                <td class="px-6 py-4 max-w-xs truncate text-[11px] text-[#5A5146]">
                                    @if($u->assistantProfile)
                                        {{ Str::limit($u->assistantProfile->bio ?? 'Tersedia bekerja', 35) }}
                                    @else
                                        <span class="text-[#8C8070] italic">Profil Majikan</span>
                                    @endif
                                </td>
                                <td class="px-6 py-4 text-[11px] text-[#5A5146] font-mono">
                                    {{ $u->created_at->format('d M Y') }}
                                </td>
                                <td class="px-6 py-4 text-right">
                                    @if($u->verification)
                                        <a href="{{ route('admin.verifications.show', $u->verification->id) }}" 
                                           class="inline-flex items-center px-2.5 py-1 rounded bg-[#FAF7F2] border border-[#E2D9CC] text-[#244C7C] font-semibold hover:bg-[#EAE4DC] text-[11px]">
                                            Lihat KTP &rarr;
                                        </a>
                                    @else
                                        <span class="text-[#8C8070] text-[11px]">-</span>
                                    @endif
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>

            <div class="px-6 py-4 border-t border-[#E2D9CC]">
                {{ $users->links() }}
            </div>
        @endif
    </div>
</div>
@endsection
