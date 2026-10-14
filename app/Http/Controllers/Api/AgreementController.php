<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Concerns\ApiResponse;
use App\Http\Controllers\Controller;
use App\Models\Agreement;
use App\Models\Application;
use App\Models\Booking;
use App\Models\BookingPeriod;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AgreementController extends Controller
{
    use ApiResponse;

    /**
     * Propose initial contract agreement
     */
    public function store(Request $request, string $applicationId): JsonResponse
    {
        $application = Application::with('listing')->find($applicationId);

        if (! $application) {
            return $this->errorResponse('NOT_FOUND', 'Lamaran tidak ditemukan.', null, 404);
        }

        $user = $request->user();
        $isSeeker = $application->listing->user_id === $user->id;
        $isAssistant = $application->user_id === $user->id;

        if (! $isSeeker && ! $isAssistant) {
            return $this->errorResponse('FORBIDDEN', 'Anda tidak terlibat dalam lamaran ini.', null, 403);
        }

        $validated = $request->validate([
            'rate_per_period' => ['required', 'integer', 'min:10000'],
            'period_type' => ['required', 'string', 'in:hourly,daily,weekly,monthly'],
            'period_count' => ['required', 'integer', 'min:1'],
            'billing_cycle' => ['required', 'string', 'in:weekly,biweekly,monthly'],
            'start_date' => ['required', 'date', 'after_or_equal:today'],
        ]);

        $agreement = Agreement::create([
            'application_id' => $application->id,
            'version' => 1,
            'proposed_by_user_id' => $user->id,
            'rate_per_period' => $validated['rate_per_period'],
            'period_type' => $validated['period_type'],
            'period_count' => $validated['period_count'],
            'billing_cycle' => $validated['billing_cycle'],
            'start_date' => $validated['start_date'],
            'seeker_approved_at' => $isSeeker ? now() : null,
            'assistant_approved_at' => $isAssistant ? now() : null,
            'status' => 'proposed',
        ]);

        return $this->successResponse($agreement, null, 201);
    }

    /**
     * Approve agreement (Seeker or Assistant)
     */
    public function approve(Request $request, string $id): JsonResponse
    {
        $agreement = Agreement::with(['application.listing'])->find($id);

        if (! $agreement) {
            return $this->errorResponse('NOT_FOUND', 'Kesepakatan tidak ditemukan.', null, 404);
        }

        $user = $request->user();
        $isSeeker = $agreement->application->listing->user_id === $user->id;
        $isAssistant = $agreement->application->user_id === $user->id;

        if (! $isSeeker && ! $isAssistant) {
            return $this->errorResponse('FORBIDDEN', 'Bukan pihak dalam kesepakatan ini.', null, 403);
        }

        if ($isSeeker) {
            $agreement->seeker_approved_at = now();
        }
        if ($isAssistant) {
            $agreement->assistant_approved_at = now();
        }

        // When both approved -> lock agreement & create Booking + Periods
        if ($agreement->seeker_approved_at && $agreement->assistant_approved_at) {
            return DB::transaction(function () use ($agreement) {
                $agreement->status = 'approved';
                $agreement->save();

                $totalAmount = $agreement->rate_per_period * $agreement->period_count;

                $booking = Booking::create([
                    'agreement_id' => $agreement->id,
                    'seeker_id' => $agreement->application->listing->user_id,
                    'assistant_id' => $agreement->application->user_id,
                    'listing_id' => $agreement->application->listing_id,
                    'total_amount' => $totalAmount,
                    'status' => 'active',
                ]);

                // Create Periods
                $startDate = Carbon::parse($agreement->start_date);
                for ($i = 1; $i <= $agreement->period_count; $i++) {
                    $amount = $agreement->rate_per_period;
                    $seekerFee = (int) round($amount * 0.05); // 5% Seeker service fee
                    $assistantFee = (int) round($amount * 0.05); // 5% Assistant service fee
                    $totalToPay = $amount + $seekerFee;
                    $totalPayout = $amount - $assistantFee;

                    BookingPeriod::create([
                        'booking_id' => $booking->id,
                        'period_number' => $i,
                        'amount' => $amount,
                        'seeker_fee' => $seekerFee,
                        'assistant_fee' => $assistantFee,
                        'total_to_pay' => $totalToPay,
                        'total_payout' => $totalPayout,
                        'due_date' => $startDate->copy()->addMonths($i - 1)->toDateString(),
                        'status' => 'awaiting_payment',
                    ]);
                }

                return $this->successResponse([
                    'message' => 'Kedua pihak telah menyetujui. Kontrak berhasil dibuat.',
                    'booking_id' => $booking->id,
                    'agreement' => $agreement,
                ]);
            });
        }

        $agreement->save();

        return $this->successResponse([
            'message' => 'Persetujuan Anda tersimpan. Menunggu persetujuan pihak lain.',
            'agreement' => $agreement,
        ]);
    }
}
