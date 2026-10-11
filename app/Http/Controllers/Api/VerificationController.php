<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Concerns\ApiResponse;
use App\Http\Controllers\Controller;
use App\Models\Skck;
use App\Models\Verification;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class VerificationController extends Controller
{
    use ApiResponse;

    /**
     * Submit KTP and Selfie verification
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'nik' => ['required', 'string', 'size:16'],
            'ktp' => ['required', 'image', 'max:5120'], // Max 5MB
            'selfie' => ['required', 'image', 'max:5120'],
        ]);

        $user = $request->user();

        // Check duplicate NIK by other verified user
        $duplicateNik = Verification::where('nik', $validated['nik'])
            ->where('user_id', '!=', $user->id)
            ->where('status', 'verified')
            ->exists();

        if ($duplicateNik) {
            return $this->errorResponse(
                'NIK_ALREADY_USED',
                'NIK ini sudah terdaftar pada akun terverifikasi lain. Silakan hubungi bantuan.',
                ['nik' => ['NIK sudah terdaftar.']],
                422
            );
        }

        $ktpPath = $request->file('ktp')->store('verifications/ktp', 'local');
        $selfiePath = $request->file('selfie')->store('verifications/selfie', 'local');

        $verification = Verification::updateOrCreate(
            ['user_id' => $user->id],
            [
                'nik' => $validated['nik'],
                'ktp_path' => $ktpPath,
                'selfie_path' => $selfiePath,
                'status' => 'pending',
                'rejection_reason' => null,
            ]
        );

        return $this->successResponse([
            'status' => $verification->status,
            'message' => 'Berkas verifikasi berhasil dikirim. Menunggu tinjauan petugas.',
        ], null, 201);
    }

    /**
     * Get Verification status
     */
    public function status(Request $request): JsonResponse
    {
        $verification = $request->user()->verification;

        if (!$verification) {
            return $this->successResponse([
                'status' => 'unverified',
                'rejection_reason' => null,
            ]);
        }

        return $this->successResponse([
            'status' => $verification->status,
            'rejection_reason' => $verification->rejection_reason,
            'reviewed_at' => $verification->reviewed_at,
        ]);
    }

    /**
     * Upload or update SKCK
     */
    public function uploadSkck(Request $request): JsonResponse
    {
        $request->validate([
            'file' => ['required', 'file', 'mimes:jpg,jpeg,png,pdf', 'max:5120'],
        ]);

        $path = $request->file('file')->store('skck', 'local');

        $skck = Skck::updateOrCreate(
            ['user_id' => $request->user()->id],
            [
                'file_path' => $path,
                'status' => 'pending',
                'rejection_reason' => null,
            ]
        );

        return $this->successResponse([
            'status' => $skck->status,
            'message' => 'Dokumen SKCK berhasil diunggah. Menunggu verifikasi.',
        ]);
    }
}
