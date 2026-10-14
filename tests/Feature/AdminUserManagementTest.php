<?php

namespace Tests\Feature;

use App\Models\Agreement;
use App\Models\Application;
use App\Models\AssistantProfile;
use App\Models\Booking;
use App\Models\Category;
use App\Models\Listing;
use App\Models\Review;
use App\Models\Skck;
use App\Models\User;
use App\Models\Verification;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminUserManagementTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Test admin can view assistant rating and review counts on users index
     */
    public function test_admin_can_view_assistant_rating_and_review_counts(): void
    {
        $category = Category::create([
            'name' => 'Asisten Rumah Tangga',
            'slug' => 'art',
            'icon' => 'home',
        ]);

        $seeker = User::create([
            'name' => 'Pak Budi',
            'email' => 'budi.majikan@pramu.id',
            'phone' => '081211112222',
            'password' => bcrypt('password'),
            'active_role' => 'seeker',
        ]);

        $assistant = User::create([
            'name' => 'Siti Nurhaliza',
            'email' => 'siti.asisten@pramu.id',
            'phone' => '081233334444',
            'password' => bcrypt('password'),
            'active_role' => 'assistant',
        ]);

        AssistantProfile::create([
            'user_id' => $assistant->id,
            'experience_years' => 4,
            'rate_per_period' => 2500000,
            'period_type' => 'monthly',
            'bio' => 'Berpengalaman mengurus rumah dan memasak.',
        ]);

        $listing = Listing::create([
            'user_id' => $seeker->id,
            'category_id' => $category->id,
            'title' => 'Dibutuhkan ART Harian',
            'description' => 'Membantu pekerjaan rumah tangga harian.',
            'budget_min' => 2000000,
            'budget_max' => 3000000,
            'period_type' => 'monthly',
            'start_date' => now()->toDateString(),
            'status' => 'open',
        ]);

        $application = Application::create([
            'listing_id' => $listing->id,
            'user_id' => $assistant->id,
            'proposed_rate' => 2500000,
            'status' => 'accepted',
        ]);

        $agreement = Agreement::create([
            'application_id' => $application->id,
            'proposed_by_user_id' => $seeker->id,
            'rate_per_period' => 2500000,
            'period_type' => 'monthly',
            'period_count' => 1,
            'billing_cycle' => 'monthly',
            'start_date' => now()->toDateString(),
            'status' => 'approved',
        ]);

        $booking = Booking::create([
            'agreement_id' => $agreement->id,
            'seeker_id' => $seeker->id,
            'assistant_id' => $assistant->id,
            'listing_id' => $listing->id,
            'total_amount' => 2500000,
            'status' => 'active',
        ]);

        // Create review for assistant
        Review::create([
            'booking_id' => $booking->id,
            'reviewer_id' => $seeker->id,
            'reviewee_id' => $assistant->id,
            'rating' => 5,
            'comment' => 'Kerja sangat cekatan dan rajin.',
        ]);

        $response = $this->get('/admin/users?role=assistant');

        $response->assertStatus(200);
        $response->assertSee('Siti Nurhaliza');
        $response->assertSee('5.0');
        $response->assertSee('1 ulasan');
        $response->assertSee('4 Thn Pengalaman');
    }

    /**
     * Test admin can view SKCK and KTP status with SKCK only required for assistant
     */
    public function test_admin_can_view_skck_and_ktp_status_for_assistant(): void
    {
        $assistant = User::create([
            'name' => 'Siti Nurhaliza',
            'email' => 'siti.asisten@pramu.id',
            'phone' => '081233334444',
            'password' => bcrypt('password'),
            'active_role' => 'assistant',
        ]);

        $seeker = User::create([
            'name' => 'Pak Budi',
            'email' => 'budi.majikan@pramu.id',
            'phone' => '081211112222',
            'password' => bcrypt('password'),
            'active_role' => 'seeker',
        ]);

        Verification::create([
            'user_id' => $assistant->id,
            'nik' => '3201010101010001',
            'ktp_path' => 'verifications/ktp_siti.jpg',
            'selfie_path' => 'verifications/selfie_siti.jpg',
            'status' => 'verified',
        ]);

        Skck::create([
            'user_id' => $assistant->id,
            'file_path' => 'skck/skck_siti.pdf',
            'status' => 'pending',
        ]);

        $response = $this->get('/admin/users');

        $response->assertStatus(200);
        $response->assertSee('KTP:');
        $response->assertSee('SKCK:');
        $response->assertSee('Lihat Detail');
        $response->assertSee('Tidak Diperlukan');
    }

    /**
     * Test admin can view dedicated assistant user detail page with rating and SKCK
     */
    public function test_admin_can_view_dedicated_assistant_user_detail_page(): void
    {
        $category = Category::create([
            'name' => 'Asisten Rumah Tangga',
            'slug' => 'art-detail',
            'icon' => 'home',
        ]);

        $seeker = User::create([
            'name' => 'Pak Majikan Budi',
            'email' => 'majikan.budi@pramu.id',
            'phone' => '081255556666',
            'password' => bcrypt('password'),
            'active_role' => 'seeker',
        ]);

        $assistant = User::create([
            'name' => 'Dewi Sartika',
            'email' => 'dewi.asisten@pramu.id',
            'phone' => '081277778888',
            'password' => bcrypt('password'),
            'active_role' => 'assistant',
        ]);

        AssistantProfile::create([
            'user_id' => $assistant->id,
            'experience_years' => 5,
            'rate_per_period' => 3000000,
            'period_type' => 'monthly',
            'bio' => 'Asisten berpengalaman merawat lansia.',
        ]);

        $listing = Listing::create([
            'user_id' => $seeker->id,
            'category_id' => $category->id,
            'title' => 'Dibutuhkan ART Full Time',
            'description' => 'Membantu pekerjaan rumah tangga harian.',
            'budget_min' => 2500000,
            'budget_max' => 3500000,
            'period_type' => 'monthly',
            'start_date' => now()->toDateString(),
            'status' => 'open',
        ]);

        $application = Application::create([
            'listing_id' => $listing->id,
            'user_id' => $assistant->id,
            'proposed_rate' => 3000000,
            'status' => 'accepted',
        ]);

        $agreement = Agreement::create([
            'application_id' => $application->id,
            'proposed_by_user_id' => $seeker->id,
            'rate_per_period' => 3000000,
            'period_type' => 'monthly',
            'period_count' => 1,
            'billing_cycle' => 'monthly',
            'start_date' => now()->toDateString(),
            'status' => 'approved',
        ]);

        $booking = Booking::create([
            'agreement_id' => $agreement->id,
            'seeker_id' => $seeker->id,
            'assistant_id' => $assistant->id,
            'listing_id' => $listing->id,
            'total_amount' => 3000000,
            'status' => 'active',
        ]);

        Review::create([
            'booking_id' => $booking->id,
            'reviewer_id' => $seeker->id,
            'reviewee_id' => $assistant->id,
            'rating' => 5,
            'comment' => 'Sangat rajin dan bertanggung jawab.',
        ]);

        $response = $this->get("/admin/users/{$assistant->id}");

        $response->assertStatus(200);
        $response->assertSee('Dewi Sartika');
        $response->assertSee('Asisten Rumah Tangga (ART)');
        $response->assertSee('5.0');
        $response->assertSee('1 ulasan');
        $response->assertSee('Sangat rajin dan bertanggung jawab.');
        $response->assertSee('Kembali ke Daftar Asisten (ART)');
    }

    /**
     * Test admin can view seeker detail page with no SKCK required
     */
    public function test_admin_can_view_seeker_detail_page(): void
    {
        $seeker = User::create([
            'name' => 'Ibu Rina',
            'email' => 'rina.majikan@pramu.id',
            'phone' => '081299990000',
            'password' => bcrypt('password'),
            'active_role' => 'seeker',
        ]);

        $response = $this->get("/admin/users/{$seeker->id}");

        $response->assertStatus(200);
        $response->assertSee('Ibu Rina');
        $response->assertSee('Majikan (Pencari)');
        $response->assertSee('Tidak Diperlukan (Majikan)');
        $response->assertSee('Kembali ke Daftar Majikan (Pencari)');
    }

    /**
     * Test admin can view assistant rating on verification review page
     */
    public function test_admin_can_view_assistant_rating_on_verification_show(): void
    {
        $assistant = User::create([
            'name' => 'Nur Aini',
            'email' => 'nur.aini@pramu.id',
            'phone' => '081244445555',
            'password' => bcrypt('password'),
            'active_role' => 'assistant',
        ]);

        $verification = Verification::create([
            'user_id' => $assistant->id,
            'nik' => '3201019999990001',
            'ktp_path' => 'verifications/ktp_nur.jpg',
            'selfie_path' => 'verifications/selfie_nur.jpg',
            'status' => 'pending',
        ]);

        $response = $this->get("/admin/verifications/{$verification->id}");

        $response->assertStatus(200);
        $response->assertSee('Nur Aini');
        $response->assertSee('Rating Asisten');
        $response->assertSee('Lihat Detail Pengguna');
    }

    /**
     * Test admin can approve and reject SKCK document
     */
    public function test_admin_can_approve_and_reject_skck(): void
    {
        $assistant = User::create([
            'name' => 'Siti Nurhaliza',
            'email' => 'siti.asisten@pramu.id',
            'phone' => '081233334444',
            'password' => bcrypt('password'),
            'active_role' => 'assistant',
        ]);

        $skck = Skck::create([
            'user_id' => $assistant->id,
            'file_path' => 'skck/skck_siti.pdf',
            'status' => 'pending',
        ]);

        $approveResponse = $this->post("/admin/skck/{$skck->id}/approve");
        $approveResponse->assertRedirect();
        $this->assertDatabaseHas('skcks', [
            'id' => $skck->id,
            'status' => 'verified',
        ]);

        $rejectResponse = $this->post("/admin/skck/{$skck->id}/reject", [
            'reason' => 'Masa berlaku SKCK habis.',
        ]);
        $rejectResponse->assertRedirect();
        $this->assertDatabaseHas('skcks', [
            'id' => $skck->id,
            'status' => 'rejected',
            'rejection_reason' => 'Masa berlaku SKCK habis.',
        ]);
    }
}
