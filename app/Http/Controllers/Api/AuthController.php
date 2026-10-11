<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Concerns\ApiResponse;
use App\Http\Controllers\Controller;
use App\Models\Otp;
use App\Models\User;
use App\Models\UserRole;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class AuthController extends Controller
{
    use ApiResponse;

    /**
     * Register new user (Phone + Email + Password)
     */
    public function register(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'phone' => ['required', 'string', 'max:20', 'unique:users,phone'],
            'email' => ['required', 'string', 'email', 'max:255', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8'],
            'role' => ['nullable', 'string', Rule::in(['seeker', 'assistant'])],
        ]);

        $role = $validated['role'] ?? 'seeker';

        $user = User::create([
            'name' => $validated['name'],
            'phone' => $validated['phone'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
            'active_role' => $role,
            'is_verified' => false,
            'status' => 'active',
        ]);

        UserRole::create([
            'user_id' => $user->id,
            'role' => $role,
        ]);

        // Auto create empty wallet for assistant
        if ($role === 'assistant') {
            $user->wallet()->create(['balance' => 0, 'held_balance' => 0]);
        }

        // Generate 6-digit OTP
        $otpCode = str_pad((string)random_int(100000, 999999), 6, '0', STR_PAD_LEFT);
        Otp::create([
            'phone' => $user->phone,
            'code' => $otpCode,
            'expires_at' => now()->addMinutes(5),
        ]);

        $token = $user->createToken('auth-token')->plainTextToken;

        return $this->successResponse([
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'phone' => $user->phone,
                'email' => $user->email,
                'active_role' => $user->active_role,
                'is_verified' => $user->is_verified,
            ],
            'token' => $token,
            'otp_hint' => config('app.env') === 'local' ? $otpCode : null,
        ], null, 201);
    }

    /**
     * Send or resend OTP
     */
    public function sendOtp(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'phone' => ['required', 'string'],
        ]);

        // Throttle check (max 5 per hour)
        $recentCount = Otp::where('phone', $validated['phone'])
            ->where('created_at', '>=', now()->subHour())
            ->count();

        if ($recentCount >= 5) {
            return $this->errorResponse(
                'TOO_MANY_ATTEMPTS',
                'Terlalu banyak permintaan OTP. Silakan tunggu 1 jam sebelum mencoba lagi.',
                null,
                429
            );
        }

        $code = str_pad((string)random_int(100000, 999999), 6, '0', STR_PAD_LEFT);
        Otp::create([
            'phone' => $validated['phone'],
            'code' => $code,
            'expires_at' => now()->addMinutes(5),
        ]);

        return $this->successResponse([
            'message' => 'Kode OTP berhasil dikirim.',
            'expires_in_seconds' => 300,
            'otp_hint' => config('app.env') === 'local' ? $code : null,
        ]);
    }

    /**
     * Verify 6-digit OTP
     */
    public function verifyOtp(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'phone' => ['required', 'string'],
            'code' => ['required', 'string', 'size:6'],
        ]);

        $otp = Otp::where('phone', $validated['phone'])
            ->whereNull('verified_at')
            ->latest()
            ->first();

        if (!$otp) {
            return $this->errorResponse('OTP_NOT_FOUND', 'Kode OTP tidak ditemukan atau belum diminta.', null, 404);
        }

        if ($otp->expires_at->isPast()) {
            return $this->errorResponse('OTP_EXPIRED', 'Kode OTP sudah kedaluwarsa. Silakan minta kode baru.', null, 422);
        }

        if ($otp->code !== $validated['code']) {
            $otp->increment('attempts');
            $remaining = max(0, 5 - $otp->attempts);

            if ($remaining === 0) {
                return $this->errorResponse('OTP_BLOCKED', 'Batas percobaan habis. Silakan kirim ulang kode.', null, 429);
            }

            return $this->errorResponse(
                'OTP_INVALID',
                "Kode OTP salah. Sisa percobaan: {$remaining}.",
                ['code' => ["Kode OTP salah."]],
                422
            );
        }

        $otp->update(['verified_at' => now()]);

        $user = User::where('phone', $validated['phone'])->first();
        if ($user) {
            $user->update(['phone_verified_at' => now()]);
        }

        return $this->successResponse([
            'message' => 'Verifikasi nomor HP berhasil.',
        ]);
    }

    /**
     * User Login (Phone or Email + Password)
     */
    public function login(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'login' => ['required', 'string'], // phone or email
            'password' => ['required', 'string'],
        ]);

        $user = User::where('email', $validated['login'])
            ->orWhere('phone', $validated['login'])
            ->first();

        if (!$user || !Hash::check($validated['password'], $user->password)) {
            return $this->errorResponse('INVALID_CREDENTIALS', 'Email/No. HP atau kata sandi tidak cocok.', null, 401);
        }

        if ($user->status === 'suspended') {
            return $this->errorResponse('ACCOUNT_SUSPENDED', 'Akun Anda sedang dinonaktifkan. Hubungi bantuan.', null, 403);
        }

        $token = $user->createToken('auth-token')->plainTextToken;

        return $this->successResponse([
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'phone' => $user->phone,
                'email' => $user->email,
                'active_role' => $user->active_role,
                'is_verified' => $user->is_verified,
                'avatar_url' => $user->avatar_url,
            ],
            'token' => $token,
        ]);
    }

    /**
     * Get Current Authenticated User Profile
     */
    public function me(Request $request): JsonResponse
    {
        $user = $request->user()->load(['roles', 'verification', 'assistantProfile', 'wallet']);

        return $this->successResponse([
            'id' => $user->id,
            'name' => $user->name,
            'phone' => $user->phone,
            'email' => $user->email,
            'active_role' => $user->active_role,
            'is_verified' => $user->is_verified,
            'roles' => $user->roles->pluck('role'),
            'verification' => $user->verification ? [
                'status' => $user->verification->status,
                'rejection_reason' => $user->verification->rejection_reason,
            ] : null,
            'assistant_profile' => $user->assistantProfile,
            'wallet' => $user->wallet ? [
                'balance' => $user->wallet->balance,
                'held_balance' => $user->wallet->held_balance,
            ] : null,
        ]);
    }

    /**
     * Get User Roles
     */
    public function getRoles(Request $request): JsonResponse
    {
        $roles = $request->user()->roles->pluck('role');

        return $this->successResponse([
            'active_role' => $request->user()->active_role,
            'available_roles' => $roles,
        ]);
    }

    /**
     * Switch Active Role (Pencari <-> Asisten)
     */
    public function switchRole(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'role' => ['required', 'string', Rule::in(['seeker', 'assistant'])],
        ]);

        $user = $request->user();

        // Ensure user has this role, or add it
        $hasRole = $user->roles()->where('role', $validated['role'])->exists();
        if (!$hasRole) {
            $user->roles()->create(['role' => $validated['role']]);
            if ($validated['role'] === 'assistant' && !$user->wallet()->exists()) {
                $user->wallet()->create(['balance' => 0, 'held_balance' => 0]);
            }
        }

        $user->update(['active_role' => $validated['role']]);

        return $this->successResponse([
            'message' => "Berhasil beralih ke peran {$validated['role']}.",
            'active_role' => $user->active_role,
        ]);
    }

    /**
     * Logout and Revoke Current Token
     */
    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return $this->successResponse([
            'message' => 'Berhasil keluar.',
        ]);
    }
}
