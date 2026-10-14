<?php

namespace Tests\Feature;

use App\Models\Application;
use App\Models\AssistantProfile;
use App\Models\Category;
use App\Models\Listing;
use App\Models\User;
use App\Models\Verification;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminListingManagementTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Test admin can view listings index with simplified status tabs (Semua, Tayang Aktif, Draf / Belum Bayar)
     */
    public function test_admin_can_view_listings_index_with_status_filtering(): void
    {
        $category = Category::create([
            'name' => 'Asisten Rumah Tangga',
            'slug' => 'art',
            'icon' => 'home',
        ]);

        $seeker = User::create([
            'name' => 'Budi Sudarsono',
            'email' => 'budi@pramu.id',
            'phone' => '081211112222',
            'password' => bcrypt('password'),
            'active_role' => 'seeker',
        ]);

        $openListing = Listing::create([
            'user_id' => $seeker->id,
            'category_id' => $category->id,
            'title' => 'Dibutuhkan Babysitter Balita',
            'description' => 'Mencari babysitter berpengalaman.',
            'city_name' => 'Surabaya',
            'period_type' => 'monthly',
            'period_count' => 1,
            'billing_cycle' => 'monthly',
            'start_date' => now()->toDateString(),
            'budget_min' => 3000000,
            'budget_max' => 4000000,
            'status' => 'open',
            'paid_at' => now(),
        ]);

        $draftListing = Listing::create([
            'user_id' => $seeker->id,
            'category_id' => $category->id,
            'title' => 'Dibutuhkan ART Masak Harian',
            'description' => 'Mencari ART yang bisa memasak.',
            'city_name' => 'Jakarta Selatan',
            'period_type' => 'monthly',
            'period_count' => 1,
            'billing_cycle' => 'monthly',
            'start_date' => now()->toDateString(),
            'budget_min' => 2500000,
            'budget_max' => 3500000,
            'status' => 'draft',
        ]);

        $response = $this->get('/admin/listings');

        $response->assertStatus(200);
        $response->assertSee('Semua (2)');
        $response->assertSee('Tayang Aktif (1)');
        $response->assertSee('Draf / Belum Bayar (1)');
        $response->assertSee('Dibutuhkan Babysitter Balita');
        $response->assertSee('Dibutuhkan ART Masak Harian');
        $response->assertSee('Lihat Detail');

        // Test filter by open status
        $openResponse = $this->get('/admin/listings?status=open');
        $openResponse->assertStatus(200);
        $openResponse->assertSee('Dibutuhkan Babysitter Balita');
        $openResponse->assertDontSee('Dibutuhkan ART Masak Harian');

        // Test filter by draft status
        $draftResponse = $this->get('/admin/listings?status=draft');
        $draftResponse->assertStatus(200);
        $draftResponse->assertSee('Dibutuhkan ART Masak Harian');
        $draftResponse->assertDontSee('Dibutuhkan Babysitter Balita');
    }

    /**
     * Test admin can view listing detail page for review without decision moderation box
     */
    public function test_admin_can_view_listing_detail(): void
    {
        $category = Category::create([
            'name' => 'Pengasuh Bayi',
            'slug' => 'babysitter',
            'icon' => 'baby',
        ]);

        $seeker = User::create([
            'name' => 'Ibu Ratna',
            'email' => 'ratna@pramu.id',
            'phone' => '081299991111',
            'password' => bcrypt('password'),
            'active_role' => 'seeker',
        ]);

        Verification::create([
            'user_id' => $seeker->id,
            'nik' => '3201019999990002',
            'ktp_path' => 'verifications/ktp_ratna.jpg',
            'selfie_path' => 'verifications/selfie_ratna.jpg',
            'status' => 'verified',
        ]);

        $listing = Listing::create([
            'user_id' => $seeker->id,
            'category_id' => $category->id,
            'title' => 'Pengasuh Bayi 1 Tahun Surabaya Timur',
            'description' => 'Membantu menjaga dan merawat bayi usia 1 tahun dengan sabar dan telaten.',
            'city_name' => 'Surabaya',
            'period_type' => 'monthly',
            'period_count' => 3,
            'billing_cycle' => 'monthly',
            'start_date' => now()->toDateString(),
            'budget_min' => 3000000,
            'budget_max' => 4500000,
            'require_skck' => true,
            'screening_questions' => ['Pernah merawat bayi usia 1 tahun?', 'Bersedia menginap?'],
            'status' => 'open',
            'paid_at' => now(),
        ]);

        $assistant = User::create([
            'name' => 'Siti Aminah',
            'email' => 'aminah@pramu.id',
            'phone' => '081244443333',
            'password' => bcrypt('password'),
            'active_role' => 'assistant',
        ]);

        AssistantProfile::create([
            'user_id' => $assistant->id,
            'experience_years' => 4,
            'rate_per_period' => 3500000,
            'period_type' => 'monthly',
            'bio' => 'Pengasuh anak bersertifikat.',
        ]);

        Application::create([
            'listing_id' => $listing->id,
            'user_id' => $assistant->id,
            'proposed_rate' => 3500000,
            'message' => 'Saya berpengalaman mengasuh bayi.',
            'status' => 'pending',
        ]);

        $response = $this->get("/admin/listings/{$listing->id}");

        $response->assertStatus(200);
        $response->assertSee('Pengasuh Bayi 1 Tahun Surabaya Timur');
        $response->assertSee('Ibu Ratna');
        $response->assertSee('Wajib SKCK Kepolisian');
        $response->assertSee('Pernah merawat bayi usia 1 tahun?');
        $response->assertSee('Siti Aminah');
        $response->assertSee('Iklan Lunas Rp25.000');
        $response->assertDontSee('Keputusan Peninjauan & Moderasi Admin');
        $response->assertDontSee('Tolak Lowongan...');
    }
}
