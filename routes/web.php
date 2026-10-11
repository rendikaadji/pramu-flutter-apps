<?php

use App\Http\Controllers\Admin\AdminController;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Storage;

Route::get('/', function () {
    return redirect()->route('admin.dashboard');
});

// Admin Panel Web Routes
Route::prefix('admin')->name('admin.')->group(function () {
    Route::get('/', [AdminController::class, 'dashboard'])->name('dashboard');

    // Redirects for legacy/removed sections to prevent 404 when browser refreshes
    Route::redirect('/system', '/admin', 301);
    Route::redirect('/settings', '/admin', 301);

    // Verifications Review
    Route::get('/verifications', [AdminController::class, 'verifications'])->name('verifications.index');
    Route::get('/verifications/{id}', [AdminController::class, 'showVerification'])->name('verifications.show');
    Route::post('/verifications/{id}/approve', [AdminController::class, 'approveVerification'])->name('verifications.approve');
    Route::post('/verifications/{id}/reject', [AdminController::class, 'rejectVerification'])->name('verifications.reject');

    // Users Management
    Route::get('/users', [AdminController::class, 'users'])->name('users.index');

    // Job Listings
    Route::get('/listings', [AdminController::class, 'listings'])->name('listings.index');

    // Interviews (Google Meet)
    Route::get('/interviews', [AdminController::class, 'interviews'])->name('interviews.index');

    // Escrow & Bookings
    Route::get('/bookings', [AdminController::class, 'bookings'])->name('bookings.index');

    // Platform Finances & Escrow Settlement
    Route::get('/finances', [AdminController::class, 'finances'])->name('finances.index');

    // Reports & Disputes
    Route::get('/reports', [AdminController::class, 'reports'])->name('reports.index');
    Route::post('/reports/{id}/resolve', [AdminController::class, 'resolveReport'])->name('reports.resolve');

    // Secure Internal File Preview (Only via local app storage)
    Route::get('/files/preview', function () {
        $path = request()->query('path');
        if (!$path) {
            abort(404);
        }
        if (Storage::disk('local')->exists($path)) {
            return response()->file(Storage::disk('local')->path($path));
        }
        if (file_exists(storage_path('app/' . $path))) {
            return response()->file(storage_path('app/' . $path));
        }
        abort(404);
    })->name('file.preview');
});

// Root level redirects for removed sections
Route::redirect('/system', '/admin', 301);
Route::redirect('/settings', '/admin', 301);
