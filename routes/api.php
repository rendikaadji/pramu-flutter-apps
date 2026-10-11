<?php

use App\Http\Controllers\Api\AgreementController;
use App\Http\Controllers\Api\ApplicationController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BookingController;
use App\Http\Controllers\Api\ListingController;
use App\Http\Controllers\Api\ReportController;
use App\Http\Controllers\Api\ReviewController;
use App\Http\Controllers\Api\VerificationController;
use App\Http\Controllers\Api\WalletController;
use App\Http\Controllers\Api\WebhookController;
use Illuminate\Support\Facades\Route;

// V1 API Endpoints
Route::prefix('v1')->group(function () {

    // Public Auth
    Route::post('/auth/register', [AuthController::class, 'register']);
    Route::post('/auth/otp/send', [AuthController::class, 'sendOtp']);
    Route::post('/auth/otp/verify', [AuthController::class, 'verifyOtp']);
    Route::post('/auth/login', [AuthController::class, 'login']);

    // Public Listings & Reviews
    Route::get('/listings', [ListingController::class, 'index']);
    Route::get('/listings/{id}', [ListingController::class, 'show']);
    Route::get('/users/{id}/reviews', [ReviewController::class, 'userReviews']);

    // Webhooks
    Route::post('/webhooks/xendit/invoice', [WebhookController::class, 'handleXenditInvoice']);

    // Protected Routes (Sanctum)
    Route::middleware('auth:sanctum')->group(function () {
        // Auth & Profile
        Route::post('/auth/logout', [AuthController::class, 'logout']);
        Route::get('/me', [AuthController::class, 'me']);
        Route::get('/me/roles', [AuthController::class, 'getRoles']);
        Route::post('/me/switch-role', [AuthController::class, 'switchRole']);

        // Verification & SKCK
        Route::post('/verification', [VerificationController::class, 'store']);
        Route::get('/verification/status', [VerificationController::class, 'status']);
        Route::post('/me/skck', [VerificationController::class, 'uploadSkck']);

        // Listings Management
        Route::post('/listings', [ListingController::class, 'store']);
        Route::post('/listings/{id}/pay', [ListingController::class, 'pay']);
        Route::get('/me/listings', [ListingController::class, 'myListings']);
        Route::post('/listings/{id}/close', [ListingController::class, 'close']);

        // Applications
        Route::post('/listings/{id}/applications', [ApplicationController::class, 'store']);
        Route::get('/listings/{id}/applications', [ApplicationController::class, 'listingApplications']);
        Route::get('/me/applications', [ApplicationController::class, 'myApplications']);
        Route::get('/applications/{id}', [ApplicationController::class, 'show']);
        Route::post('/applications/{id}/shortlist', [ApplicationController::class, 'shortlist']);
        Route::post('/applications/{id}/accept', [ApplicationController::class, 'accept']);
        Route::post('/applications/{id}/reject', [ApplicationController::class, 'reject']);
        Route::post('/applications/{id}/withdraw', [ApplicationController::class, 'withdraw']);

        // Agreements
        Route::post('/applications/{id}/agreement', [AgreementController::class, 'store']);
        Route::post('/agreements/{id}/approve', [AgreementController::class, 'approve']);

        // Bookings & Escrow Periods
        Route::get('/bookings', [BookingController::class, 'index']);
        Route::get('/bookings/{id}', [BookingController::class, 'show']);
        Route::post('/booking-periods/{id}/pay', [BookingController::class, 'payPeriod']);
        Route::post('/booking-periods/{id}/confirm-complete', [BookingController::class, 'confirmComplete']);
        Route::post('/bookings/{id}/cancel', [BookingController::class, 'cancel']);

        // Wallet & Payout
        Route::get('/wallet', [WalletController::class, 'index']);
        Route::get('/wallet/transactions', [WalletController::class, 'transactions']);
        Route::post('/me/bank-account', [WalletController::class, 'saveBankAccount']);
        Route::post('/wallet/payouts', [WalletController::class, 'requestPayout']);

        // Reviews
        Route::post('/bookings/{id}/reviews', [ReviewController::class, 'store']);

        // Reports & Disputes
        Route::post('/reports', [ReportController::class, 'store']);
        Route::post('/reports/{id}/share-conversation', [ReportController::class, 'shareConversation']);
    });
});

// Backward-compatible webhook path (Spec §8)
Route::post('/webhooks/xendit/invoice', [WebhookController::class, 'handleXenditInvoice']);
