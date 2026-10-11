<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Booking;
use App\Models\BookingPeriod;
use App\Models\Listing;
use App\Models\Report;
use App\Models\User;
use App\Models\Verification;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class AdminController extends Controller
{
    /**
     * Admin Dashboard Overview
     */
    public function dashboard(): View
    {
        $stats = [
            'total_users' => User::count(),
            'pending_verifications' => Verification::where('status', 'pending')->count(),
            'open_listings' => Listing::where('status', 'open')->count(),
            'active_bookings' => Booking::where('status', 'active')->count(),
            'escrow_held' => BookingPeriod::whereIn('status', ['paid', 'in_progress', 'awaiting_confirmation'])->sum('amount'),
            'open_disputes' => Report::whereIn('status', ['submitted', 'under_review'])->count(),
        ];

        $recentVerifications = Verification::with('user')
            ->where('status', 'pending')
            ->latest()
            ->take(5)
            ->get();

        $recentBookings = Booking::with(['seeker', 'assistant', 'listing'])
            ->latest()
            ->take(5)
            ->get();

        return view('admin.dashboard', compact('stats', 'recentVerifications', 'recentBookings'));
    }

    /**
     * List all verification submissions
     */
    public function verifications(Request $request): View
    {
        $status = $request->query('status', 'pending');

        $query = Verification::with('user');
        if ($status !== 'all') {
            $query->where('status', $status);
        }

        $verifications = $query->latest()->paginate(15);

        return view('admin.verifications.index', compact('verifications', 'status'));
    }

    /**
     * Show single verification review screen
     */
    public function showVerification(string $id): View
    {
        $verification = Verification::with('user.assistantProfile')->findOrFail($id);

        return view('admin.verifications.show', compact('verification'));
    }

    /**
     * Approve user verification
     */
    public function approveVerification(Request $request, string $id): RedirectResponse
    {
        $verification = Verification::findOrFail($id);
        $verification->update([
            'status' => 'verified',
            'reviewed_at' => now(),
            'reviewed_by' => $request->user()?->id,
            'rejection_reason' => null,
        ]);

        $verification->user->update(['is_verified' => true]);

        return redirect()->route('admin.verifications.index')
            ->with('success', "Verifikasi pengguna {$verification->user->name} berhasil disetujui.");
    }

    /**
     * Reject user verification with reason
     */
    public function rejectVerification(Request $request, string $id): RedirectResponse
    {
        $request->validate([
            'rejection_reason' => ['required', 'string', 'max:500'],
        ]);

        $verification = Verification::findOrFail($id);
        $verification->update([
            'status' => 'rejected',
            'reviewed_at' => now(),
            'reviewed_by' => $request->user()?->id,
            'rejection_reason' => $request->input('rejection_reason'),
        ]);

        $verification->user->update(['is_verified' => false]);

        return redirect()->route('admin.verifications.index')
            ->with('success', "Verifikasi pengguna {$verification->user->name} telah ditolak dengan alasan yang tercatat.");
    }

    /**
     * List Escrow Bookings & Contracts
     */
    public function bookings(): View
    {
        $bookings = Booking::with(['seeker', 'assistant', 'periods', 'listing'])
            ->latest()
            ->paginate(15);

        return view('admin.bookings.index', compact('bookings'));
    }

    /**
     * List Reports & Disputes
     */
    public function reports(): View
    {
        $reports = Report::with(['reporter', 'reported', 'booking'])
            ->latest()
            ->paginate(15);

        return view('admin.reports.index', compact('reports'));
    }

    /**
     * Resolve a Report / Dispute
     */
    public function resolveReport(Request $request, string $id): RedirectResponse
    {
        $request->validate([
            'decision' => ['required', 'string'],
        ]);

        $report = Report::findOrFail($id);
        $report->update([
            'status' => 'resolved',
            'decision' => $request->input('decision'),
        ]);

        return redirect()->route('admin.reports.index')
            ->with('success', "Laporan #{$report->id} berhasil diselesaikan.");
    }
}
