<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Concerns\ApiResponse;
use App\Http\Controllers\Controller;
use App\Models\Booking;
use App\Models\Report;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ReportController extends Controller
{
    use ApiResponse;

    /**
     * Submit a report or dispute
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'reported_id' => ['required', 'string', 'exists:users,id'],
            'booking_id' => ['nullable', 'string', 'exists:bookings,id'],
            'category' => ['required', 'string', 'in:behavior,fraud,payment,not_as_described,other'],
            'description' => ['required', 'string'],
            'share_chat_consent' => ['boolean'],
        ]);

        $user = $request->user();

        // If related to a booking, mark booking as disputed
        if (! empty($validated['booking_id'])) {
            $booking = Booking::find($validated['booking_id']);
            if ($booking) {
                $booking->update(['status' => 'disputed']);
                // Freeze periods
                $booking->periods()
                    ->whereIn('status', ['paid', 'in_progress', 'awaiting_confirmation'])
                    ->update(['status' => 'disputed']);
            }
        }

        $shareConsent = $validated['share_chat_consent'] ?? false;

        $report = Report::create([
            'reporter_id' => $user->id,
            'reported_id' => $validated['reported_id'],
            'booking_id' => $validated['booking_id'] ?? null,
            'category' => $validated['category'],
            'description' => $validated['description'],
            'share_chat_consent' => $shareConsent,
            'consent_expires_at' => $shareConsent ? now()->addDays(7) : null,
            'status' => 'submitted',
        ]);

        return $this->successResponse([
            'message' => 'Laporan Anda telah diterima oleh tim moderasi.',
            'report' => $report,
        ], null, 201);
    }

    /**
     * Share conversation consent
     */
    public function shareConversation(Request $request, string $id): JsonResponse
    {
        $report = Report::find($id);

        if (! $report || $report->reporter_id !== $request->user()->id) {
            return $this->errorResponse('FORBIDDEN', 'Laporan tidak ditemukan.', null, 404);
        }

        $report->update([
            'share_chat_consent' => true,
            'consent_expires_at' => now()->addDays(7),
        ]);

        return $this->successResponse([
            'message' => 'Persetujuan membagikan riwayat percakapan berlaku selama 7 hari.',
            'consent_expires_at' => $report->consent_expires_at,
        ]);
    }
}
