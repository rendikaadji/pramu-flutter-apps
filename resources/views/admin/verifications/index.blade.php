@extends('admin.layout')

@section('title', 'Verifikasi KTP & Identitas')
@section('header', 'Verifikasi KTP & Identitas Pengguna')

@section('content')
<div class="space-y-6">
    <!-- Filter Tabs -->
    <div class="flex items-center gap-2 border-b border-[#E2D9CC] pb-3 text-sm">
        <a href="{{ route('admin.verifications.index', ['status' => 'pending']) }}" 
           class="px-4 py-2 rounded-lg font-medium transition-colors {{ $status === 'pending' ? 'bg-[#244C7C] text-white' : 'text-[#5A5146] hover:bg-[#F3EEE6]' }}">
            Menunggu Tinjauan
        </a>
        <a href="{{ route('admin.verifications.index', ['status' => 'verified']) }}" 
           class="px-4 py-2 rounded-lg font-medium transition-colors {{ $status === 'verified' ? 'bg-[#244C7C] text-white' : 'text-[#5A5146] hover:bg-[#F3EEE6]' }}">
            Terverifikasi
        </a>
        <a href="{{ route('admin.verifications.index', ['status' => 'rejected']) }}" 
           class="px-4 py-2 rounded-lg font-medium transition-colors {{ $status === 'rejected' ? 'bg-[#244C7C] text-white' : 'text-[#5A5146] hover:bg-[#F3EEE6]' }}">
            Ditolak
        </a>
        <a href="{{ route('admin.verifications.index', ['status' => 'all']) }}" 
           class="px-4 py-2 rounded-lg font-medium transition-colors {{ $status === 'all' ? 'bg-[#244C7C] text-white' : 'text-[#5A5146] hover:bg-[#F3EEE6]' }}">
            Semua Riwayat
        </a>
    </div>

    <!-- Table Card -->
    <div class="bg-white rounded-xl border border-[#E2D9CC] shadow-sm overflow-hidden">
        @if($verifications->isEmpty())
            <div class="p-12 text-center text-[#5A5146]">
                <svg class="w-12 h-12 mx-auto text-[#8C8070] opacity-50 mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
                <p class="text-sm font-medium">Tidak ada data verifikasi untuk kategori ini.</p>
            </div>
        @else
            <div class="overflow-x-auto">
                <table class="w-full text-left text-sm text-[#1F1B16]">
                    <thead class="bg-[#FAF7F2] text-xs uppercase font-medium text-[#5A5146] border-b border-[#E2D9CC]">
                        <tr>
                            <th class="px-6 py-3">Nama Pemohon</th>
                            <th class="px-6 py-3">No. HP & Email</th>
                            <th class="px-6 py-3">NIK (16 Digit)</th>
                            <th class="px-6 py-3">Peran</th>
                            <th class="px-6 py-3">Status</th>
                            <th class="px-6 py-3">Waktu Masuk</th>
                            <th class="px-6 py-3 text-right">Aksi</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-[#E2D9CC]">
                        @foreach($verifications as $v)
                            <tr class="hover:bg-[#FAF7F2]/50 transition-colors">
                                <td class="px-6 py-4 font-semibold text-[#1F1B16]">{{ $v->user->name }}</td>
                                <td class="px-6 py-4 text-xs text-[#5A5146]">
                                    <div>{{ $v->user->phone }}</div>
                                    <div class="text-[#8C8070]">{{ $v->user->email }}</div>
                                </td>
                                <td class="px-6 py-4 font-mono text-xs">{{ $v->nik }}</td>
                                <td class="px-6 py-4">
                                    <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium {{ $v->user->active_role === 'assistant' ? 'bg-[#F8E9DC] text-[#9A4E1C]' : 'bg-[#E4ECF7] text-[#244C7C]' }}">
                                        {{ $v->user->active_role === 'assistant' ? 'Asisten' : 'Pencari' }}
                                    </span>
                                </td>
                                <td class="px-6 py-4">
                                    @if($v->status === 'pending')
                                        <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-[#FFF1D6] text-[#8A5200]">
                                            Menunggu
                                        </span>
                                    @elseif($v->status === 'verified')
                                        <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-[#E3F2EA] text-[#1B6E45]">
                                            Terverifikasi
                                        </span>
                                    @else
                                        <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-[#FBE5E3] text-[#B3261E]">
                                            Ditolak
                                        </span>
                                    @endif
                                </td>
                                <td class="px-6 py-4 text-xs text-[#5A5146]">{{ $v->created_at->format('d M Y, H:i') }}</td>
                                <td class="px-6 py-4 text-right">
                                    <a href="{{ route('admin.verifications.show', $v->id) }}" 
                                       class="inline-flex items-center px-3 py-1.5 rounded-lg bg-[#244C7C] text-white text-xs font-medium hover:bg-[#1a385c] transition-colors">
                                        Periksa Berkas &rarr;
                                    </a>
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>

            <div class="px-6 py-4 border-t border-[#E2D9CC]">
                {{ $verifications->links() }}
            </div>
        @endif
    </div>
</div>
@endsection

