<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Concerns\ApiResponse;
use App\Http\Controllers\Controller;
use App\Models\BankAccount;
use App\Models\Payout;
use App\Models\Wallet;
use App\Models\WalletTransaction;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class WalletController extends Controller
{
    use ApiResponse;

    /**
     * Get wallet balance & summary
     */
    public function index(Request $request): JsonResponse
    {
        $wallet = Wallet::firstOrCreate(
            ['user_id' => $request->user()->id],
            ['balance' => 0, 'held_balance' => 0]
        );

        $bankAccount = BankAccount::where('user_id', $request->user()->id)
            ->where('is_active', true)
            ->first();

        return $this->successResponse([
            'balance' => $wallet->balance,
            'held_balance' => $wallet->held_balance,
            'bank_account' => $bankAccount ? [
                'id' => $bankAccount->id,
                'bank_name' => $bankAccount->bank_name,
                'account_number_masked' => '••••'.substr($bankAccount->account_number, -4),
                'account_holder_name' => $bankAccount->account_holder_name,
            ] : null,
        ]);
    }

    /**
     * Get wallet transactions
     */
    public function transactions(Request $request): JsonResponse
    {
        $wallet = $request->user()->wallet;

        if (! $wallet) {
            return $this->successResponse([]);
        }

        $transactions = $wallet->transactions()
            ->latest()
            ->paginate(20);

        return $this->successResponse($transactions->items(), [
            'total' => $transactions->total(),
        ]);
    }

    /**
     * Save or update bank account
     */
    public function saveBankAccount(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'bank_code' => ['required', 'string'],
            'bank_name' => ['required', 'string'],
            'account_number' => ['required', 'string', 'min:8', 'max:30'],
            'account_holder_name' => ['required', 'string', 'max:255'],
        ]);

        $account = BankAccount::updateOrCreate(
            ['user_id' => $request->user()->id],
            [
                ...$validated,
                'is_active' => true,
            ]
        );

        return $this->successResponse([
            'id' => $account->id,
            'bank_name' => $account->bank_name,
            'account_number_masked' => '••••'.substr($account->account_number, -4),
            'account_holder_name' => $account->account_holder_name,
            'message' => 'Rekening bank berhasil disimpan.',
        ]);
    }

    /**
     * Request payout (Tarik Dana)
     */
    public function requestPayout(Request $request): JsonResponse
    {
        $idempotencyKey = $request->header('Idempotency-Key');

        $validated = $request->validate([
            'amount' => ['required', 'integer', 'min:50000'],
        ]);

        $user = $request->user();

        if (! $user->is_verified) {
            return $this->errorResponse('VERIFICATION_REQUIRED', 'Akun harus terverifikasi untuk menarik dana.', null, 403);
        }

        $bankAccount = BankAccount::where('user_id', $user->id)->where('is_active', true)->first();
        if (! $bankAccount) {
            return $this->errorResponse('BANK_ACCOUNT_REQUIRED', 'Silakan daftarkan rekening bank terlebih dahulu.', null, 422);
        }

        $wallet = $user->wallet;
        if (! $wallet || $wallet->balance < $validated['amount']) {
            return $this->errorResponse('INSUFFICIENT_BALANCE', 'Saldo dompet tidak mencukupi.', null, 422);
        }

        return DB::transaction(function () use ($wallet, $bankAccount, $validated, $idempotencyKey) {
            $wallet->decrement('balance', $validated['amount']);

            $payout = Payout::create([
                'wallet_id' => $wallet->id,
                'bank_account_id' => $bankAccount->id,
                'amount' => $validated['amount'],
                'status' => 'queued',
                'idempotency_key' => $idempotencyKey,
            ]);

            WalletTransaction::create([
                'wallet_id' => $wallet->id,
                'type' => 'debit',
                'category' => 'payout',
                'amount' => $validated['amount'],
                'reference_type' => Payout::class,
                'reference_id' => $payout->id,
                'description' => "Penarikan dana ke rekening {$bankAccount->bank_name} ••••".substr($bankAccount->account_number, -4),
            ]);

            return $this->successResponse([
                'message' => 'Permintaan penarikan dana berhasil dibuat dan sedang dalam antrean.',
                'payout' => $payout,
            ], null, 201);
        });
    }
}
