<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Concerns\ApiResponse;
use App\Http\Controllers\Controller;
use App\Models\Booking;
use App\Models\Review;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ReviewController extends Controller
{
    use ApiResponse;

    /**
     * Submit review for a booking
     */
    public function store(Request $request, string $bookingId): JsonResponse
    {
        $booking = Booking::with('reviews')->find($bookingId);

        if (! $booking) {
            return $this->errorResponse('BOOKING_NOT_FOUND', 'Kontrak tidak ditemukan.', null, 404);
        }

        $user = $request->user();
        $isSeeker = $booking->seeker_id === $user->id;
        $isAssistant = $booking->assistant_id === $user->id;

        if (! $isSeeker && ! $isAssistant) {
            return $this->errorResponse('FORBIDDEN', 'Bukan pihak dalam kontrak ini.', null, 403);
        }

        $revieweeId = $isSeeker ? $booking->assistant_id : $booking->seeker_id;

        // Check if already submitted
        $alreadyReviewed = Review::where('booking_id', $bookingId)
            ->where('reviewer_id', $user->id)
            ->exists();

        if ($alreadyReviewed) {
            return $this->errorResponse('ALREADY_REVIEWED', 'Anda sudah memberikan penilaian untuk kontrak ini.', null, 409);
        }

        $validated = $request->validate([
            'rating' => ['required', 'integer', 'between:1,5'],
            'comment' => ['nullable', 'string', 'max:1000'],
        ]);

        $review = Review::create([
            'booking_id' => $booking->id,
            'reviewer_id' => $user->id,
            'reviewee_id' => $revieweeId,
            'rating' => $validated['rating'],
            'comment' => $validated['comment'] ?? null,
            'is_auto' => false,
            'revealed_at' => null, // Hidden until both submit or day 7
        ]);

        // If the other party has already submitted review, reveal both!
        $otherReview = Review::where('booking_id', $bookingId)
            ->where('reviewer_id', $revieweeId)
            ->first();

        if ($otherReview) {
            $now = now();
            $review->update(['revealed_at' => $now]);
            $otherReview->update(['revealed_at' => $now]);
        }

        return $this->successResponse([
            'message' => 'Penilaian Anda berhasil disimpan.',
            'review' => $review,
        ], null, 201);
    }

    /**
     * Get public revealed reviews for a user
     */
    public function userReviews(string $userId): JsonResponse
    {
        $reviews = Review::with('reviewer:id,name,avatar_url')
            ->where('reviewee_id', $userId)
            ->whereNotNull('revealed_at')
            ->latest()
            ->paginate(15);

        return $this->successResponse($reviews->items(), [
            'total' => $reviews->total(),
        ]);
    }
}
