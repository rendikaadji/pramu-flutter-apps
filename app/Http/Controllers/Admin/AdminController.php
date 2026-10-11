<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Booking;
use App\Models\BookingPeriod;
use App\Models\Category;
use App\Models\Interview;
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
     * Admin Dashboard Overview matching the enterprise reference layout
     */
    public function dashboard(): View
    {
        // 1. User metrics
        $totalUsers = User::count();
        $totalSeekers = User::where('active_role', 'seeker')->count();
        $totalAssistants = User::where('active_role', 'assistant')->count();
        $pendingVerificationsCount = Verification::where('status', 'pending')->count();
        $verifiedUsersCount = User::where('is_verified', true)->count();

        // 2. Financial / Escrow metrics
        $escrowHeld = BookingPeriod::whereIn('status', ['paid', 'in_progress', 'awaiting_confirmation'])->sum('amount');
        $escrowSettled = BookingPeriod::where('status', 'settled')->sum('total_payout');
        $platformFees = BookingPeriod::where('status', 'settled')->sum('seeker_fee') 
                      + BookingPeriod::where('status', 'settled')->sum('assistant_fee');
        $listingFees = Listing::whereNotNull('paid_at')->count() * 25000;

        // 3. Operational queues
        $pendingVerifications = Verification::with(['user.assistantProfile'])
            ->where('status', 'pending')
            ->latest()
            ->take(5)
            ->get();

        $upcomingInterviews = Interview::with(['application.user', 'application.listing.user', 'application.listing'])
            ->whereIn('status', ['proposed', 'confirmed'])
            ->latest()
            ->take(4)
            ->get();

        $activeBookings = Booking::with(['seeker', 'assistant', 'periods', 'listing.category'])
            ->latest()
            ->take(6)
            ->get();

        $recentReports = Report::with(['reporter', 'reported', 'booking'])
            ->latest()
            ->take(4)
            ->get();

        $recentUsers = User::with('verification')
            ->latest()
            ->take(5)
            ->get();

        $categories = Category::withCount('listings')->get();

        $stats = [
            'total_users' => $totalUsers,
            'total_seekers' => $totalSeekers,
            'total_assistants' => $totalAssistants,
            'pending_verifications' => $pendingVerificationsCount,
            'verified_users' => $verifiedUsersCount,
            'escrow_held' => $escrowHeld,
            'escrow_settled' => $escrowSettled,
            'platform_fees' => $platformFees,
            'listing_fees' => $listingFees,
            'open_listings' => Listing::where('status', 'open')->count(),
            'active_bookings' => Booking::where('status', 'active')->count(),
            'open_disputes' => Report::whereIn('status', ['submitted', 'under_review'])->count(),
            'total_applications' => \App\Models\Application::count(),
            'shortlisted_applications' => \App\Models\Application::whereIn('status', ['shortlisted', 'interviewing'])->count(),
            'interview_count' => Interview::count(),
            'accepted_applications' => \App\Models\Application::where('status', 'accepted')->count(),
        ];

        return view('admin.dashboard', compact(
            'stats',
            'pendingVerifications',
            'upcomingInterviews',
            'activeBookings',
            'recentReports',
            'recentUsers',
            'categories'
        ));
    }

    /**
     * List all verification submissions
     */
    public function verifications(Request $request): View
    {
        $status = $request->query('status', 'pending');

        $query = Verification::with(['user.assistantProfile']);
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

        return redirect()->back()
            ->with('success', "Verifikasi identitas {$verification->user->name} (NIK {$verification->nik}) berhasil disetujui.");
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

        return redirect()->back()
            ->with('success', "Verifikasi identitas {$verification->user->name} telah ditolak dengan alasan yang tercatat.");
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
            ->with('success', "Laporan sengketa #{$report->id} berhasil diselesaikan.");
    }

    /**
     * List all Users (Seekers & Assistants)
     */
    public function users(Request $request): View
    {
        $role = $request->query('role', 'all');
        $search = $request->query('search');

        $query = User::with(['verification', 'roles', 'assistantProfile']);

        if ($role !== 'all') {
            $query->where('active_role', $role);
        }

        if ($search) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%")
                  ->orWhere('phone', 'like', "%{$search}%");
            });
        }

        $users = $query->latest()->paginate(15)->withQueryString();
        $counts = [
            'all' => User::count(),
            'seeker' => User::where('active_role', 'seeker')->count(),
            'assistant' => User::where('active_role', 'assistant')->count(),
        ];

        return view('admin.users.index', compact('users', 'role', 'search', 'counts'));
    }

    /**
     * List all Job Listings
     */
    public function listings(Request $request): View
    {
        $status = $request->query('status', 'all');
        $search = $request->query('search');

        $query = Listing::with(['user', 'category'])->withCount('applications');

        if ($status !== 'all') {
            $query->where('status', $status);
        }

        if ($search) {
            $query->where(function ($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                  ->orWhere('city', 'like', "%{$search}%")
                  ->orWhere('district', 'like', "%{$search}%");
            });
        }

        $listings = $query->latest()->paginate(15)->withQueryString();
        $counts = [
            'all' => Listing::count(),
            'open' => Listing::where('status', 'open')->count(),
            'closed' => Listing::where('status', 'closed')->count(),
        ];

        return view('admin.listings.index', compact('listings', 'status', 'search', 'counts'));
    }

    /**
     * List all Scheduled Interviews (Google Meet)
     */
    public function interviews(Request $request): View
    {
        $status = $request->query('status', 'all');

        $query = Interview::with(['application.user', 'application.listing.user', 'application.listing']);

        if ($status !== 'all') {
            $query->where('status', $status);
        }

        $interviews = $query->latest()->paginate(15)->withQueryString();

        return view('admin.interviews.index', compact('interviews', 'status'));
    }

    /**
     * Financial & Platform Revenue Overview
     */
    public function finances(): View
    {
        $escrowHeld = BookingPeriod::whereIn('status', ['paid', 'in_progress', 'awaiting_confirmation'])->sum('amount');
        $escrowSettled = BookingPeriod::where('status', 'settled')->sum('total_payout');
        $platformFees = BookingPeriod::where('status', 'settled')->sum('seeker_fee') 
                      + BookingPeriod::where('status', 'settled')->sum('assistant_fee');
        $listingFees = Listing::whereNotNull('paid_at')->count() * 25000;

        $recentPeriods = BookingPeriod::with(['booking.seeker', 'booking.assistant'])
            ->latest()
            ->paginate(15);

        return view('admin.finances.index', compact('escrowHeld', 'escrowSettled', 'platformFees', 'listingFees', 'recentPeriods'));
    }
}

