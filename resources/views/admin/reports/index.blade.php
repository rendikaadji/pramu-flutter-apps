@extends('admin.layout')

@section('title', 'Laporan & Sengketa')
@section('header', 'Penyelesaian Sengketa & Moderasi Laporan')

@section('content')
<div class="space-y-6">
    <div class="bg-white rounded-xl border border-[#E2D9CC] shadow-sm overflow-hidden">
        <div class="px-6 py-4 border-b border-[#E2D9CC]">
            <h3 class="text-base font-semibold text-[#1F1B16]">Daftar Kasus & Sengketa Pengguna</h3>
            <p class="text-xs text-[#5A5146]">Mediasi masalah transaksi dan perlindungan kedua belah pihak</p>
        </div>

        @if($reports->isEmpty())
            <div class="p-12 text-center text-[#5A5146]">
                <p class="text-sm">Tidak ada laporan atau sengketa aktif saat ini.</p>
            </div>
        @else
            <div class="divide-y divide-[#E2D9CC]">
                @foreach($reports as $r)
                    <div class="p-6 space-y-4 hover:bg-[#FAF7F2]/40 transition-colors">
                        <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                            <div class="flex items-center gap-3">
                                <span class="text-xs font-mono font-bold text-[#5A5146]">#{{ substr($r->id, 0, 8) }}</span>
                                <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-semibold bg-[#F8E9DC] text-[#9A4E1C]">
                                    Kategori: {{ ucfirst($r->category) }}
                                </span>
                                <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium {{ $r->status === 'resolved' ? 'bg-[#E3F2EA] text-[#1B6E45]' : 'bg-[#FFF1D6] text-[#8A5200]' }}">
                                    Status: {{ ucfirst(str_replace('_', ' ', $r->status)) }}
                                </span>
                            </div>
                            <span class="text-xs text-[#5A5146]">{{ $r->created_at->format('d M Y, H:i') }}</span>
                        </div>

                        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs">
                            <div class="p-3 bg-[#FAF7F2] rounded-lg border border-[#E2D9CC]">
                                <span class="text-[#5A5146]">Pelapor:</span>
                                <strong class="text-[#1F1B16] ml-1">{{ $r->reporter?->name ?? 'User' }}</strong>
                            </div>
                            <div class="p-3 bg-[#FAF7F2] rounded-lg border border-[#E2D9CC]">
                                <span class="text-[#5A5146]">Dilaporkan:</span>
                                <strong class="text-[#1F1B16] ml-1">{{ $r->reported?->name ?? 'User' }}</strong>
                            </div>
                        </div>

                        <div class="text-xs text-[#1F1B16] bg-white p-3 rounded-lg border border-[#E2D9CC]">
                            <strong class="block text-[#5A5146] mb-1">Uraian Masalah:</strong>
                            <p class="whitespace-pre-line">{{ $r->description }}</p>
                        </div>

                        <!-- Chat Consent Notice -->
                        <div class="flex items-center gap-2 text-xs">
                            @if($r->share_chat_consent && $r->consent_expires_at && $r->consent_expires_at->isFuture())
                                <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded bg-[#E4ECF7] text-[#244C7C] font-medium">
                                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"/></svg>
                                    Persetujuan berbagi riwayat obrolan aktif hingga {{ $r->consent_expires_at->format('d M Y') }}
                                </span>
                            @else
                                <span class="text-[#8C8070]">Riwayat obrolan privat (tidak dibagikan).</span>
                            @endif
                        </div>

                        <!-- Resolve Form / Decision -->
                        @if($r->status !== 'resolved')
                            <form action="{{ route('admin.reports.resolve', $r->id) }}" method="POST" class="mt-3 flex gap-2">
                                @csrf
                                <input type="text" name="decision" required placeholder="Tuliskan putusan sengketa..."
                                       class="flex-1 text-xs p-2.5 rounded-lg border border-[#E2D9CC] outline-none focus:border-[#244C7C]">
                                <button type="submit" 
                                        class="px-4 py-2.5 bg-[#244C7C] text-white text-xs font-semibold rounded-lg hover:bg-[#1a385c]">
                                    Selesaikan Kasus
                                </button>
                            </form>
                        @else
                            <div class="p-3 bg-[#E3F2EA] border border-[#1B6E45]/20 text-[#1B6E45] rounded-lg text-xs">
                                <strong>Keputusan Akhir:</strong> {{ $r->decision }}
                            </div>
                        @endif
                    </div>
                @endforeach
            </div>

            <div class="px-6 py-4 border-t border-[#E2D9CC]">
                {{ $reports->links() }}
            </div>
        @endif
    </div>
</div>
@endsection
