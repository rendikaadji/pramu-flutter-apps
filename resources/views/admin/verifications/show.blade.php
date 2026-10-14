@extends('admin.layout')

@section('title', 'Tinjau Verifikasi: ' . $verification->user->name)
@section('header', 'Tinjau Berkas Identitas KTP & Wajah')

@section('content')
<div class="max-w-5xl space-y-6">
    <!-- Breadcrumb & Back Navigation -->
    <div class="flex items-center justify-between gap-4">
        <a href="{{ route('admin.verifications.index') }}" 
           class="inline-flex items-center gap-2 text-xs font-semibold text-white/90 hover:text-white bg-white/10 hover:bg-white/15 px-3.5 py-2 rounded-xl border border-white/15 backdrop-blur-xs transition-all shadow-xs">
            <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"/>
            </svg>
            <span>Kembali ke Daftar Verifikasi</span>
        </a>
        <div class="hidden sm:flex items-center gap-2 text-xs text-cyan-200/70 font-mono">
            <span>Verifikasi</span>
            <span>&bull;</span>
            <span class="text-white font-semibold">Tinjau Berkas Identitas</span>
        </div>
    </div>

    <!-- User Information Header Card (Launchly Style) -->
    <div class="bg-white rounded-2xl border border-slate-100 p-6 sm:p-7 shadow-md space-y-5">
        <!-- Top Row: User Avatar, Name, Role Badge, Status Badge & Action Button -->
        <div class="flex flex-col md:flex-row md:items-center justify-between gap-5 border-b border-slate-100 pb-5">
            <div class="flex items-center gap-4">
                <div class="w-13 h-13 rounded-2xl bg-[#082032] text-white flex items-center justify-center font-black text-xl shrink-0 shadow-sm border border-slate-700/20">
                    {{ strtoupper(substr($verification->user->name, 0, 1)) }}
                </div>
                <div>
                    <div class="flex flex-wrap items-center gap-2.5">
                        <h3 class="text-xl font-extrabold text-slate-900 tracking-tight leading-tight">{{ $verification->user->name }}</h3>
                        <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-bold whitespace-nowrap {{ $verification->user->active_role === 'assistant' ? 'bg-orange-50 text-orange-950 border border-orange-300' : 'bg-sky-50 text-sky-950 border border-sky-300' }}">
                            {{ $verification->user->active_role === 'assistant' ? 'Asisten Rumah Tangga' : 'Pencari Kerja (Majikan)' }}
                        </span>
                        
                        @if($verification->status === 'pending')
                            <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-amber-100 text-amber-950 border border-amber-300 whitespace-nowrap">
                                <span class="w-2 h-2 rounded-full bg-amber-600 animate-pulse"></span>
                                Menunggu Peninjauan
                            </span>
                        @elseif($verification->status === 'verified')
                            <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-emerald-100 text-emerald-950 border border-emerald-300 whitespace-nowrap">
                                <span class="w-1.5 h-1.5 rounded-full bg-emerald-600"></span>
                                Terverifikasi Resmi
                            </span>
                        @else
                            <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-rose-100 text-rose-950 border border-rose-300 whitespace-nowrap">
                                <span class="w-1.5 h-1.5 rounded-full bg-rose-600"></span>
                                Ditolak
                            </span>
                        @endif
                    </div>
                    <p class="text-xs text-slate-500 mt-1">ID Pengguna: <span class="font-mono text-slate-700">#{{ substr($verification->user->id, 0, 8) }}</span></p>
                </div>
            </div>

            <!-- Action Button: Lihat Detail Pengguna -->
            <div class="flex items-center gap-3 shrink-0 self-start md:self-center">
                <a href="{{ route('admin.users.show', $verification->user->id) }}" 
                   class="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-slate-50 hover:bg-[#082032] text-slate-800 hover:text-white border border-slate-200 hover:border-[#082032] font-bold text-xs transition-all shadow-xs whitespace-nowrap group">
                    <svg class="w-4 h-4 text-slate-500 group-hover:text-cyan-300 transition-colors" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/>
                    </svg>
                    <span>Lihat Detail Pengguna</span>
                    <span class="text-slate-400 group-hover:text-white transition-colors">&rarr;</span>
                </a>
            </div>
        </div>

        <!-- Bottom Metadata Grid (Phone, Email, Submission Date, Rating, SKCK) -->
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-3.5 pt-1">
            <div class="p-3 bg-slate-50/80 rounded-xl border border-slate-100 flex flex-col justify-center">
                <span class="text-[10px] font-bold text-slate-400 uppercase tracking-wider">No. Telepon / HP</span>
                <span class="text-xs font-bold font-mono text-slate-900 mt-0.5">{{ $verification->user->phone }}</span>
            </div>
            
            <div class="p-3 bg-slate-50/80 rounded-xl border border-slate-100 flex flex-col justify-center">
                <span class="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Alamat Email</span>
                <span class="text-xs font-bold font-mono text-slate-900 mt-0.5 truncate" title="{{ $verification->user->email }}">{{ $verification->user->email }}</span>
            </div>

            <div class="p-3 bg-slate-50/80 rounded-xl border border-slate-100 flex flex-col justify-center">
                <span class="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Waktu Pengajuan</span>
                <span class="text-xs font-bold font-mono text-slate-900 mt-0.5">{{ $verification->created_at->format('d M Y, H:i') }} WIB</span>
            </div>

            <div class="p-3 bg-slate-50/80 rounded-xl border border-slate-100 flex flex-col justify-center">
                <span class="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Rating Asisten</span>
                <div class="flex items-center gap-1.5 mt-0.5">
                    <span class="text-xs font-bold font-mono text-amber-600">★ {{ number_format($verification->user->received_reviews_avg_rating ?? 5.0, 1) }}</span>
                    <span class="text-[10px] text-slate-400">({{ $verification->user->received_reviews_count ?? 0 }} ulasan)</span>
                </div>
            </div>

            <div class="p-3 bg-slate-50/80 rounded-xl border border-slate-100 flex flex-col justify-center">
                <span class="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Dokumen SKCK</span>
                <span class="text-xs font-bold text-slate-900 mt-0.5">
                    {{ $verification->user->skck ? ucfirst($verification->user->skck->status) : 'Belum Ada' }}
                </span>
            </div>
        </div>

        @if($verification->rejection_reason)
            <div class="p-4 bg-rose-50 border border-rose-200 text-rose-900 rounded-xl text-xs flex items-start gap-3">
                <svg class="w-4 h-4 text-rose-600 shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/></svg>
                <div>
                    <strong class="font-bold">Catatan Penolakan Sebelumnya:</strong>
                    <p class="mt-0.5 text-rose-800 leading-relaxed">{{ $verification->rejection_reason }}</p>
                </div>
            </div>
        @endif
    </div>

    <!-- Side-by-Side Document Inspection Cards -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <!-- 1. KTP Card -->
        <div class="bg-white rounded-2xl border border-slate-100 p-6 shadow-md flex flex-col justify-between space-y-4">
            <div>
                <div class="flex items-center justify-between border-b border-slate-100 pb-3.5">
                    <div class="flex items-center gap-2">
                        <div class="w-7 h-7 rounded-lg bg-orange-50 text-[#FF6B35] flex items-center justify-center font-bold text-xs">1</div>
                        <h4 class="text-sm font-bold text-slate-900">Foto Kartu Tanda Penduduk (KTP)</h4>
                    </div>
                    <div class="flex items-center gap-1.5">
                        <span class="text-xs font-mono font-bold bg-slate-100 text-slate-900 px-3 py-1 rounded-lg border border-slate-200/90 select-all">
                            NIK: {{ $verification->nik }}
                        </span>
                    </div>
                </div>

                <!-- KTP Image Preview Box -->
                <div class="mt-4 relative group h-72 bg-slate-950/5 rounded-xl border border-slate-200/90 overflow-hidden flex items-center justify-center">
                    @php
                        $ktpExists = $verification->ktp_path && (
                            \Illuminate\Support\Facades\Storage::disk('local')->exists($verification->ktp_path) ||
                            file_exists(storage_path('app/' . $verification->ktp_path)) ||
                            file_exists(storage_path('app/private/' . $verification->ktp_path))
                        );
                    @endphp

                    @if($ktpExists)
                        <img id="preview-img-ktp" src="{{ route('admin.file.preview', ['path' => $verification->ktp_path]) }}" 
                             alt="Foto Kartu KTP Pemohon" 
                             class="w-full h-full object-contain p-2 transition-transform duration-200 group-hover:scale-[1.02]">
                        <!-- Zoom Overlay Action -->
                        <div class="absolute inset-0 bg-slate-950/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center backdrop-blur-xs">
                            <button type="button" onclick="openLightbox('{{ route('admin.file.preview', ['path' => $verification->ktp_path]) }}', 'Foto Kartu Tanda Penduduk (KTP) — NIK {{ $verification->nik }}')"
                                    class="px-4 py-2 bg-white text-slate-900 font-bold text-xs rounded-xl shadow-lg hover:bg-slate-50 transition-all flex items-center gap-2">
                                <svg class="w-4 h-4 text-[#FF6B35]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0zM10 7v3m0 0v3m0-3h3m-3 0H7"/></svg>
                                <span>Perbesar Gambar</span>
                            </button>
                        </div>
                    @else
                        <div class="text-center p-6 space-y-2">
                            <div class="w-12 h-12 rounded-2xl bg-slate-200 text-slate-500 mx-auto flex items-center justify-center">
                                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z"/></svg>
                            </div>
                            <p class="text-xs font-bold text-slate-700">Berkas Terenkripsi di Storage Lokal</p>
                            <p class="text-[11px] font-mono text-slate-400 max-w-xs break-all mx-auto">{{ $verification->ktp_path }}</p>
                        </div>
                    @endif
                </div>
            </div>

            <!-- KTP Verification Checklist -->
            <div class="pt-3 border-t border-slate-100 space-y-2 text-xs text-slate-600 bg-slate-50/50 p-3.5 rounded-xl">
                <span class="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Kriteria Pemeriksaan KTP:</span>
                <div class="flex items-center gap-2 text-slate-700">
                    <span class="w-4 h-4 rounded-full bg-emerald-100 text-emerald-700 font-bold flex items-center justify-center text-[10px]">&check;</span>
                    <span>16 digit NIK cocok dengan data profil</span>
                </div>
                <div class="flex items-center gap-2 text-slate-700">
                    <span class="w-4 h-4 rounded-full bg-emerald-100 text-emerald-700 font-bold flex items-center justify-center text-[10px]">&check;</span>
                    <span>Foto KTP tajam, terbaca jelas, dan tidak ada pantulan cahaya silau</span>
                </div>
                <div class="flex items-center gap-2 text-slate-700">
                    <span class="w-4 h-4 rounded-full bg-emerald-100 text-emerald-700 font-bold flex items-center justify-center text-[10px]">&check;</span>
                    <span>Nama dan tempat/tanggal lahir sesuai identitas asli</span>
                </div>
            </div>
        </div>

        <!-- 2. Selfie Card -->
        <div class="bg-white rounded-2xl border border-slate-100 p-6 shadow-md flex flex-col justify-between space-y-4">
            <div>
                <div class="flex items-center justify-between border-b border-slate-100 pb-3.5">
                    <div class="flex items-center gap-2">
                        <div class="w-7 h-7 rounded-lg bg-sky-50 text-[#0C5D8F] flex items-center justify-center font-bold text-xs">2</div>
                        <h4 class="text-sm font-bold text-slate-900">Foto Selfie Memegang KTP</h4>
                    </div>
                    <span class="inline-flex items-center gap-1.5 text-xs font-semibold px-2.5 py-0.5 rounded-full bg-slate-100 text-slate-700 border border-slate-200">
                        <span class="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
                        Kamera Langsung
                    </span>
                </div>

                <!-- Selfie Image Preview Box -->
                <div class="mt-4 relative group h-72 bg-slate-950/5 rounded-xl border border-slate-200/90 overflow-hidden flex items-center justify-center">
                    @php
                        $selfieExists = $verification->selfie_path && (
                            \Illuminate\Support\Facades\Storage::disk('local')->exists($verification->selfie_path) ||
                            file_exists(storage_path('app/' . $verification->selfie_path)) ||
                            file_exists(storage_path('app/private/' . $verification->selfie_path))
                        );
                    @endphp

                    @if($selfieExists)
                        <img id="preview-img-selfie" src="{{ route('admin.file.preview', ['path' => $verification->selfie_path]) }}" 
                             alt="Foto Selfie Memegang Kartu KTP" 
                             class="w-full h-full object-contain p-2 transition-transform duration-200 group-hover:scale-[1.02]">
                        <!-- Zoom Overlay Action -->
                        <div class="absolute inset-0 bg-slate-950/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center backdrop-blur-xs">
                            <button type="button" onclick="openLightbox('{{ route('admin.file.preview', ['path' => $verification->selfie_path]) }}', 'Foto Selfie Memegang KTP — {{ $verification->user->name }}')"
                                    class="px-4 py-2 bg-white text-slate-900 font-bold text-xs rounded-xl shadow-lg hover:bg-slate-50 transition-all flex items-center gap-2">
                                <svg class="w-4 h-4 text-cyan-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0zM10 7v3m0 0v3m0-3h3m-3 0H7"/></svg>
                                <span>Perbesar Gambar</span>
                            </button>
                        </div>
                    @else
                        <div class="text-center p-6 space-y-2">
                            <div class="w-12 h-12 rounded-2xl bg-slate-200 text-slate-500 mx-auto flex items-center justify-center">
                                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/></svg>
                            </div>
                            <p class="text-xs font-bold text-slate-700">Berkas Terenkripsi di Storage Lokal</p>
                            <p class="text-[11px] font-mono text-slate-400 max-w-xs break-all mx-auto">{{ $verification->selfie_path }}</p>
                        </div>
                    @endif
                </div>
            </div>

            <!-- Selfie Verification Checklist -->
            <div class="pt-3 border-t border-slate-100 space-y-2 text-xs text-slate-600 bg-slate-50/50 p-3.5 rounded-xl">
                <span class="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Kriteria Pemeriksaan Biometrik Wajah:</span>
                <div class="flex items-center gap-2 text-slate-700">
                    <span class="w-4 h-4 rounded-full bg-emerald-100 text-emerald-700 font-bold flex items-center justify-center text-[10px]">&check;</span>
                    <span>Wajah pemegang cocok dengan pasfoto di kartu KTP</span>
                </div>
                <div class="flex items-center gap-2 text-slate-700">
                    <span class="w-4 h-4 rounded-full bg-emerald-100 text-emerald-700 font-bold flex items-center justify-center text-[10px]">&check;</span>
                    <span>Fisik kartu KTP tampak jelas dipegang dan tidak tertutup jari</span>
                </div>
                <div class="flex items-center gap-2 text-slate-700">
                    <span class="w-4 h-4 rounded-full bg-emerald-100 text-emerald-700 font-bold flex items-center justify-center text-[10px]">&check;</span>
                    <span>Bukan tangkapan layar (screenshot), foto monitor, atau hasil suntingan</span>
                </div>
            </div>
        </div>
    </div>

    <!-- Review Decision Actions Card -->
    <div class="bg-white rounded-2xl border border-slate-100 p-6 sm:p-7 shadow-md space-y-4">
        <div class="flex flex-col sm:flex-row gap-4 items-start sm:items-center justify-between border-b border-slate-100 pb-4">
            <div>
                <h4 class="text-sm font-bold text-slate-900 tracking-tight">Keputusan Petugas Verifikasi</h4>
                <p class="text-xs text-slate-500 mt-0.5">
                    Persetujuan memberikan status resmi <strong class="text-emerald-700 font-semibold">Terverifikasi</strong> dan mengaktifkan fitur pencarian & lamaran kerja bagi pengguna.
                </p>
            </div>

            <!-- Action Buttons Toolbar -->
            <div class="flex items-center gap-3 w-full sm:w-auto shrink-0">
                <!-- Reject Form Trigger Button -->
                <button type="button" onclick="toggleRejectionBox()" 
                        class="px-4 py-2.5 rounded-xl border border-rose-300 hover:border-rose-400 text-rose-700 hover:bg-rose-50 text-xs font-bold transition-all whitespace-nowrap shadow-xs">
                    Tolak Berkas...
                </button>

                <!-- Approve Form Button -->
                <form action="{{ route('admin.verifications.approve', $verification->id) }}" method="POST">
                    @csrf
                    <button type="submit" 
                            class="px-5 py-2.5 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold transition-all shadow-md shadow-emerald-600/20 whitespace-nowrap flex items-center gap-1.5">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M5 13l4 4L19 7"/></svg>
                        <span>Setujui Verifikasi</span>
                    </button>
                </form>
            </div>
        </div>

        <!-- Inline Rejection Form Drawer (Hidden by default) -->
        <div id="reject-form-modal" class="hidden pt-2">
            <form action="{{ route('admin.verifications.reject', $verification->id) }}" method="POST" class="space-y-3 bg-rose-50/50 p-4.5 rounded-2xl border border-rose-200">
                @csrf
                <div class="flex items-center justify-between">
                    <label for="rejection_reason" class="block text-xs font-bold text-rose-900">
                        Tuliskan Alasan Penolakan Berkas (Akan Dikirimkan ke Pengguna):
                    </label>
                    <span class="text-[11px] text-rose-600 font-semibold">Pilih alasan cepat di bawah atau ketik manual</span>
                </div>

                <!-- Quick Reason Pills -->
                <div class="flex flex-wrap gap-2 pt-1">
                    <button type="button" onclick="setQuickReason('Foto KTP buram, kabur, atau NIK tidak dapat terbaca dengan jelas. Harap unggah ulang di tempat terang.')"
                            class="px-2.5 py-1 rounded-lg bg-white border border-rose-200 hover:border-rose-400 text-rose-800 text-[11px] font-medium transition-all">
                        + Foto KTP Buram / Silau
                    </button>
                    <button type="button" onclick="setQuickReason('Foto selfie tidak memegang kartu fisik KTP asli dengan jelas. Pastikan KTP berada di dekat wajah.')"
                            class="px-2.5 py-1 rounded-lg bg-white border border-rose-200 hover:border-rose-400 text-rose-800 text-[11px] font-medium transition-all">
                        + Selfie Tidak Memegang KTP
                    </button>
                    <button type="button" onclick="setQuickReason('Wajah pada foto selfie tidak cocok atau berbeda dengan pasfoto pada kartu tanda penduduk.')"
                            class="px-2.5 py-1 rounded-lg bg-white border border-rose-200 hover:border-rose-400 text-rose-800 text-[11px] font-medium transition-all">
                        + Wajah Tidak Cocok dengan KTP
                    </button>
                    <button type="button" onclick="setQuickReason('16 digit NIK pada formulir tidak sesuai dengan nomor NIK yang tertera pada kartu KTP.')"
                            class="px-2.5 py-1 rounded-lg bg-white border border-rose-200 hover:border-rose-400 text-rose-800 text-[11px] font-medium transition-all">
                        + NIK Tidak Sesuai Fisik KTP
                    </button>
                </div>

                <textarea id="rejection_reason" name="rejection_reason" rows="3" required
                          placeholder="Ketik rincian alasan penolakan secara jelas dan sopan..."
                          class="w-full text-xs p-3.5 rounded-xl border border-rose-200 bg-white focus:border-rose-500 focus:ring-1 focus:ring-rose-500 outline-none transition-all placeholder:text-slate-400 text-slate-900 leading-relaxed"></textarea>

                <div class="flex items-center justify-end gap-2.5 pt-1">
                    <button type="button" onclick="toggleRejectionBox()"
                            class="px-4 py-2 rounded-xl text-xs font-semibold text-slate-600 hover:bg-slate-200/60 transition-colors">
                        Batal
                    </button>
                    <button type="submit" 
                            class="px-5 py-2.5 rounded-xl bg-rose-600 hover:bg-rose-700 text-white text-xs font-bold transition-all shadow-md shadow-rose-600/20 flex items-center gap-1.5">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
                        <span>Konfirmasi Tolak Berkas</span>
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- Lightbox Modal for High-Resolution Document Inspection -->
<div id="image-lightbox-modal" class="fixed inset-0 z-50 hidden bg-[#041B2D]/90 backdrop-blur-sm flex items-center justify-center p-4 sm:p-8" onclick="closeLightbox(event)">
    <div class="relative max-w-4xl w-full bg-white rounded-2xl shadow-2xl overflow-hidden border border-slate-700/30" onclick="event.stopPropagation()">
        <!-- Lightbox Header -->
        <div class="px-6 py-4 bg-slate-900 text-white flex items-center justify-between border-b border-slate-800">
            <div class="flex items-center gap-3">
                <span class="w-2.5 h-2.5 rounded-full bg-[#FF6B35]"></span>
                <h5 id="lightbox-title" class="text-xs font-bold tracking-wide uppercase text-slate-200">Pratinjau Dokumen Resolusi Penuh</h5>
            </div>
            <button type="button" onclick="closeLightbox()" class="text-slate-400 hover:text-white p-1 rounded-lg hover:bg-white/10 transition-colors">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
            </button>
        </div>

        <!-- Lightbox Image Viewport -->
        <div class="p-4 sm:p-6 bg-slate-950 flex items-center justify-center max-h-[75vh] overflow-auto">
            <img id="lightbox-img" src="" alt="Pratinjau Berkas" class="max-h-[70vh] w-auto max-w-full object-contain rounded-lg shadow-md">
        </div>

        <!-- Lightbox Footer Controls -->
        <div class="px-6 py-3 bg-slate-900 text-slate-300 text-xs flex items-center justify-between border-t border-slate-800">
            <span class="text-[11px] text-slate-400">Gunakan mouse atau geser untuk memeriksa keaslian foto</span>
            <button type="button" onclick="closeLightbox()" class="px-3.5 py-1.5 rounded-xl bg-white/10 hover:bg-white/20 text-white text-xs font-semibold transition-colors">
                Tutup Pratinjau
            </button>
        </div>
    </div>
</div>

<script>
    function toggleRejectionBox() {
        const box = document.getElementById('reject-form-modal');
        if (box) {
            box.classList.toggle('hidden');
            if (!box.classList.contains('hidden')) {
                const textarea = document.getElementById('rejection_reason');
                if (textarea) textarea.focus();
            }
        }
    }

    function setQuickReason(text) {
        const textarea = document.getElementById('rejection_reason');
        if (textarea) {
            textarea.value = text;
            textarea.focus();
        }
    }

    function openLightbox(url, title) {
        const modal = document.getElementById('image-lightbox-modal');
        const img = document.getElementById('lightbox-img');
        const titleEl = document.getElementById('lightbox-title');
        if (modal && img) {
            img.src = url;
            if (titleEl && title) titleEl.textContent = title;
            modal.classList.remove('hidden');
            document.body.style.overflow = 'hidden';
        }
    }

    function closeLightbox() {
        const modal = document.getElementById('image-lightbox-modal');
        if (modal) {
            modal.classList.add('hidden');
            document.body.style.overflow = '';
        }
    }

    // Keyboard support: ESC to close lightbox
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') {
            closeLightbox();
        }
    });
</script>
@endsection
