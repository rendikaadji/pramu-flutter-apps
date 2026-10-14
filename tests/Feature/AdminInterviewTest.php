<?php

namespace Tests\Feature;

use App\Models\Application;
use App\Models\Category;
use App\Models\Interview;
use App\Models\Listing;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AdminInterviewTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Test interview model supports helper to create valid formatted Google Meet URL
     */
    public function test_interview_model_supports_generating_google_meet_url(): void
    {
        $url = Interview::generateMeetingUrl();

        $this->assertNotEmpty($url);
        $this->assertStringStartsWith('https://meet.google.com/', $url);
        $this->assertMatchesRegularExpression('/^https:\/\/meet\.google\.com\/[a-z]{3}-[a-z]{4}-[a-z]{3}$/', $url);
    }

    /**
     * Test admin can view interviews list with meeting links and confirmed slots
     */
    public function test_admin_can_view_interviews_list_with_meeting_link(): void
    {
        $category = Category::create([
            'name' => 'Pengasuh Bayi',
            'slug' => 'babysitter-meet',
            'icon' => 'baby',
        ]);

        $seeker = User::create([
            'name' => 'Ibu Maya',
            'email' => 'maya@pramu.id',
            'phone' => '081277779999',
            'password' => bcrypt('password'),
            'active_role' => 'seeker',
        ]);

        $assistant = User::create([
            'name' => 'Anisa Rahma',
            'email' => 'anisa@pramu.id',
            'phone' => '081288882222',
            'password' => bcrypt('password'),
            'active_role' => 'assistant',
        ]);

        $listing = Listing::create([
            'user_id' => $seeker->id,
            'category_id' => $category->id,
            'title' => 'Pengasuh Balita Cekatan',
            'description' => 'Mengasuh balita.',
            'city_name' => 'Jakarta Selatan',
            'period_type' => 'monthly',
            'period_count' => 1,
            'billing_cycle' => 'monthly',
            'start_date' => now()->toDateString(),
            'budget_min' => 3000000,
            'budget_max' => 4000000,
            'status' => 'open',
        ]);

        $application = Application::create([
            'listing_id' => $listing->id,
            'user_id' => $assistant->id,
            'proposed_rate' => 3000000,
            'status' => 'interview_scheduled',
        ]);

        $interview = Interview::create([
            'application_id' => $application->id,
            'proposed_slots' => [now()->addDays(2)->setHour(14)->setMinute(0)->toIso8601String()],
            'confirmed_slot' => now()->addDays(2)->setHour(14)->setMinute(0),
            'meeting_url' => 'https://meet.google.com/abc-defg-hij',
            'status' => 'confirmed',
        ]);

        $response = $this->get('/admin/interviews');

        $response->assertStatus(200);
        $response->assertSee('Anisa Rahma');
        $response->assertSee('Ibu Maya');
        $response->assertSee('CONFIRMED');
        $response->assertSee('https://meet.google.com/abc-defg-hij');
        $response->assertSee('Masuk Meet');
    }

    /**
     * Test admin can update interview meeting link, confirmed slot, and status
     */
    public function test_admin_can_update_interview_meeting_link_and_schedule(): void
    {
        $category = Category::create([
            'name' => 'ART',
            'slug' => 'art-slot',
            'icon' => 'home',
        ]);

        $seeker = User::create([
            'name' => 'Pak Hendra',
            'email' => 'hendra@pramu.id',
            'phone' => '081233334444',
            'password' => bcrypt('password'),
            'active_role' => 'seeker',
        ]);

        $assistant = User::create([
            'name' => 'Siti Aminah',
            'email' => 'siti@pramu.id',
            'phone' => '081255556666',
            'password' => bcrypt('password'),
            'active_role' => 'assistant',
        ]);

        $listing = Listing::create([
            'user_id' => $seeker->id,
            'category_id' => $category->id,
            'title' => 'ART Harian Rawat Rumah',
            'description' => 'Membersihkan rumah.',
            'city_name' => 'Bandung',
            'period_type' => 'monthly',
            'period_count' => 1,
            'billing_cycle' => 'monthly',
            'start_date' => now()->toDateString(),
            'budget_min' => 2000000,
            'budget_max' => 2500000,
            'status' => 'open',
        ]);

        $application = Application::create([
            'listing_id' => $listing->id,
            'user_id' => $assistant->id,
            'proposed_rate' => 2200000,
            'status' => 'interview_scheduled',
        ]);

        $interview = Interview::create([
            'application_id' => $application->id,
            'proposed_slots' => [now()->addDay()->toIso8601String()],
            'meeting_url' => null,
            'status' => 'proposed',
        ]);

        $response = $this->post("/admin/interviews/{$interview->id}/update", [
            'meeting_url' => 'https://zoom.us/j/9876543210',
            'confirmed_slot' => now()->addDays(3)->format('Y-m-d H:i:s'),
            'status' => 'confirmed',
            'notes' => 'Diubah admin atas permintaan majikan',
        ]);

        $response->assertRedirect();
        $interview->refresh();

        $this->assertEquals('https://zoom.us/j/9876543210', $interview->meeting_url);
        $this->assertEquals('confirmed', $interview->status);
        $this->assertEquals('Diubah admin atas permintaan majikan', $interview->notes);
    }

    /**
     * Test seeker (employer) can schedule interview and submit meeting link via API
     */
    public function test_seeker_can_schedule_interview_and_provide_meeting_link_via_api(): void
    {
        $category = Category::create([
            'name' => 'Tukang Kebun',
            'slug' => 'gardener',
            'icon' => 'flower',
        ]);

        $seeker = User::create([
            'name' => 'Pak Ridwan',
            'email' => 'ridwan@pramu.id',
            'phone' => '081277771111',
            'password' => bcrypt('password'),
            'active_role' => 'seeker',
            'is_verified' => true,
        ]);

        $assistant = User::create([
            'name' => 'Budi Susanto',
            'email' => 'budi@pramu.id',
            'phone' => '081299993333',
            'password' => bcrypt('password'),
            'active_role' => 'assistant',
            'is_verified' => true,
        ]);

        $listing = Listing::create([
            'user_id' => $seeker->id,
            'category_id' => $category->id,
            'title' => 'Tukang Kebun Rumah',
            'description' => 'Merawat taman.',
            'city_name' => 'Bogor',
            'period_type' => 'monthly',
            'period_count' => 1,
            'billing_cycle' => 'monthly',
            'start_date' => now()->toDateString(),
            'budget_min' => 2000000,
            'budget_max' => 2500000,
            'status' => 'open',
        ]);

        $application = Application::create([
            'listing_id' => $listing->id,
            'user_id' => $assistant->id,
            'proposed_rate' => 2000000,
            'status' => 'shortlisted',
        ]);

        Sanctum::actingAs($seeker);

        $response = $this->postJson("/api/v1/applications/{$application->id}/schedule-interview", [
            'meeting_url' => 'https://meet.google.com/xyz-uvwx-rst',
            'scheduled_at' => now()->addDays(2)->format('Y-m-d H:i:s'),
            'notes' => 'Silakan siapkan pengenalan diri singkat',
        ]);

        $response->assertStatus(200);
        $response->assertJsonPath('data.interview.meeting_url', 'https://meet.google.com/xyz-uvwx-rst');
        $response->assertJsonPath('data.application_status', 'interview_scheduled');

        $this->assertDatabaseHas('interviews', [
            'application_id' => $application->id,
            'meeting_url' => 'https://meet.google.com/xyz-uvwx-rst',
            'status' => 'confirmed',
        ]);
    }

    /**
     * Test admin can trigger generate Google Meet action fallback
     */
    public function test_admin_can_generate_google_meet_url(): void
    {
        $category = Category::create([
            'name' => 'Supir',
            'slug' => 'driver-meet',
            'icon' => 'car',
        ]);

        $seeker = User::create([
            'name' => 'Pak Bambang',
            'email' => 'bambang@pramu.id',
            'phone' => '081266661111',
            'password' => bcrypt('password'),
            'active_role' => 'seeker',
        ]);

        $assistant = User::create([
            'name' => 'Agus Santoso',
            'email' => 'agus@pramu.id',
            'phone' => '081299994444',
            'password' => bcrypt('password'),
            'active_role' => 'assistant',
        ]);

        $listing = Listing::create([
            'user_id' => $seeker->id,
            'category_id' => $category->id,
            'title' => 'Sopir Pribadi Kantor',
            'description' => 'Sopir kantor harian.',
            'city_name' => 'Surabaya',
            'period_type' => 'monthly',
            'period_count' => 1,
            'billing_cycle' => 'monthly',
            'start_date' => now()->toDateString(),
            'budget_min' => 3500000,
            'budget_max' => 4500000,
            'status' => 'open',
        ]);

        $application = Application::create([
            'listing_id' => $listing->id,
            'user_id' => $assistant->id,
            'proposed_rate' => 3500000,
            'status' => 'interview_scheduled',
        ]);

        $interview = Interview::create([
            'application_id' => $application->id,
            'proposed_slots' => [now()->addDay()->toIso8601String()],
            'meeting_url' => 'https://meet.google.com/old-link-test',
            'status' => 'proposed',
        ]);

        $response = $this->post("/admin/interviews/{$interview->id}/generate-meet");

        $response->assertRedirect();
        $interview->refresh();

        $this->assertNotEmpty($interview->meeting_url);
        $this->assertNotEquals('https://meet.google.com/old-link-test', $interview->meeting_url);
        $this->assertStringStartsWith('https://meet.google.com/', $interview->meeting_url);
        $this->assertEquals('confirmed', $interview->status);
    }
}
