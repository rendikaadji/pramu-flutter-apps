<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Verification;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminVerificationTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Test admin can filter verifications by assistant role
     */
    public function test_admin_can_filter_verifications_by_assistant_role(): void
    {
        $assistantUser = User::create([
            'name' => 'Siti Asisten',
            'email' => 'siti@pramu.id',
            'phone' => '081234567890',
            'password' => bcrypt('password'),
            'active_role' => 'assistant',
        ]);

        $seekerUser = User::create([
            'name' => 'Budi Majikan',
            'email' => 'budi@pramu.id',
            'phone' => '081298765432',
            'password' => bcrypt('password'),
            'active_role' => 'seeker',
        ]);

        Verification::create([
            'user_id' => $assistantUser->id,
            'nik' => '3201010101010001',
            'ktp_path' => 'verifications/ktp1.jpg',
            'selfie_path' => 'verifications/selfie1.jpg',
            'status' => 'pending',
        ]);

        Verification::create([
            'user_id' => $seekerUser->id,
            'nik' => '3201010101010002',
            'ktp_path' => 'verifications/ktp2.jpg',
            'selfie_path' => 'verifications/selfie2.jpg',
            'status' => 'pending',
        ]);

        $response = $this->get('/admin/verifications?status=pending&role=assistant');

        $response->assertStatus(200);
        $response->assertSee('Siti Asisten');
        $response->assertDontSee('Budi Majikan');
        $response->assertSee('3201010101010001');
        $response->assertDontSee('3201010101010002');
    }

    /**
     * Test admin can filter verifications by seeker role
     */
    public function test_admin_can_filter_verifications_by_seeker_role(): void
    {
        $assistantUser = User::create([
            'name' => 'Siti Asisten',
            'email' => 'siti@pramu.id',
            'phone' => '081234567890',
            'password' => bcrypt('password'),
            'active_role' => 'assistant',
        ]);

        $seekerUser = User::create([
            'name' => 'Budi Majikan',
            'email' => 'budi@pramu.id',
            'phone' => '081298765432',
            'password' => bcrypt('password'),
            'active_role' => 'seeker',
        ]);

        Verification::create([
            'user_id' => $assistantUser->id,
            'nik' => '3201010101010001',
            'ktp_path' => 'verifications/ktp1.jpg',
            'selfie_path' => 'verifications/selfie1.jpg',
            'status' => 'pending',
        ]);

        Verification::create([
            'user_id' => $seekerUser->id,
            'nik' => '3201010101010002',
            'ktp_path' => 'verifications/ktp2.jpg',
            'selfie_path' => 'verifications/selfie2.jpg',
            'status' => 'pending',
        ]);

        $response = $this->get('/admin/verifications?status=pending&role=seeker');

        $response->assertStatus(200);
        $response->assertSee('Budi Majikan');
        $response->assertDontSee('Siti Asisten');
        $response->assertSee('3201010101010002');
        $response->assertDontSee('3201010101010001');
    }

    /**
     * Test admin sidebar and page display role filter items and counts
     */
    public function test_admin_sidebar_and_page_display_role_filter_items(): void
    {
        $assistantUser = User::create([
            'name' => 'Siti Asisten',
            'email' => 'siti@pramu.id',
            'phone' => '081234567890',
            'password' => bcrypt('password'),
            'active_role' => 'assistant',
        ]);

        Verification::create([
            'user_id' => $assistantUser->id,
            'nik' => '3201010101010001',
            'ktp_path' => 'verifications/ktp1.jpg',
            'selfie_path' => 'verifications/selfie1.jpg',
            'status' => 'pending',
        ]);

        $response = $this->get('/admin/verifications');

        $response->assertStatus(200);
        $response->assertSee('Peran Asisten');
        $response->assertSee('Peran Pencari');
        $response->assertSee('role=assistant');
        $response->assertSee('role=seeker');
    }
}
