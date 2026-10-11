<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Concerns\ApiResponse;
use App\Http\Controllers\Controller;
use App\Models\Application;
use App\Models\Listing;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ApplicationController extends Controller
{
    use ApiResponse;

    /**
     * Submit an application (Assistant)
     */
    public function store(Request $request, string $listingId): JsonResponse
    {
        $user = $request->user();

        if (!$user->is_verified) {
            return $this->errorResponse('VERIFICATION_REQUIRED', 'Anda harus terverifikasi untuk melamar lowongan.', null, 403);
        }

        $listing = Listing::find($listingId);
        if (!$listing || $listing->status !== 'open') {
            return $this->errorResponse('LISTING_UNAVAILABLE', 'Lowongan ini sudah tidak menerima lamaran.', null, 400);
        }

        // Check SKCK requirement
        if ($listing->require_skck) {
            $hasVerifiedSkck = $user->skck && $user->skck->status === 'verified';
            if (!$hasVerifiedSkck) {
                return $this->errorResponse(
                    'SKCK_REQUIRED',
                    'Lowongan ini mewajibkan SKCK yang sudah terverifikasi.',
                    null,
                    403
                );
            }
        }

        // Prevent duplicate application
        $exists = Application::where('listing_id', $listingId)
            ->where('user_id', $user->id)
            ->exists();

        if ($exists) {
            return $this->errorResponse('ALREADY_APPLIED', 'Anda sudah melamar pada lowongan ini.', null, 409);
        }

        $validated = $request->validate([
            'message' => ['nullable', 'string'],
            'proposed_rate' => ['required', 'integer', 'min:10000'],
            'answers' => ['nullable', 'array'],
        ]);

        $application = Application::create([
            'listing_id' => $listing->id,
            'user_id' => $user->id,
            'message' => $validated['message'] ?? null,
            'proposed_rate' => $validated['proposed_rate'],
            'answers' => $validated['answers'] ?? null,
            'status' => 'pending',
        ]);

        return $this->successResponse($application, null, 201);
    }

    /**
     * List applicants for a listing (Seeker)
     */
    public function listingApplications(Request $request, string $listingId): JsonResponse
    {
        $listing = $request->user()->listings()->find($listingId);

        if (!$listing) {
            return $this->errorResponse('NOT_FOUND', 'Lowongan tidak ditemukan atau bukan milik Anda.', null, 404);
        }

        $applications = $listing->applications()
            ->with(['user:id,name,avatar_url,is_verified', 'user.assistantProfile'])
            ->latest()
            ->paginate(20);

        return $this->successResponse($applications->items(), [
            'total' => $applications->total(),
        ]);
    }

    /**
     * List user's sent applications (Assistant)
     */
    public function myApplications(Request $request): JsonResponse
    {
        $applications = $request->user()->applications()
            ->with(['listing:id,title,city_name,period_type,status', 'listing.category:id,name'])
            ->latest()
            ->paginate(20);

        return $this->successResponse($applications->items(), [
            'total' => $applications->total(),
        ]);
    }

    /**
     * Show single application details
     */
    public function show(Request $request, string $id): JsonResponse
    {
        $application = Application::with(['user.assistantProfile', 'listing', 'interview', 'agreements'])
            ->find($id);

        if (!$application) {
            return $this->errorResponse('APPLICATION_NOT_FOUND', 'Lamaran tidak ditemukan.', null, 404);
        }

        $user = $request->user();
        // Only seeker owner or assistant applicant can view
        if ($application->user_id !== $user->id && $application->listing->user_id !== $user->id) {
            return $this->errorResponse('FORBIDDEN', 'Anda tidak memiliki akses ke lamaran ini.', null, 403);
        }

        return $this->successResponse($application);
    }

    /**
     * Shortlist application (Seeker)
     */
    public function shortlist(Request $request, string $id): JsonResponse
    {
        $application = Application::with('listing')->find($id);

        if (!$application || $application->listing->user_id !== $request->user()->id) {
            return $this->errorResponse('FORBIDDEN', 'Bukan pemilik lowongan.', null, 403);
        }

        $application->update(['status' => 'shortlisted']);

        return $this->successResponse([
            'message' => 'Pelamar berhasil masuk daftar pendek.',
            'status' => $application->status,
        ]);
    }

    /**
     * Accept application (Seeker)
     */
    public function accept(Request $request, string $id): JsonResponse
    {
        $application = Application::with('listing')->find($id);

        if (!$application || $application->listing->user_id !== $request->user()->id) {
            return $this->errorResponse('FORBIDDEN', 'Bukan pemilik lowongan.', null, 403);
        }

        $application->update(['status' => 'accepted']);

        return $this->successResponse([
            'message' => 'Pelamar diterima. Silakan susun kesepakatan kontrak.',
            'status' => $application->status,
        ]);
    }

    /**
     * Reject application (Seeker)
     */
    public function reject(Request $request, string $id): JsonResponse
    {
        $application = Application::with('listing')->find($id);

        if (!$application || $application->listing->user_id !== $request->user()->id) {
            return $this->errorResponse('FORBIDDEN', 'Bukan pemilik lowongan.', null, 403);
        }

        $application->update([
            'status' => 'rejected',
            'rejection_reason' => $request->input('reason'),
        ]);

        return $this->successResponse([
            'message' => 'Lamaran ditolak.',
            'status' => $application->status,
        ]);
    }

    /**
     * Withdraw application (Assistant)
     */
    public function withdraw(Request $request, string $id): JsonResponse
    {
        $application = $request->user()->applications()->find($id);

        if (!$application) {
            return $this->errorResponse('APPLICATION_NOT_FOUND', 'Lamaran tidak ditemukan.', null, 404);
        }

        if (in_array($application->status, ['accepted', 'rejected', 'withdrawn'])) {
            return $this->errorResponse('CANNOT_WITHDRAW', 'Lamaran tidak dapat ditarik pada status ini.', null, 409);
        }

        $application->update(['status' => 'withdrawn']);

        return $this->successResponse([
            'message' => 'Lamaran berhasil ditarik.',
            'status' => $application->status,
        ]);
    }
}

