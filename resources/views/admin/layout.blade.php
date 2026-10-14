<!DOCTYPE html>
<html lang="id" class="h-full bg-[#052F4D]">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>@yield('title', 'Admin Dashboard') — Pramu Asisten Platform</title>
    <link rel="icon" type="image/png" href="{{ asset('images/logo.png') }}">
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <style>
        :root {
            --sidebar-bg: #082032;
            --sidebar-active: #143F66;
            --canvas-bg: #07446E;
            --accent-orange: #FF6B35;
            --accent-cyan: #0284C7;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
        }
        /* Custom sleek scrollbar for dashboard */
        ::-webkit-scrollbar {
            width: 6px;
            height: 6px;
        }
        ::-webkit-scrollbar-track {
            background: rgba(0, 0, 0, 0.05);
        }
        ::-webkit-scrollbar-thumb {
            background: rgba(255, 255, 255, 0.2);
            border-radius: 9999px;
        }
        ::-webkit-scrollbar-thumb:hover {
            background: rgba(255, 255, 255, 0.35);
        }
    </style>
</head>
<body class="h-full flex overflow-hidden antialiased text-slate-800">

    <!-- Mobile Overlay Backdrop -->
    <div id="sidebar-backdrop" onclick="toggleSidebar(false)" class="fixed inset-0 bg-[#041B2D]/70 z-30 hidden lg:hidden transition-opacity"></div>

    <!-- Left Sidebar: Deep Navy Modern SaaS Sidebar (Launchly Style) -->
    <aside id="admin-sidebar" class="fixed inset-y-0 left-0 z-40 w-64 bg-[#082032] border-r border-[#0D2D44] flex flex-col flex-shrink-0 h-full -translate-x-full lg:translate-x-0 lg:static transition-transform duration-200 ease-in-out text-slate-300">
        <!-- Logo & Header Brand -->
        <div class="h-16 px-5 border-b border-[#0D2D44] flex items-center justify-between flex-shrink-0 bg-[#082032]">
            <a href="{{ route('admin.dashboard') }}" class="flex items-center gap-3 group">
                <img src="{{ asset('images/logo.png') }}" alt="Pramu Logo" 
                     class="w-9 h-9 rounded-xl object-cover shadow-md shadow-black/20 group-hover:scale-105 transition-transform border border-white/10 shrink-0">
                <div>
                    <h1 class="text-base font-extrabold text-white tracking-tight leading-tight flex items-center gap-1">
                        Pramu<span class="text-[#FF6B35]">Admin</span>
                    </h1>
                    <p class="text-[10px] text-cyan-200/60 font-medium">Portal Operasional</p>
                </div>
            </a>
            <!-- Mobile Close Button -->
            <button type="button" onclick="toggleSidebar(false)" class="lg:hidden p-1.5 text-slate-400 hover:text-white rounded-lg">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
            </button>
        </div>

        <!-- Sidebar Navigation Sections (Scrollable) -->
        <div class="flex-1 overflow-y-auto px-3.5 py-4 space-y-4 text-xs">
            <!-- Nav Item 1: Beranda Utama -->
            <div>
                <a href="{{ route('admin.dashboard') }}" 
                   class="flex items-center gap-3 px-3.5 py-2.5 rounded-xl font-semibold transition-all {{ request()->routeIs('admin.dashboard') ? 'bg-[#143F66] text-white shadow-sm border border-cyan-400/20' : 'text-slate-300 hover:bg-white/5 hover:text-white' }}">
                    <svg class="w-4 h-4 {{ request()->routeIs('admin.dashboard') ? 'text-cyan-300' : 'text-slate-400' }}" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/></svg>
                    <span>Beranda Utama</span>
                </a>
            </div>

            <!-- Nav Item 2: Pemeriksaan KTP & Foto -->
            <div>
                <a href="{{ route('admin.verifications.index') }}" 
                   class="flex items-center justify-between px-3.5 py-2.5 rounded-xl font-semibold transition-all {{ request()->routeIs('admin.verifications.*') ? 'bg-[#143F66] text-white shadow-sm border border-cyan-400/20' : 'text-slate-300 hover:bg-white/5 hover:text-white' }}">
                    <div class="flex items-center gap-3">
                        <svg class="w-4 h-4 {{ request()->routeIs('admin.verifications.*') ? 'text-cyan-300' : 'text-slate-400' }}" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"/></svg>
                        <span>Pemeriksaan KTP & Foto</span>
                    </div>
                    @php $pendingVerifCount = \App\Models\Verification::where('status', 'pending')->count(); @endphp
                    @if($pendingVerifCount > 0)
                        <span class="px-2 py-0.5 rounded-full text-[10px] font-bold bg-[#FF6B35] text-white shadow-sm">
                            {{ $pendingVerifCount }}
                        </span>
                    @endif
                </a>
            </div>

            <!-- Nav Item 3: Daftar Majikan & Asisten -->
            <div>
                <a href="{{ route('admin.users.index') }}" 
                   class="flex items-center gap-3 px-3.5 py-2.5 rounded-xl font-semibold transition-all {{ request()->routeIs('admin.users.*') ? 'bg-[#143F66] text-white shadow-sm border border-cyan-400/20' : 'text-slate-300 hover:bg-white/5 hover:text-white' }}">
                    <svg class="w-4 h-4 {{ request()->routeIs('admin.users.*') ? 'text-cyan-300' : 'text-slate-400' }}" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"/></svg>
                    <span>Daftar Majikan & Asisten</span>
                </a>
            </div>

            <!-- Nav Item 4: Lowongan Kerja Aktif -->
            <div>
                <a href="{{ route('admin.listings.index') }}" 
                   class="flex items-center gap-3 px-3.5 py-2.5 rounded-xl font-semibold transition-all {{ request()->routeIs('admin.listings.*') ? 'bg-[#143F66] text-white shadow-sm border border-cyan-400/20' : 'text-slate-300 hover:bg-white/5 hover:text-white' }}">
                    <svg class="w-4 h-4 {{ request()->routeIs('admin.listings.*') ? 'text-cyan-300' : 'text-slate-400' }}" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"/></svg>
                    <span>Lowongan Kerja Aktif</span>
                </a>
            </div>

            <!-- Nav Item 5: Jadwal Wawancara Online -->
            <div>
                <a href="{{ route('admin.interviews.index') }}" 
                   class="flex items-center gap-3 px-3.5 py-2.5 rounded-xl font-semibold transition-all {{ request()->routeIs('admin.interviews.*') ? 'bg-[#143F66] text-white shadow-sm border border-cyan-400/20' : 'text-slate-300 hover:bg-white/5 hover:text-white' }}">
                    <svg class="w-4 h-4 {{ request()->routeIs('admin.interviews.*') ? 'text-cyan-300' : 'text-slate-400' }}" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"/></svg>
                    <span>Jadwal Wawancara Online</span>
                </a>
            </div>

            <!-- Nav Item 6: Daftar Kontrak Kerja -->
            <div>
                <a href="{{ route('admin.bookings.index') }}" 
                   class="flex items-center gap-3 px-3.5 py-2.5 rounded-xl font-semibold transition-all {{ request()->routeIs('admin.bookings.*') ? 'bg-[#143F66] text-white shadow-sm border border-cyan-400/20' : 'text-slate-300 hover:bg-white/5 hover:text-white' }}">
                    <svg class="w-4 h-4 {{ request()->routeIs('admin.bookings.*') ? 'text-cyan-300' : 'text-slate-400' }}" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4"/></svg>
                    <span>Daftar Kontrak Kerja</span>
                </a>
            </div>

            <!-- Nav Item 7: Keuangan & Bagi Hasil (10%) -->
            <div>
                <a href="{{ route('admin.finances.index') }}" 
                   class="flex items-center gap-3 px-3.5 py-2.5 rounded-xl font-semibold transition-all {{ request()->routeIs('admin.finances.*') ? 'bg-[#143F66] text-white shadow-sm border border-cyan-400/20' : 'text-slate-300 hover:bg-white/5 hover:text-white' }}">
                    <svg class="w-4 h-4 {{ request()->routeIs('admin.finances.*') ? 'text-cyan-300' : 'text-slate-400' }}" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                    <span>Keuangan & Bagi Hasil (10%)</span>
                </a>
            </div>

            <!-- Nav Item 8: Laporan Keluhan & Mediasi -->
            <div>
                <a href="{{ route('admin.reports.index') }}" 
                   class="flex items-center justify-between px-3.5 py-2.5 rounded-xl font-semibold transition-all {{ request()->routeIs('admin.reports.*') ? 'bg-[#143F66] text-white shadow-sm border border-cyan-400/20' : 'text-slate-300 hover:bg-white/5 hover:text-white' }}">
                    <div class="flex items-center gap-3">
                        <svg class="w-4 h-4 {{ request()->routeIs('admin.reports.*') ? 'text-cyan-300' : 'text-slate-400' }}" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/></svg>
                        <span>Laporan Keluhan & Mediasi</span>
                    </div>
                    @php $openReportsCount = \App\Models\Report::whereIn('status', ['submitted', 'under_review'])->count(); @endphp
                    @if($openReportsCount > 0)
                        <span class="px-2 py-0.5 rounded-full text-[10px] font-bold bg-[#EF4444] text-white shadow-sm">
                            {{ $openReportsCount }}
                        </span>
                    @endif
                </a>
            </div>
        </div>

        <!-- Sidebar Footer: Workspace / Admin Profile Card (Launchly Style) -->
        <div class="p-3 border-t border-[#0D2D44] bg-[#061B2B] flex-shrink-0">
            <div class="bg-[#082032] border border-white/5 rounded-xl p-2.5 flex items-center justify-between">
                <div class="flex items-center gap-2.5">
                    <img src="{{ asset('images/logo.png') }}" alt="Admin Pramu" class="w-7 h-7 rounded-lg object-cover border border-white/10 shadow-xs shrink-0">
                    <div class="text-left text-xs leading-tight">
                        <div class="font-bold text-white">Admin Pramu</div>
                        <div class="text-[10px] text-cyan-200/60">Superadmin</div>
                    </div>
                </div>
                <svg class="w-4 h-4 text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>
            </div>
        </div>
    </aside>

    <!-- Main Content Wrapper: Full Viewport with Lush Ocean Blue Backdrop -->
    <div class="flex-1 flex flex-col min-w-0 h-full overflow-hidden" style="background: radial-gradient(circle at top right, #0C5D8F 0%, #08436B 45%, #052F4D 100%);">
        <!-- Topbar: Dark Translucent Glass Navigation Bar -->
        <header class="h-16 bg-[#082032]/80 backdrop-blur-md border-b border-white/10 px-4 sm:px-6 lg:px-8 flex items-center justify-between flex-shrink-0 z-10 text-white">
            <!-- Left: Mobile Toggle & Search Bar -->
            <div class="flex items-center gap-3 w-auto sm:w-96">
                <!-- Mobile Menu Button -->
                <button type="button" onclick="toggleSidebar(true)" class="lg:hidden p-2 text-cyan-200 hover:text-white hover:bg-white/10 rounded-xl transition-colors">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"/></svg>
                </button>

                <!-- Mobile Brand Logo -->
                <a href="{{ route('admin.dashboard') }}" class="lg:hidden flex items-center gap-2 shrink-0">
                    <img src="{{ asset('images/logo.png') }}" alt="Pramu" class="w-7 h-7 rounded-lg object-cover border border-white/10 shadow-xs">
                </a>

                <!-- Search Input Pill (Launchly Style) -->
                <form method="GET" action="{{ route('admin.users.index') }}" class="relative w-48 sm:w-full">
                    <svg class="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-cyan-200/60" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/></svg>
                    <input id="topbar-search-input" type="text" name="search" placeholder="Cari nama, NIK, lowongan..." 
                           class="w-full text-xs pl-9 pr-14 py-2 bg-[#051F33]/70 rounded-xl border border-white/10 text-white placeholder-cyan-200/40 focus:bg-[#072B47] focus:border-cyan-400 focus:ring-1 focus:ring-cyan-400 outline-none transition-all">
                    <kbd class="hidden sm:inline-block absolute right-2.5 top-1/2 -translate-y-1/2 text-[10px] font-mono text-cyan-200/60 bg-white/5 px-1.5 py-0.5 rounded border border-white/10 pointer-events-none">CTRL + /</kbd>
                </form>
            </div>

            <!-- Topbar Right Controls (Date pill, Bell, Avatar, Orange CTA button) -->
            <div class="flex items-center gap-2 sm:gap-3">
                <!-- Date Filter Pill (Launchly Style) -->
                <div class="hidden md:flex items-center gap-2 text-xs text-cyan-100 bg-white/10 hover:bg-white/15 px-3 py-1.5 rounded-xl border border-white/10 transition-colors">
                    <svg class="w-3.5 h-3.5 text-cyan-300" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>
                    <span>{{ now()->translatedFormat('d M Y') }}</span>
                    <span class="text-cyan-300 text-[10px]">&bull; WIB</span>
                </div>

                <!-- Notification Bell Pill -->
                <div class="relative">
                    <a href="{{ route('admin.verifications.index') }}" 
                       class="p-2 text-cyan-200 hover:text-white bg-white/5 hover:bg-white/10 border border-white/10 rounded-xl transition-colors block">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"/></svg>
                        @if($pendingVerifCount > 0 || $openReportsCount > 0)
                            <span class="w-2 h-2 rounded-full bg-[#FF6B35] absolute top-1.5 right-1.5 ring-2 ring-[#082032]"></span>
                        @endif
                    </a>
                </div>

                <!-- Admin Avatar Pill with Logo -->
                <div class="w-8 h-8 rounded-xl overflow-hidden shadow-sm border border-white/20 shrink-0">
                    <img src="{{ asset('images/logo.png') }}" alt="Admin" class="w-full h-full object-cover">
                </div>

                <!-- Launchly Orange Primary CTA Button -->
                <a href="{{ route('admin.verifications.index') }}" 
                   class="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-[#FF6B35] hover:bg-[#E85926] text-white text-xs font-bold shadow-md shadow-[#FF6B35]/30 transition-all">
                    <span>+</span>
                    <span class="hidden sm:inline">Periksa KTP</span>
                </a>
            </div>
        </header>

        <!-- Main Body Scroll Container -->
        <main class="flex-1 overflow-y-auto px-4 py-5 sm:px-6 sm:py-6 lg:px-8 lg:py-8">
            <div class="max-w-7xl mx-auto space-y-6">

                <!-- Flash Success Notification -->
                @if(session('success'))
                    <div class="p-4 bg-emerald-500/20 border border-emerald-400/40 text-emerald-100 rounded-2xl text-xs flex items-center gap-3 shadow-md backdrop-blur-sm">
                        <div class="w-6 h-6 rounded-lg bg-emerald-500 text-white flex items-center justify-center font-bold text-xs shrink-0">
                            &check;
                        </div>
                        <span class="font-semibold">{{ session('success') }}</span>
                    </div>
                @endif

                <!-- Flash Errors Notification -->
                @if($errors->any())
                    <div class="p-4 bg-rose-500/20 border border-rose-400/40 text-rose-100 rounded-2xl text-xs shadow-md backdrop-blur-sm">
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

    <!-- Mobile Sidebar Toggle & Keyboard Shortcut Listener -->
    <script>
        function toggleSidebar(open) {
            const sidebar = document.getElementById('admin-sidebar');
            const backdrop = document.getElementById('sidebar-backdrop');
            if (!sidebar || !backdrop) return;

            if (open) {
                sidebar.classList.remove('-translate-x-full');
                backdrop.classList.remove('hidden');
            } else {
                sidebar.classList.add('-translate-x-full');
                backdrop.classList.add('hidden');
            }
        }

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