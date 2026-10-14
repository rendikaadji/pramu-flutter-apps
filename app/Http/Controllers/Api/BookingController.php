<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Concerns\ApiResponse;
use App\Http\Controllers\Controller;
use App\Models\Booking;
use App\Models\BookingPeriod;
use App\Models\Wallet;
use App\Models\WalletTransaction;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class BookingController extends Controller
{
    use ApiResponse;

    /**
     * List current user's bookings (as Seeker or Assistant)
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $bookings = Booking::with([
            'periods',
            'listing:id,title,city_name',
            'seeker:id,name,avatar_url',
            'assistant:id,name,avatar_url',
        ])
            ->where(function ($q) use ($user) {
                $q->where('seeker_id', $user->id)
                    ->orWhere('assistant_id', $user->id);
            })
            ->latest()
            ->paginate(15);

        return $this->successResponse($bookings->items(), [
            'total' => $bookings->total(),
        ]);
    }

    /**
     * Show booking detail
     */
    public function show(Request $request, string $id): JsonResponse
    {
        $user = $request->user();

        $booking = Booking::with([
            'periods',
            'listing',
            'seeker:id,name,avatar_url,phone',
            'assistant:id,name,avatar_url,phone',
        ])
            ->where(function ($q) use ($user) {
                $q->where('seeker_id', $user->id)
                    ->orWhere('assistant_id', $user->id);
            })
            ->find($id);

        if (! $booking) {
            return $this->errorResponse('BOOKING_NOT_FOUND', 'Kontrak tidak ditemukan.', null, 404);
        }

        // Mask contact details if no period is paid yet (PRD §5.6, CHT-2)
        $hasPaidPeriod = $booking->periods->contains(fn ($p) => in_array($p->status, ['paid', 'in_progress', 'completed', 'settled']));
        if (! $hasPaidPeriod) {
            if ($booking->seeker) {
                $booking->seeker->phone = '••••••••';
            }
            if ($booking->assistant) {
                $booking->assistant->phone = '••••••••';
            }
        }

        return $this->successResponse($booking);
    }

    /**
     * Pay a booking period (Escrow via Xendit)
     */
    public function payPeriod(Request $request, string $periodId): JsonResponse
    {
        $idempotencyKey = $request->header('Idempotency-Key');

        $period = BookingPeriod::with('booking')->find($periodId);

        if (! $period) {
            return $this->errorResponse('PERIOD_NOT_FOUND', 'Periode tagihan tidak ditemukan.', null, 404);
        }

        if ($period->booking->seeker_id !== $request->user()->id) {
            return $this->errorResponse('FORBIDDEN', 'Hanya pencari yang dapat membayar tagihan.', null, 403);
        }

        if ($period->status !== 'awaiting_payment') {
            return $this->errorResponse('INVALID_STATE', 'Status tagihan tidak dalam status menunggu pembayaran.', null, 409);
        }

        $externalId = "period_pay_{$period->id}_".Str::random(6);
        $invoiceUrl = "https://checkout-staging.xendit.co/web/{$externalId}";

        $period->update([
            'invoice_id' => $externalId,
            'invoice_url' => $invoiceUrl,
            'idempotency_key' => $idempotencyKey,
        ]);

        return $this->successResponse([
            'period_id' => $period->id,
            'amount' => $period->amount,
            'seeker_fee' => $period->seeker_fee,
            'total' => $period->total_to_pay,
            'invoice_url' => $invoiceUrl,
            'external_id' => $externalId,
            'status' => $period->status,
        ]);
    }

    /**
     * Confirm period work completed (Seeker) -> Releases funds to assistant wallet
     */
    public function confirmComplete(Request $request, string $periodId): JsonResponse
    {
        $period = BookingPeriod::with('booking')->find($periodId);

        if (! $period) {
            return $this->errorResponse('PERIOD_NOT_FOUND', 'Periode tidak ditemukan.', null, 404);
        }

        if ($period->booking->seeker_id !== $request->user()->id) {
            return $this->errorResponse('FORBIDDEN', 'Hanya pencari yang dapat mengonfirmasi pekerjaan selesai.', null, 403);
        }

        if (! in_array($period->status, ['paid', 'in_progress', 'awaiting_confirmation'])) {
            return $this->errorResponse('INVALID_STATE', 'Periode belum dalam status yang dapat dikonfirmasi.', null, 409);
        }

        return DB::transaction(function () use ($period) {
            $period->status = 'settled';
            $period->completed_at = now();
            $period->settled_at = now();
            $period->save();

            // Credit Assistant Wallet
            $wallet = Wallet::firstOrCreate(
                ['user_id' => $period->booking->assistant_id],
                ['balance' => 0, 'held_balance' => 0]
            );

            $wallet->increment('balance', $period->total_payout);

            WalletTransaction::create([
                'wallet_id' => $wallet->id,
                'type' => 'credit',
                'category' => 'settlement',
                'amount' => $period->total_payout,
                'reference_type' => BookingPeriod::class,
                'reference_id' => $period->id,
                'description' => "Pencairan dana periode #{$period->period_number} selesai.",
            ]);

            return $this->successResponse([
                'message' => 'Pekerjaan berhasil dikonfirmasi. Dana telah dicairkan ke dompet asisten.',
                'period' => $period,
            ]);
        });
    }

    /**
     * Cancel booking
     */
    public function cancel(Request $request, string $id): JsonResponse
    {
        $booking = Booking::with('periods')->find($id);

        if (! $booking) {
            return $this->errorResponse('BOOKING_NOT_FOUND', 'Kontrak tidak ditemukan.', null, 404);
        }

        $user = $request->user();
        if ($booking->seeker_id !== $user->id && $booking->assistant_id !== $user->id) {
            return $this->errorResponse('FORBIDDEN', 'Bukan pihak dalam kontrak ini.', null, 403);
        }

        $booking->update(['status' => 'cancelled']);

        return $this->successResponse([
            'message' => 'Kontrak telah dibatalkan.',
            'booking' => $booking,
        ]);
    }
}
