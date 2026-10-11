@extends('admin.layout')

@section('title', 'Tinjau Verifikasi: ' . $verification->user->name)
@section('header', 'Tinjau Berkas Identitas KTP & Wajah')

@section('content')
<div class="max-w-5xl space-y-6">
    <!-- Back Button -->
    <div>
        <a href="{{ route('admin.verifications.index') }}" class="inline-flex items-center gap-2 text-xs font-medium text-[#244C7C] hover:underline">
            &larr; Kembali ke Daftar Verifikasi
        </a>
    </div>

    <!-- User Information Header Card -->
    <div class="bg-white rounded-xl border border-[#E2D9CC] p-6 shadow-sm">
        <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <div>
                <div class="flex items-center gap-3">
                    <h3 class="text-xl font-bold text-[#1F1B16]">{{ $verification->user->name }}</h3>
                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold {{ $verification->user->active_role === 'assistant' ? 'bg-[#F8E9DC] text-[#9A4E1C]' : 'bg-[#E4ECF7] text-[#244C7C]' }}">
                        {{ $verification->user->active_role === 'assistant' ? 'Asisten Rumah Tangga' : 'Pencari Kerja' }}
                    </span>
                </div>
                <div class="mt-2 grid grid-cols-1 sm:grid-cols-3 gap-y-1 gap-x-6 text-xs text-[#5A5146]">
                    <div>No. HP: <strong class="text-[#1F1B16]">{{ $verification->user->phone }}</strong></div>
                    <div>Email: <strong class="text-[#1F1B16]">{{ $verification->user->email }}</strong></div>
                    <div>Waktu Pengajuan: <strong class="text-[#1F1B16]">{{ $verification->created_at->format('d M Y, H:i WIB') }}</strong></div>
                </div>
            </div>

            <!-- Current Status Badge -->
            <div>
                @if($verification->status === 'pending')
                    <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-[#FFF1D6] text-[#8A5200]">
                        Menunggu Peninjauan
                    </span>
                @elseif($verification->status === 'verified')
                    <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-[#E3F2EA] text-[#1B6E45]">
                        Terverifikasi Resmi
                    </span>
                @else
                    <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-[#FBE5E3] text-[#B3261E]">
                        Ditolak
                    </span>
                @endif
            </div>
        </div>

        @if($verification->rejection_reason)
            <div class="mt-4 p-3 bg-[#FBE5E3] border border-[#B3261E]/20 text-[#B3261E] rounded-lg text-xs">
                <strong>Alasan Penolakan:</strong> {{ $verification->rejection_reason }}
            </div>
        @endif
    </div>

    <!-- Side-by-Side Document Inspection -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <!-- 1. KTP Card -->
        <div class="bg-white rounded-xl border border-[#E2D9CC] p-5 shadow-sm space-y-3">
            <div class="flex items-center justify-between border-b border-[#E2D9CC] pb-3">
                <h4 class="text-sm font-bold text-[#1F1B16]">1. Foto Kartu Tanda Penduduk (KTP)</h4>
                <span class="text-xs font-mono bg-[#FAF7F2] px-2 py-1 rounded border border-[#E2D9CC]">
                    NIK: {{ $verification->nik }}
                </span>
            </div>
            
            <div class="aspect-[16/10] bg-[#FAF7F2] rounded-lg border border-dashed border-[#8C8070] flex items-center justify-center overflow-hidden">
                @if($verification->ktp_path && file_exists(storage_path('app/' . $verification->ktp_path)))
                    <img src="{{ route('admin.file.preview', ['path' => $verification->ktp_path]) }}" alt="Foto KTP" class="w-full h-full object-contain">
                @else
                    <div class="text-center p-4">
                        <svg class="w-10 h-10 mx-auto text-[#8C8070] opacity-50 mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z"/></svg>
                        <p class="text-xs text-[#5A5146] font-medium">Berkas tersimpan di storage lokal terenkripsi</p>
                        <p class="text-[11px] font-mono text-[#8C8070] mt-1">{{ $verification->ktp_path }}</p>
                    </div>
                @endif
            </div>

            <p class="text-xs text-[#5A5146]">Pastikan: Nama, NIK 16-digit, tempat/tgl lahir, dan foto wajah terbaca jelas tanpa pantulan kilau.</p>
        </div>

        <!-- 2. Selfie Card -->
        <div class="bg-white rounded-xl border border-[#E2D9CC] p-5 shadow-sm space-y-3">
            <div class="flex items-center justify-between border-b border-[#E2D9CC] pb-3">
                <h4 class="text-sm font-bold text-[#1F1B16]">2. Foto Selfie Memegang KTP</h4>
                <span class="text-xs text-[#5A5146]">Kamera Langsung</span>
            </div>
            
            <div class="aspect-[16/10] bg-[#FAF7F2] rounded-lg border border-dashed border-[#8C8070] flex items-center justify-center overflow-hidden">
                @if($verification->selfie_path && file_exists(storage_path('app/' . $verification->selfie_path)))
                    <img src="{{ route('admin.file.preview', ['path' => $verification->selfie_path]) }}" alt="Foto Selfie" class="w-full h-full object-contain">
                @else
                    <div class="text-center p-4">
                        <svg class="w-10 h-10 mx-auto text-[#8C8070] opacity-50 mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/></svg>
                        <p class="text-xs text-[#5A5146] font-medium">Berkas tersimpan di storage lokal terenkripsi</p>
                        <p class="text-[11px] font-mono text-[#8C8070] mt-1">{{ $verification->selfie_path }}</p>
                    </div>
                @endif
            </div>

            <p class="text-xs text-[#5A5146]">Pastikan: Wajah pemohon cocok dengan foto di kartu KTP dan tidak terpotong.</p>
        </div>
    </div>

    <!-- Review Decision Actions -->
    <div class="bg-white rounded-xl border border-[#E2D9CC] p-6 shadow-sm">
        <h4 class="text-sm font-bold text-[#1F1B16] mb-3">Keputusan Petugas Verifikasi</h4>
        
        <div class="flex flex-col sm:flex-row gap-4 items-start sm:items-center justify-between">
            <div class="text-xs text-[#5A5146]">
                Persetujuan akan memberikan badge <strong>Terverifikasi</strong> dan membuka akses pasang lowongan / melamar pekerjaan.
            </div>

            <div class="flex items-center gap-3 w-full sm:w-auto">
                <!-- Reject Form Trigger -->
                <button type="button" onclick="document.getElementById('reject-form-modal').classList.toggle('hidden')" 
                        class="px-4 py-2.5 rounded-lg border border-[#B3261E] text-[#B3261E] text-xs font-semibold hover:bg-[#FBE5E3] transition-colors">
                    Tolak Berkas...
                </button>

                <!-- Approve Form -->
                <form action="{{ route('admin.verifications.approve', $verification->id) }}" method="POST">
                    @csrf
                    <button type="submit" 
                            class="px-5 py-2.5 rounded-lg bg-[#1B6E45] text-white text-xs font-semibold hover:bg-[#155435] transition-colors">
                        Setujui Verifikasi &check;
                    </button>
                </form>
            </div>
        </div>

        <!-- Inline Rejection Box (Hidden by default) -->
        <div id="reject-form-modal" class="hidden mt-4 pt-4 border-t border-[#E2D9CC]">
            <form action="{{ route('admin.verifications.reject', $verification->id) }}" method="POST" class="space-y-3">
                @csrf
                <label for="rejection_reason" class="block text-xs font-bold text-[#B3261E]">
                    Tuliskan Alasan Penolakan (akan ditampilkan di aplikasi mobile pengguna):
                </label>
                <textarea id="rejection_reason" name="rejection_reason" rows="2" required
                          placeholder="Contoh: Foto KTP buram dan nomor NIK tidak terbaca jelas. Silakan foto ulang di tempat terang."
                          class="w-full text-xs p-3 rounded-lg border border-[#E2D9CC] focus:border-[#B3261E] focus:ring-1 focus:ring-[#B3261E] outline-none"></textarea>
                <div class="flex justify-end gap-2">
                    <button type="button" onclick="document.getElementById('reject-form-modal').classList.add('hidden')"
                            class="px-3 py-1.5 text-xs text-[#5A5146] hover:underline">
                        Batal
                    </button>
                    <button type="submit" 
                            class="px-4 py-1.5 rounded-lg bg-[#B3261E] text-white text-xs font-semibold hover:bg-[#8f1e18]">
                        Kirim Penolakan
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>
@endsection

