<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Application;
use App\Models\Booking;
use App\Models\BookingPeriod;
use App\Models\Category;
use App\Models\Interview;
use App\Models\Listing;
use App\Models\Report;
use App\Models\Skck;
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
            'total_applications' => Application::count(),
            'shortlisted_applications' => Application::whereIn('status', ['shortlisted', 'interviewing'])->count(),
            'interview_count' => Interview::count(),
            'accepted_applications' => Application::where('status', 'accepted')->count(),
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
     * List all verification submissions with status and role filtering
     */
    public function verifications(Request $request): View
    {
        $status = $request->query('status', 'pending');
        $role = $request->query('role', 'all');
        $search = $request->query('search');

        $query = Verification::with(['user.assistantProfile']);

        if ($status !== 'all') {
            $query->where('status', $status);
        }

        if ($role !== 'all') {
            $query->whereHas('user', function ($q) use ($role) {
                $q->where('active_role', $role);
            });
        }

        if ($search) {
            $query->where(function ($q) use ($search) {
                $q->where('nik', 'like', "%{$search}%")
                    ->orWhereHas('user', function ($u) use ($search) {
                        $u->where('name', 'like', "%{$search}%")
                            ->orWhere('email', 'like', "%{$search}%")
                            ->orWhere('phone', 'like', "%{$search}%");
                    });
            });
        }

        $verifications = $query->latest()->paginate(15)->withQueryString();

        $roleCounts = [
            'all' => Verification::when($status !== 'all', fn ($q) => $q->where('status', $status))->count(),
            'assistant' => Verification::when($status !== 'all', fn ($q) => $q->where('status', $status))
                ->whereHas('user', fn ($q) => $q->where('active_role', 'assistant'))->count(),
            'seeker' => Verification::when($status !== 'all', fn ($q) => $q->where('status', $status))
                ->whereHas('user', fn ($q) => $q->where('active_role', 'seeker'))->count(),
        ];

        $statusCounts = [
            'pending' => Verification::when($role !== 'all', fn ($q) => $q->whereHas('user', fn ($u) => $u->where('active_role', $role)))->where('status', 'pending')->count(),
            'verified' => Verification::when($role !== 'all', fn ($q) => $q->whereHas('user', fn ($u) => $u->where('active_role', $role)))->where('status', 'verified')->count(),
            'rejected' => Verification::when($role !== 'all', fn ($q) => $q->whereHas('user', fn ($u) => $u->where('active_role', $role)))->where('status', 'rejected')->count(),
            'all' => Verification::when($role !== 'all', fn ($q) => $q->whereHas('user', fn ($u) => $u->where('active_role', $role)))->count(),
        ];

        return view('admin.verifications.index', compact('verifications', 'status', 'role', 'search', 'roleCounts', 'statusCounts'));
    }

    /**
     * Show single verification review screen
     */
    public function showVerification(string $id): View
    {
        $verification = Verification::with(['user.assistantProfile', 'user.skck'])->findOrFail($id);

        $verification->user->loadAvg('receivedReviews', 'rating')->loadCount('receivedReviews');

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
     * List Reports & Disputes with reporter role and status filtering
     */
    public function reports(Request $request): View
    {
        $role = $request->query('role', 'all');
        $status = $request->query('status', 'all');
        $search = $request->query('search');

        $query = Report::with(['reporter', 'reported', 'booking.listing.category']);

        if ($role !== 'all') {
            $query->whereHas('reporter', function ($q) use ($role) {
                $q->where('active_role', $role);
            });
        }

        if ($status !== 'all') {
            if ($status === 'open') {
                $query->whereIn('status', ['submitted', 'under_review']);
            } else {
                $query->where('status', $status);
            }
        }

        if ($search) {
            $query->where(function ($q) use ($search) {
                $q->where('description', 'like', "%{$search}%")
                    ->orWhere('category', 'like', "%{$search}%")
                    ->orWhere('id', 'like', "%{$search}%")
                    ->orWhereHas('reporter', function ($u) use ($search) {
                        $u->where('name', 'like', "%{$search}%")
                            ->orWhere('email', 'like', "%{$search}%")
                            ->orWhere('phone', 'like', "%{$search}%");
                    })
                    ->orWhereHas('reported', function ($u) use ($search) {
                        $u->where('name', 'like', "%{$search}%")
                            ->orWhere('email', 'like', "%{$search}%")
                            ->orWhere('phone', 'like', "%{$search}%");
                    });
            });
        }

        $reports = $query->latest()->paginate(15)->withQueryString();

        $roleCounts = [
            'all' => Report::when($status !== 'all', fn ($q) => $status === 'open' ? $q->whereIn('status', ['submitted', 'under_review']) : $q->where('status', $status))->count(),
            'assistant' => Report::when($status !== 'all', fn ($q) => $status === 'open' ? $q->whereIn('status', ['submitted', 'under_review']) : $q->where('status', $status))
                ->whereHas('reporter', fn ($q) => $q->where('active_role', 'assistant'))->count(),
            'seeker' => Report::when($status !== 'all', fn ($q) => $status === 'open' ? $q->whereIn('status', ['submitted', 'under_review']) : $q->where('status', $status))
                ->whereHas('reporter', fn ($q) => $q->where('active_role', 'seeker'))->count(),
        ];

        $statusCounts = [
            'all' => Report::when($role !== 'all', fn ($q) => $q->whereHas('reporter', fn ($u) => $u->where('active_role', $role)))->count(),
            'open' => Report::when($role !== 'all', fn ($q) => $q->whereHas('reporter', fn ($u) => $u->where('active_role', $role)))->whereIn('status', ['submitted', 'under_review'])->count(),
            'submitted' => Report::when($role !== 'all', fn ($q) => $q->whereHas('reporter', fn ($u) => $u->where('active_role', $role)))->where('status', 'submitted')->count(),
            'under_review' => Report::when($role !== 'all', fn ($q) => $q->whereHas('reporter', fn ($u) => $u->where('active_role', $role)))->where('status', 'under_review')->count(),
            'resolved' => Report::when($role !== 'all', fn ($q) => $q->whereHas('reporter', fn ($u) => $u->where('active_role', $role)))->where('status', 'resolved')->count(),
        ];

        return view('admin.reports.index', compact('reports', 'role', 'status', 'search', 'roleCounts', 'statusCounts'));
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

        $query = User::with(['verification', 'roles', 'assistantProfile', 'skck'])
            ->withAvg('receivedReviews', 'rating')
            ->withCount('receivedReviews');

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
     * Show detailed user profile (Seeker or Assistant)
     */
    public function showUser(string $id): View
    {
        $user = User::with([
            'assistantProfile',
            'verification',
            'skck',
            'receivedReviews.reviewer',
            'listings.category',
            'applications.listing.category',
        ])
            ->withAvg('receivedReviews', 'rating')
            ->withCount('receivedReviews')
            ->findOrFail($id);

        return view('admin.users.show', compact('user'));
    }

    /**
     * List all Job Listings (Semua, Tayang Aktif, Draf / Belum Bayar)
     */
    public function listings(Request $request): View
    {
        $status = $request->query('status', 'all');
        $search = $request->query('search');

        $query = Listing::with(['user', 'category'])->withCount('applications');

        if ($status !== 'all') {
            if ($status === 'draft') {
                $query->whereIn('status', ['draft', 'awaiting_payment']);
            } else {
                $query->where('status', $status);
            }
        }

        if ($search) {
            $query->where(function ($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                    ->orWhere('city_name', 'like', "%{$search}%")
                    ->orWhere('description', 'like', "%{$search}%")
                    ->orWhereHas('user', function ($u) use ($search) {
                        $u->where('name', 'like', "%{$search}%")
                            ->orWhere('email', 'like', "%{$search}%")
                            ->orWhere('phone', 'like', "%{$search}%");
                    })
                    ->orWhereHas('category', function ($c) use ($search) {
                        $c->where('name', 'like', "%{$search}%");
                    });
            });
        }

        $listings = $query->latest()->paginate(15)->withQueryString();
        $counts = [
            'all' => Listing::count(),
            'open' => Listing::where('status', 'open')->count(),
            'draft' => Listing::whereIn('status', ['draft', 'awaiting_payment'])->count(),
        ];

        return view('admin.listings.index', compact('listings', 'status', 'search', 'counts'));
    }

    /**
     * Show single job listing detail for review
     */
    public function showListing(string $id): View
    {
        $listing = Listing::with([
            'user.verification',
            'category',
            'applications.user.assistantProfile',
        ])
            ->withCount('applications')
            ->findOrFail($id);

        return view('admin.listings.show', compact('listing'));
    }

    /**
     * List all Scheduled Interviews
     */
    public function interviews(Request $request): View
    {
        $status = $request->query('status', 'all');

        $query = Interview::with(['application.user', 'application.listing.user', 'application.listing']);

        if ($status !== 'all') {
            $query->where('status', $status);
        }

        $interviews = $query->latest()->paginate(15)->withQueryString();

        $counts = [
            'all' => Interview::count(),
            'confirmed' => Interview::where('status', 'confirmed')->count(),
            'done' => Interview::where('status', 'done')->count(),
        ];

        return view('admin.interviews.index', compact('interviews', 'status', 'counts'));
    }

    /**
     * Update Interview schedule, meeting URL, or status (Admin)
     */
    public function updateInterview(Request $request, string $id): RedirectResponse
    {
        $interview = Interview::findOrFail($id);

        $validated = $request->validate([
            'meeting_url' => ['nullable', 'url', 'max:255'],
            'confirmed_slot' => ['nullable', 'date'],
            'status' => ['required', 'in:proposed,confirmed,done,cancelled'],
            'notes' => ['nullable', 'string', 'max:500'],
        ]);

        $interview->update([
            'meeting_url' => $validated['meeting_url'] ?? $interview->meeting_url,
            'confirmed_slot' => $validated['confirmed_slot'] ?? $interview->confirmed_slot,
            'status' => $validated['status'],
            'notes' => $validated['notes'] ?? $interview->notes,
        ]);

        return redirect()->back()
            ->with('success', 'Data sesi wawancara dan tautan pertemuan berhasil diperbarui.');
    }

    /**
     * Generate or refresh Google Meet URL for interview
     */
    public function generateInterviewMeet(string $id): RedirectResponse
    {
        $interview = Interview::findOrFail($id);
        $newUrl = Interview::generateMeetingUrl();

        $interview->update([
            'meeting_url' => $newUrl,
            'status' => $interview->status === 'proposed' ? 'confirmed' : $interview->status,
        ]);

        return redirect()->back()
            ->with('success', "Link Google Meet otomatis berhasil dibuat: {$newUrl}");
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

    /**
     * Approve user SKCK document
     */
    public function approveSkck(string $id): RedirectResponse
    {
        $skck = Skck::findOrFail($id);
        $skck->update([
            'status' => 'verified',
            'reviewed_at' => now(),
        ]);

        return redirect()->back()
            ->with('success', 'Dokumen SKCK berhasil diverifikasi sah.');
    }

    /**
     * Reject user SKCK document
     */
    public function rejectSkck(Request $request, string $id): RedirectResponse
    {
        $skck = Skck::findOrFail($id);
        $skck->update([
            'status' => 'rejected',
            'rejection_reason' => $request->input('reason', 'Dokumen SKCK tidak valid atau telah kedaluwarsa.'),
            'reviewed_at' => now(),
        ]);

        return redirect()->back()
            ->with('success', 'Dokumen SKCK telah ditolak.');
    }
}
