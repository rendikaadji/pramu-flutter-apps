<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>@yield('title', 'Admin Panel') — Pramu Asisten Marketplace</title>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <style>
        :root {
            --bg-canvas: #FAF7F2;
            --bg-surface: #FFFFFF;
            --border-subtle: #E2D9CC;
            --border-strong: #8C8070;
            --text-primary: #1F1B16;
            --text-muted: #5A5146;
            --primary: #244C7C;
            --accent: #9A4E1C;
            --success: #1B6E45;
            --danger: #B3261E;
        }
        body {
            background-color: var(--bg-canvas);
            color: var(--text-primary);
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
        }
    </style>
</head>
<body class="min-h-screen flex flex-col md:flex-row antialiased">
    <!-- Sidebar -->
    <aside class="w-full md:w-64 bg-white border-r border-[#E2D9CC] flex flex-col flex-shrink-0">
        <!-- Brand -->
        <div class="p-6 border-b border-[#E2D9CC] flex items-center gap-3">
            <div class="w-10 h-10 rounded-lg bg-[#244C7C] flex items-center justify-center text-white font-bold text-lg">
                P
            </div>
            <div>
                <h1 class="text-base font-bold text-[#1F1B16] leading-tight">Pramu Backend</h1>
                <p class="text-xs text-[#5A5146]">Panel Moderasi & Escrow</p>
            </div>
        </div>

        <!-- Navigation Links -->
        <nav class="flex-1 p-4 space-y-1">
            <a href="{{ route('admin.dashboard') }}" 
               class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors {{ request()->routeIs('admin.dashboard') ? 'bg-[#244C7C] text-white' : 'text-[#5A5146] hover:bg-[#F3EEE6] hover:text-[#1F1B16]' }}">
                <svg class="w-5 h-5 opacity-80" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/></svg>
                <span>Ringkasan</span>
            </a>

            <a href="{{ route('admin.verifications.index') }}" 
               class="flex items-center justify-between px-3 py-2.5 rounded-lg text-sm font-medium transition-colors {{ request()->routeIs('admin.verifications.*') ? 'bg-[#244C7C] text-white' : 'text-[#5A5146] hover:bg-[#F3EEE6] hover:text-[#1F1B16]' }}">
                <div class="flex items-center gap-3">
                    <svg class="w-5 h-5 opacity-80" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"/></svg>
                    <span>Verifikasi KTP</span>
                </div>
                @php $pendingCount = \App\Models\Verification::where('status', 'pending')->count(); @endphp
                @if($pendingCount > 0)
                    <span class="text-xs px-2 py-0.5 rounded-full {{ request()->routeIs('admin.verifications.*') ? 'bg-white/20 text-white' : 'bg-[#9A4E1C] text-white' }}">
                        {{ $pendingCount }}
                    </span>
                @endif
            </a>

            <a href="{{ route('admin.bookings.index') }}" 
               class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors {{ request()->routeIs('admin.bookings.*') ? 'bg-[#244C7C] text-white' : 'text-[#5A5146] hover:bg-[#F3EEE6] hover:text-[#1F1B16]' }}">
                <svg class="w-5 h-5 opacity-80" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4"/></svg>
                <span>Kontrak & Escrow</span>
            </a>

            <a href="{{ route('admin.reports.index') }}" 
               class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors {{ request()->routeIs('admin.reports.*') ? 'bg-[#244C7C] text-white' : 'text-[#5A5146] hover:bg-[#F3EEE6] hover:text-[#1F1B16]' }}">
                <svg class="w-5 h-5 opacity-80" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/></svg>
                <span>Laporan & Sengketa</span>
            </a>

            <div class="pt-4 mt-4 border-t border-[#E2D9CC]">
                <a href="/api/v1/listings" target="_blank"
                   class="flex items-center gap-3 px-3 py-2 text-xs text-[#5A5146] hover:text-[#1F1B16] rounded transition-colors">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4"/></svg>
                    <span>Cek Endpoint API v1 &rarr;</span>
                </a>
            </div>
        </nav>

        <!-- Environment Info -->
        <div class="p-4 border-t border-[#E2D9CC] text-xs text-[#5A5146]">
            <div>Mode: <span class="font-medium text-[#1B6E45]">Lokal (Herd)</span></div>
            <div>Database: <span class="font-medium">SQLite</span></div>
        </div>
    </aside>

    <!-- Main Content -->
    <main class="flex-1 flex flex-col min-w-0">
        <!-- Topbar -->
        <header class="bg-white border-b border-[#E2D9CC] px-6 py-4 flex items-center justify-between">
            <h2 class="text-lg font-semibold text-[#1F1B16]">@yield('header', 'Dashboard')</h2>
            <div class="flex items-center gap-4 text-sm text-[#5A5146]">
                <span>Petugas: <strong class="text-[#1F1B16]">Admin Pramu</strong></span>
            </div>
        </header>

        <!-- Flash Message -->
        @if(session('success'))
            <div class="mx-6 mt-6 p-4 bg-[#E3F2EA] border border-[#1B6E45]/20 text-[#1B6E45] rounded-lg text-sm flex items-center gap-3">
                <svg class="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
                <span>{{ session('success') }}</span>
            </div>
        @endif

        @if($errors->any())
            <div class="mx-6 mt-6 p-4 bg-[#FBE5E3] border border-[#B3261E]/20 text-[#B3261E] rounded-lg text-sm">
                <ul class="list-disc pl-5 space-y-1">
                    @foreach($errors->all() as $error)
                        <li>{{ $error }}</li>
                    @endforeach
                </ul>
            </div>
        @endif

        <!-- View Body -->
        <div class="p-6 flex-1">
            @yield('content')
        </div>
    </main>
</body>
</html>
