<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Concerns\ApiResponse;
use App\Http\Controllers\Controller;
use App\Models\BookingPeriod;
use App\Models\Listing;
use App\Models\WebhookEvent;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class WebhookController extends Controller
{
    use ApiResponse;

    /**
     * Handle Xendit Invoice Paid Webhook
     */
    public function handleXenditInvoice(Request $request): JsonResponse
    {
        $callbackToken = $request->header('x-callback-token');
        $expectedToken = config('services.xendit.callback_token', env('XENDIT_CALLBACK_TOKEN'));

        // Validate callback token if configured
        if ($expectedToken && $callbackToken !== $expectedToken) {
            return $this->errorResponse('INVALID_CALLBACK_TOKEN', 'Token verifikasi webhook tidak cocok.', null, 403);
        }

        $eventId = $request->input('id');
        $externalId = $request->input('external_id');
        $status = strtoupper($request->input('status', ''));

        if (!$eventId || !$externalId) {
            return $this->errorResponse('INVALID_PAYLOAD', 'Payload webhook tidak lengkap.', null, 422);
        }

        // Idempotency check
        $alreadyProcessed = WebhookEvent::where('event_id', $eventId)->exists();
        if ($alreadyProcessed) {
            return $this->successResponse(['message' => 'Event already processed.']);
        }

        return DB::transaction(function () use ($eventId, $externalId, $status, $request) {
            WebhookEvent::create([
                'event_id' => $eventId,
                'source' => 'xendit',
                'event_type' => 'invoice.' . strtolower($status),
                'payload' => $request->all(),
                'processed_at' => now(),
            ]);

            if ($status === 'PAID') {
                // 1. Listing Publishing Fee
                if (str_starts_with($externalId, 'listing_fee_')) {
                    $listing = Listing::where('listing_fee_invoice_id', $externalId)->first();
                    if ($listing) {
                        $listing->update([
                            'status' => 'open',
                            'paid_at' => now(),
                            'expires_at' => now()->addDays(30),
                        ]);
                    }
                }

                // 2. Booking Period Escrow Payment
                if (str_starts_with($externalId, 'period_pay_')) {
                    $period = BookingPeriod::where('invoice_id', $externalId)->first();
                    if ($period) {
                        $period->update([
                            'status' => 'paid',
                            'paid_at' => now(),
                        ]);
                    }
                }
            }

            return $this->successResponse(['message' => 'Webhook berhasil diproses.']);
        });
    }
}
