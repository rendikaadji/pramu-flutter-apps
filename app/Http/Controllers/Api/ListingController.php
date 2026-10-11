<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Concerns\ApiResponse;
use App\Http\Controllers\Controller;
use App\Models\Listing;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class ListingController extends Controller
{
    use ApiResponse;

    /**
     * Browse open listings with filters and pagination
     */
    public function index(Request $request): JsonResponse
    {
        $query = Listing::with(['category', 'user:id,name,avatar_url,is_verified'])
            ->where('status', 'open');

        if ($request->filled('category_id')) {
            $query->where('category_id', $request->category_id);
        }

        if ($request->filled('city_id')) {
            $query->where('city_id', $request->city_id);
        }

        if ($request->filled('period_type')) {
            $query->where('period_type', $request->period_type);
        }

        if ($request->filled('budget_max')) {
            $query->where('budget_min', '<=', (int)$request->budget_max);
        }

        if ($request->filled('search')) {
            $query->where('title', 'like', "%{$request->search}%");
        }

        $perPage = min((int)($request->per_page ?? 15), 50);
        $listings = $query->latest()->paginate($perPage);

        return $this->successResponse(
            $listings->items(),
            [
                'current_page' => $listings->currentPage(),
                'last_page' => $listings->lastPage(),
                'per_page' => $listings->perPage(),
                'total' => $listings->total(),
            ]
        );
    }

    /**
     * Show single listing details
     */
    public function show(string $id): JsonResponse
    {
        $listing = Listing::with(['category', 'user:id,name,avatar_url,is_verified'])
            ->find($id);

        if (!$listing) {
            return $this->errorResponse('LISTING_NOT_FOUND', 'Lowongan tidak ditemukan.', null, 404);
        }

        return $this->successResponse($listing);
    }

    /**
     * Create listing draft (Requires verified Seeker)
     */
    public function store(Request $request): JsonResponse
    {
        $user = $request->user();

        if (!$user->is_verified) {
            return $this->errorResponse(
                'VERIFICATION_REQUIRED',
                'Anda harus menyelesaikan verifikasi KTP terlebih dahulu untuk memasang lowongan.',
                null,
                403
            );
        }

        $validated = $request->validate([
            'category_id' => ['required', 'string', 'exists:categories,id'],
            'title' => ['required', 'string', 'max:255'],
            'description' => ['required', 'string'],
            'city_id' => ['nullable', 'string'],
            'city_name' => ['nullable', 'string'],
            'period_type' => ['required', 'string', 'in:hourly,daily,weekly,monthly'],
            'period_count' => ['required', 'integer', 'min:1'],
            'billing_cycle' => ['required', 'string', 'in:weekly,biweekly,monthly'],
            'start_date' => ['required', 'date', 'after_or_equal:today'],
            'budget_min' => ['required', 'integer', 'min:10000'],
            'budget_max' => ['required', 'integer', 'gte:budget_min'],
            'require_skck' => ['boolean'],
            'screening_questions' => ['nullable', 'array', 'max:5'],
        ]);

        $listing = $user->listings()->create([
            ...$validated,
            'status' => 'draft',
        ]);

        return $this->successResponse($listing, null, 201);
    }

    /**
     * Pay listing publishing fee (Rp25.000)
     */
    public function pay(Request $request, string $id): JsonResponse
    {
        $listing = $request->user()->listings()->find($id);

        if (!$listing) {
            return $this->errorResponse('LISTING_NOT_FOUND', 'Lowongan tidak ditemukan.', null, 404);
        }

        if ($listing->status === 'open') {
            return $this->errorResponse('ALREADY_ACTIVE', 'Lowongan ini sudah aktif.', null, 400);
        }

        $feeAmount = 25000; // Rp25.000 pasang lowongan (PRD §5.4, LST-2)
        $externalId = "listing_fee_{$listing->id}_" . Str::random(6);

        // Simulation or integration URL
        $invoiceUrl = "https://checkout-staging.xendit.co/web/{$externalId}";

        $listing->update([
            'status' => 'awaiting_payment',
            'listing_fee_invoice_id' => $externalId,
            'listing_fee_invoice_url' => $invoiceUrl,
        ]);

        return $this->successResponse([
            'listing_id' => $listing->id,
            'amount' => $feeAmount,
            'invoice_url' => $invoiceUrl,
            'external_id' => $externalId,
            'status' => $listing->status,
        ]);
    }

    /**
     * List current user's listings
     */
    public function myListings(Request $request): JsonResponse
    {
        $listings = $request->user()->listings()
            ->with(['category'])
            ->withCount('applications')
            ->latest()
            ->paginate(20);

        return $this->successResponse($listings->items(), [
            'current_page' => $listings->currentPage(),
            'total' => $listings->total(),
        ]);
    }

    /**
     * Close a listing
     */
    public function close(Request $request, string $id): JsonResponse
    {
        $listing = $request->user()->listings()->find($id);

        if (!$listing) {
            return $this->errorResponse('LISTING_NOT_FOUND', 'Lowongan tidak ditemukan.', null, 404);
        }

        $listing->update(['status' => 'closed']);

        return $this->successResponse([
            'message' => 'Lowongan berhasil ditutup.',
            'status' => $listing->status,
        ]);
    }
}

