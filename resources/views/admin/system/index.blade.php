@extends('admin.layout')

@section('title', 'Status Sistem & Panduan API')
@section('header', 'Status Server & Panduan Integrasi Sistem')

@section('content')
<div class="space-y-6">

    <!-- System Status Grid -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-5">
        <!-- Card 1: Server Runtime -->
        <div class="bg-white rounded-2xl border border-[#E2D9CC] p-5 shadow-sm space-y-3">
            <div class="flex items-center justify-between pb-2 border-b border-[#E2D9CC]/60">
                <h3 class="text-xs font-bold text-[#1F1B16] uppercase tracking-wide">Runtime Backend</h3>
                <span class="inline-flex items-center gap-1 text-[10px] font-semibold text-[#1B6E45]">
                    <span class="w-2 h-2 rounded-full bg-[#1B6E45]"></span> Normal
                </span>
            </div>
            <div class="space-y-2 text-xs">
                <div class="flex justify-between py-1 border-b border-[#FAF7F2]">
                    <span class="text-[#5A5146]">Framework:</span>
                    <span class="font-mono font-bold text-[#1F1B16]">Laravel {{ $systemInfo['laravel_version'] }}</span>
                </div>
                <div class="flex justify-between py-1 border-b border-[#FAF7F2]">
                    <span class="text-[#5A5146]">PHP Engine:</span>
                    <span class="font-mono font-bold text-[#1F1B16]">{{ $systemInfo['php_version'] }}</span>
                </div>
                <div class="flex justify-between py-1 border-b border-[#FAF7F2]">
                    <span class="text-[#5A5146]">Driver Database:</span>
                    <span class="font-mono font-bold text-[#244C7C] uppercase">{{ $systemInfo['database'] }}</span>
                </div>
                <div class="flex justify-between py-1">
                    <span class="text-[#5A5146]">Lingkungan (Env):</span>
                    <span class="font-mono font-semibold text-[#9A4E1C]">{{ $systemInfo['environment'] }}</span>
                </div>
            </div>
        </div>

        <!-- Card 2: Payment Gateway & Escrow -->
        <div class="bg-white rounded-2xl border border-[#E2D9CC] p-5 shadow-sm space-y-3">
            <div class="flex items-center justify-between pb-2 border-b border-[#E2D9CC]/60">
                <h3 class="text-xs font-bold text-[#1F1B16] uppercase tracking-wide">Xendit Escrow Gateway</h3>
                <span class="inline-flex items-center gap-1 text-[10px] font-semibold text-[#1B6E45]">
                    <span class="w-2 h-2 rounded-full bg-[#1B6E45]"></span> Siap
                </span>
            </div>
            <div class="space-y-2 text-xs">
                <div class="flex justify-between py-1 border-b border-[#FAF7F2]">
                    <span class="text-[#5A5146]">Koneksi API:</span>
                    <span class="font-semibold text-[#1F1B16]">{{ $systemInfo['xendit_status'] }}</span>
                </div>
                <div class="flex justify-between py-1 border-b border-[#FAF7F2]">
                    <span class="text-[#5A5146]">Metode Bayar:</span>
                    <span class="font-semibold text-[#1F1B16]">VA, QRIS, E-Wallet</span>
                </div>
                <div class="flex justify-between py-1 border-b border-[#FAF7F2]">
                    <span class="text-[#5A5146]">Webhook Log:</span>
                    <span class="font-mono font-bold text-[#244C7C]">{{ $systemInfo['webhook_count'] }} Event Diterima</span>
                </div>
                <div class="flex justify-between py-1">
                    <span class="text-[#5A5146]">Keamanan:</span>
                    <span class="font-semibold text-[#1B6E45]">HMAC Signature Checked</span>
                </div>
            </div>
        </div>

        <!-- Card 3: Google Meet & Integrasi -->
        <div class="bg-white rounded-2xl border border-[#E2D9CC] p-5 shadow-sm space-y-3">
            <div class="flex items-center justify-between pb-2 border-b border-[#E2D9CC]/60">
                <h3 class="text-xs font-bold text-[#1F1B16] uppercase tracking-wide">Google Meet API</h3>
                <span class="inline-flex items-center gap-1 text-[10px] font-semibold text-[#1B6E45]">
                    <span class="w-2 h-2 rounded-full bg-[#1B6E45]"></span> Terhubung
                </span>
            </div>
            <div class="space-y-2 text-xs">
                <div class="flex justify-between py-1 border-b border-[#FAF7F2]">
                    <span class="text-[#5A5146]">Status OAuth:</span>
                    <span class="font-semibold text-[#1B6E45]">{{ $systemInfo['google_meet_status'] }}</span>
                </div>
                <div class="flex justify-between py-1 border-b border-[#FAF7F2]">
                    <span class="text-[#5A5146]">Format Link:</span>
                    <span class="font-mono text-[11px] text-[#244C7C]">https://meet.google.com/***</span>
                </div>
                <div class="flex justify-between py-1 border-b border-[#FAF7F2]">
                    <span class="text-[#5A5146]">Durasi Standar:</span>
                    <span class="font-semibold text-[#1F1B16]">45 Menit / Wawancara</span>
                </div>
                <div class="flex justify-between py-1">
                    <span class="text-[#5A5146]">Sinkronisasi:</span>
                    <span class="font-semibold text-[#1F1B16]">Otomatis saat Shortlist</span>
                </div>
            </div>
        </div>
    </div>

    <!-- API Routes Reference for Mobile Apps -->
    <div class="bg-white rounded-2xl border border-[#E2D9CC] shadow-sm overflow-hidden">
        <div class="px-6 py-4 border-b border-[#E2D9CC] flex items-center justify-between">
            <div>
                <h3 class="text-sm font-bold text-[#1F1B16] uppercase tracking-wide">Katalog REST API v1 untuk Aplikasi Mobile Flutter</h3>
                <p class="text-xs text-[#5A5146]">Standard Envelope: { "data": ..., "meta": ... } & { "error": { "code", "message", "fields" } }</p>
            </div>
            <a href="/api/v1/listings" target="_blank" 
               class="inline-flex items-center gap-1 px-3 py-1.5 rounded-lg bg-[#244C7C] text-white text-xs font-semibold hover:bg-[#1a385c]">
                <span>Cek Response JSON</span> &rarr;
            </a>
        </div>

        <div class="divide-y divide-[#E2D9CC]/60 text-xs">
            <div class="p-4 flex flex-col sm:flex-row sm:items-center justify-between gap-2 hover:bg-[#FAF7F2]/50">
                <div class="flex items-center gap-3">
                    <span class="px-2 py-0.5 rounded font-mono font-bold bg-[#E4ECF7] text-[#244C7C]">POST</span>
                    <span class="font-mono font-semibold text-[#1F1B16]">/api/v1/auth/register & /api/v1/auth/login</span>
                </div>
                <span class="text-[#5A5146]">Autentikasi akun, token Sanctum Bearer, dan pemilihan peran (Seeker / Assistant)</span>
            </div>

            <div class="p-4 flex flex-col sm:flex-row sm:items-center justify-between gap-2 hover:bg-[#FAF7F2]/50">
                <div class="flex items-center gap-3">
                    <span class="px-2 py-0.5 rounded font-mono font-bold bg-[#E4ECF7] text-[#244C7C]">POST</span>
                    <span class="font-mono font-semibold text-[#1F1B16]">/api/v1/verifications</span>
                </div>
                <span class="text-[#5A5146]">Pengunggahan foto KTP & foto selfie dengan multipart form-data terenkripsi</span>
            </div>

            <div class="p-4 flex flex-col sm:flex-row sm:items-center justify-between gap-2 hover:bg-[#FAF7F2]/50">
                <div class="flex items-center gap-3">
                    <span class="px-2 py-0.5 rounded font-mono font-bold bg-[#E3F2EA] text-[#1B6E45]">GET</span>
                    <span class="font-mono font-semibold text-[#1F1B16]">/api/v1/listings</span>
                </div>
                <span class="text-[#5A5146]">Eksplorasi lowongan kerja publik dengan filter kategori, kota, dan rentang gaji</span>
            </div>

            <div class="p-4 flex flex-col sm:flex-row sm:items-center justify-between gap-2 hover:bg-[#FAF7F2]/50">
                <div class="flex items-center gap-3">
                    <span class="px-2 py-0.5 rounded font-mono font-bold bg-[#E4ECF7] text-[#244C7C]">POST</span>
                    <span class="font-mono font-semibold text-[#1F1B16]">/api/v1/applications</span>
                </div>
                <span class="text-[#5A5146]">Pengajuan lamaran asisten ke lowongan kerja beserta tarif penawaran</span>
            </div>

            <div class="p-4 flex flex-col sm:flex-row sm:items-center justify-between gap-2 hover:bg-[#FAF7F2]/50">
                <div class="flex items-center gap-3">
                    <span class="px-2 py-0.5 rounded font-mono font-bold bg-[#E4ECF7] text-[#244C7C]">POST</span>
                    <span class="font-mono font-semibold text-[#1F1B16]">/api/v1/bookings</span>
                </div>
                <span class="text-[#5A5146]">Penerbitan kontrak kerja escrow bertermin dan invoice pembayaran Xendit</span>
            </div>

            <div class="p-4 flex flex-col sm:flex-row sm:items-center justify-between gap-2 hover:bg-[#FAF7F2]/50">
                <div class="flex items-center gap-3">
                    <span class="px-2 py-0.5 rounded font-mono font-bold bg-[#F8E9DC] text-[#9A4E1C]">POST</span>
                    <span class="font-mono font-semibold text-[#1F1B16]">/api/v1/webhooks/xendit</span>
                </div>
                <span class="text-[#5A5146]">Penerima notifikasi otomatis settlement pembayaran invoice dan pencairan dana</span>
            </div>
        </div>
    </div>
</div>
@endsection
