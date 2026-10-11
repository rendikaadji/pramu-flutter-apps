<!DOCTYPE html>
<html lang="id" class="h-full bg-[#FAF7F2]">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>@yield('title', 'Admin Dashboard') — Pramu Asisten Platform</title>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <style>
        :root {
            --bg-canvas: #FAF7F2;
            --bg-surface: #FFFFFF;
            --bg-subtle: #F3EEE6;
            --border-subtle: #E2D9CC;
            --border-strong: #8C8070;
            --text-primary: #1F1B16;
            --text-muted: #5A5146;
            --primary: #244C7C;
            --accent: #9A4E1C;
            --success: #1B6E45;
            --warning: #8A5200;
            --danger: #B3261E;
        }
        body {
            background-color: var(--bg-canvas);
            color: var(--text-primary);
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
        }
        /* Custom scrollbar to look sleek and non-intrusive */
        ::-webkit-scrollbar {
            width: 6px;
            height: 6px;
        }
        ::-webkit-scrollbar-track {
            background: transparent;
        }
        ::-webkit-scrollbar-thumb {
            background: #D9D0C3;
            border-radius: 9999px;
        }
        ::-webkit-scrollbar-thumb:hover {
            background: #BFB5A5;
        }
    </style>
</head>
<body class="h-full flex overflow-hidden antialiased bg-[#FAF7F2] text-[#1F1B16]">

    <!-- Left Sidebar: Fixed Full Height with Single Clean Column -->
    <aside class="w-64 bg-white border-r border-[#E2D9CC] flex flex-col flex-shrink-0 h-full z-20">
        <!-- Logo & Header Brand -->
        <div class="h-16 px-6 border-b border-[#E2D9CC] flex items-center justify-between flex-shrink-0">
            <div class="flex items-center gap-3">
                <div class="w-9 h-9 rounded-xl bg-[#244C7C] flex items-center justify-center text-white font-bold text-base shadow-xs">
                    P
                </div>
                <div>
                    <h1 class="text-sm font-bold text-[#1F1B16] tracking-tight leading-tight">Pramu<span class="text-[#9A4E1C]">Admin</span></h1>
                    <p class="text-[11px] text-[#5A5146]">Portal Operasional</p>
                </div>
            </div>
        </div>

        <!-- Sidebar Navigation Sections (Independent Scrollbar) -->
        <div class="flex-1 overflow-y-auto px-4 py-4 space-y-6 text-xs">
            <!-- Section 1: MENU UTAMA -->
            <div>
                <div class="px-3 pb-2 text-[10px] font-bold text-[#8C8070] uppercase tracking-wider">Menu Utama</div>
                <div class="space-y-0.5">
                    <a href="{{ route('admin.dashboard') }}" 
                       class="flex items-center gap-3 px-3 py-2 rounded-xl font-medium transition-colors {{ request()->routeIs('admin.dashboard') ? 'bg-[#244C7C] text-white shadow-xs' : 'text-[#5A5146] hover:bg-[#F3EEE6] hover:text-[#1F1B16]' }}">
                        <svg class="w-4 h-4 opacity-80" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/></svg>
                        <span>Beranda Utama</span>
                    </a>
                </div>
            </div>

            <!-- Section 2: KELOLA PENGGUNA -->
            <div>
                <div class="px-3 pb-2 text-[10px] font-bold text-[#8C8070] uppercase tracking-wider">Kelola Pengguna</div>
                <div class="space-y-0.5">
                    <a href="{{ route('admin.verifications.index') }}" 
                       class="flex items-center justify-between px-3 py-2 rounded-xl font-medium transition-colors {{ request()->routeIs('admin.verifications.*') ? 'bg-[#244C7C] text-white shadow-xs' : 'text-[#5A5146] hover:bg-[#F3EEE6] hover:text-[#1F1B16]' }}">
                        <div class="flex items-center gap-3">
                            <svg class="w-4 h-4 opacity-80" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"/></svg>
                            <span>Pemeriksaan KTP & Foto</span>
                        </div>
                        @php $pendingVerifCount = \App\Models\Verification::where('status', 'pending')->count(); @endphp
                        @if($pendingVerifCount > 0)
                            <span class="px-1.5 py-0.5 rounded text-[10px] font-bold {{ request()->routeIs('admin.verifications.*') ? 'bg-white/20 text-white' : 'bg-[#9A4E1C] text-white' }}">
                                {{ $pendingVerifCount }}
                            </span>
                        @endif
                    </a>

                    <a href="{{ route('admin.users.index') }}" 
                       class="flex items-center gap-3 px-3 py-2 rounded-xl font-medium transition-colors {{ request()->routeIs('admin.users.*') ? 'bg-[#244C7C] text-white shadow-xs' : 'text-[#5A5146] hover:bg-[#F3EEE6] hover:text-[#1F1B16]' }}">
                        <svg class="w-4 h-4 opacity-80" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"/></svg>
                        <span>Daftar Majikan & Asisten</span>
                    </a>
                </div>
            </div>

            <!-- Section 3: LOWONGAN & WAWANCARA -->
            <div>
                <div class="px-3 pb-2 text-[10px] font-bold text-[#8C8070] uppercase tracking-wider">Lowongan & Wawancara</div>
                <div class="space-y-0.5">
                    <a href="{{ route('admin.listings.index') }}" 
                       class="flex items-center gap-3 px-3 py-2 rounded-xl font-medium transition-colors {{ request()->routeIs('admin.listings.*') ? 'bg-[#244C7C] text-white shadow-xs' : 'text-[#5A5146] hover:bg-[#F3EEE6] hover:text-[#1F1B16]' }}">
                        <svg class="w-4 h-4 opacity-80" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"/></svg>
                        <span>Lowongan Kerja Aktif</span>
                    </a>

                    <a href="{{ route('admin.interviews.index') }}" 
                       class="flex items-center gap-3 px-3 py-2 rounded-xl font-medium transition-colors {{ request()->routeIs('admin.interviews.*') ? 'bg-[#244C7C] text-white shadow-xs' : 'text-[#5A5146] hover:bg-[#F3EEE6] hover:text-[#1F1B16]' }}">
                        <svg class="w-4 h-4 opacity-80" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"/></svg>
                        <span>Jadwal Wawancara Online</span>
                    </a>
                </div>
            </div>

            <!-- Section 4: KONTRAK & KEUANGAN -->
            <div>
                <div class="px-3 pb-2 text-[10px] font-bold text-[#8C8070] uppercase tracking-wider">Kontrak & Keuangan</div>
                <div class="space-y-0.5">
                    <a href="{{ route('admin.bookings.index') }}" 
                       class="flex items-center gap-3 px-3 py-2 rounded-xl font-medium transition-colors {{ request()->routeIs('admin.bookings.*') ? 'bg-[#244C7C] text-white shadow-xs' : 'text-[#5A5146] hover:bg-[#F3EEE6] hover:text-[#1F1B16]' }}">
                        <svg class="w-4 h-4 opacity-80" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4"/></svg>
                        <span>Kontrak Kerja & Titip Gaji</span>
                    </a>

                    <a href="{{ route('admin.finances.index') }}" 
                       class="flex items-center gap-3 px-3 py-2 rounded-xl font-medium transition-colors {{ request()->routeIs('admin.finances.*') ? 'bg-[#244C7C] text-white shadow-xs' : 'text-[#5A5146] hover:bg-[#F3EEE6] hover:text-[#1F1B16]' }}">
                        <svg class="w-4 h-4 opacity-80" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                        <span>Keuangan & Bagi Hasil (10%)</span>
                    </a>
                </div>
            </div>

            <!-- Section 5: BANTUAN & PENGADUAN -->
            <div>
                <div class="px-3 pb-2 text-[10px] font-bold text-[#8C8070] uppercase tracking-wider">Bantuan & Pengaduan</div>
                <div class="space-y-0.5">
                    <a href="{{ route('admin.reports.index') }}" 
                       class="flex items-center justify-between px-3 py-2 rounded-xl font-medium transition-colors {{ request()->routeIs('admin.reports.*') ? 'bg-[#244C7C] text-white shadow-xs' : 'text-[#5A5146] hover:bg-[#F3EEE6] hover:text-[#1F1B16]' }}">
                        <div class="flex items-center gap-3">
                            <svg class="w-4 h-4 opacity-80" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/></svg>
                            <span>Laporan Keluhan & Mediasi</span>
                        </div>
                        @php $openReportsCount = \App\Models\Report::whereIn('status', ['submitted', 'under_review'])->count(); @endphp
                        @if($openReportsCount > 0)
                            <span class="px-1.5 py-0.5 rounded text-[10px] font-bold {{ request()->routeIs('admin.reports.*') ? 'bg-white/20 text-white' : 'bg-[#B3261E] text-white' }}">
                                {{ $openReportsCount }}
                            </span>
                        @endif
                    </a>
                </div>
            </div>

        </div>

        <!-- Sidebar Footer -->
        <div class="p-4 border-t border-[#E2D9CC] bg-[#FAF7F2]/60 text-xs text-[#5A5146] space-y-1 flex-shrink-0">
            <div class="flex items-center justify-between text-[11px]">
                <span class="font-medium text-[#1F1B16]">Pramu Platform</span>
                <span class="text-[#8C8070]">Indonesia</span>
            </div>
            <div class="flex items-center justify-between text-[11px] text-[#8C8070]">
                <span>Zona Waktu:</span>
                <span>WIB (UTC+7)</span>
            </div>
        </div>
    </aside>

    <!-- Main Content Wrapper: Full Viewport Height with ONE Smooth Scrolling Area -->
    <div class="flex-1 flex flex-col min-w-0 h-full overflow-hidden">
        <!-- Topbar: Fixed at top (flex-shrink-0) -->
        <header class="h-16 bg-white border-b border-[#E2D9CC] px-6 lg:px-8 flex items-center justify-between flex-shrink-0 z-10 shadow-2xs">
            <!-- Search Bar -->
            <div class="flex items-center gap-3 w-72 sm:w-96">
                <form method="GET" action="{{ route('admin.users.index') }}" class="relative w-full">
                    <svg class="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-[#8C8070]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/></svg>
                    <input id="topbar-search-input" type="text" name="search" placeholder="Cari nama, NIK, lowongan, atau nomor kontrak..." 
                           class="w-full text-xs pl-9 pr-14 py-2 bg-[#FAF7F2] rounded-xl border border-[#E2D9CC] focus:bg-white focus:border-[#244C7C] focus:ring-1 focus:ring-[#244C7C] outline-none transition-all">
                    <kbd class="absolute right-2.5 top-1/2 -translate-y-1/2 text-[10px] font-mono text-[#8C8070] bg-white px-1.5 py-0.5 rounded border border-[#E2D9CC] pointer-events-none">CTRL + /</kbd>
                </form>
            </div>

            <!-- Topbar Right Actions -->
            <div class="flex items-center gap-3 sm:gap-4">
                <!-- Date Indicator -->
                <div class="hidden md:flex items-center gap-2 text-xs text-[#5A5146] bg-[#FAF7F2] px-3 py-1.5 rounded-xl border border-[#E2D9CC]">
                    <svg class="w-3.5 h-3.5 text-[#8C8070]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>
                    <span>{{ now()->translatedFormat('d M Y') }} &bull; WIB</span>
                </div>

                <!-- Notification Indicator -->
                <div class="relative">
                    <a href="{{ route('admin.verifications.index') }}" 
                       class="p-2 text-[#5A5146] hover:text-[#1F1B16] hover:bg-[#F3EEE6] rounded-xl transition-colors block">
                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"/></svg>
                        @if($pendingVerifCount > 0 || $openReportsCount > 0)
                            <span class="w-2 h-2 rounded-full bg-[#B3261E] absolute top-2 right-2 ring-2 ring-white"></span>
                        @endif
                    </a>
                </div>

                <!-- User Profile -->
                <div class="flex items-center gap-2.5 pl-3 border-l border-[#E2D9CC]">
                    <div class="w-8 h-8 rounded-full bg-[#244C7C] text-white flex items-center justify-center font-bold text-xs shadow-2xs">
                        AP
                    </div>
                    <div class="hidden sm:block text-left text-xs leading-tight">
                        <div class="font-bold text-[#1F1B16]">Admin Pramu</div>
                        <div class="text-[11px] text-[#5A5146]">Pengelola Sistem</div>
                    </div>
                </div>
            </div>
        </header>

        <!-- Main Body: THE SINGLE SCROLLABLE CONTAINER (Smooth & Clean) -->
        <main class="flex-1 overflow-y-auto px-6 py-6 lg:px-10 lg:py-8">
            <div class="max-w-7xl mx-auto space-y-6">

                <!-- Flash Success Notification -->
                @if(session('success'))
                    <div class="p-4 bg-[#E3F2EA] border border-[#1B6E45]/20 text-[#1B6E45] rounded-xl text-xs flex items-center gap-3 shadow-2xs">
                        <svg class="w-4 h-4 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" /></svg>
                        <span class="font-medium">{{ session('success') }}</span>
                    </div>
                @endif

                <!-- Flash Errors Notification -->
                @if($errors->any())
                    <div class="p-4 bg-[#FBE5E3] border border-[#B3261E]/20 text-[#B3261E] rounded-xl text-xs shadow-2xs">
                        <ul class="list-disc pl-5 space-y-1">
                            @foreach($errors->all() as $error)
                                <li>{{ $error }}</li>
                            @endforeach
                        </ul>
                    </div>
                @endif

                <!-- View Content Injected Here -->
                @yield('content')

            </div>
        </main>
    </div>

    <!-- Keyboard Shortcut Listener for Quick Search -->
    <script>
        document.addEventListener('keydown', function(e) {
            if ((e.ctrlKey || e.metaKey) && e.key === '/') {
                e.preventDefault();
                const searchInput = document.getElementById('topbar-search-input');
                if (searchInput) {
                    searchInput.focus();
                    searchInput.select();
                }
            }
        });
    </script>
</body>
</html>

