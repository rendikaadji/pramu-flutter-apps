<?php

namespace Tests\Feature;

use App\Models\Report;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminReportTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Test admin can view reports submitted by an assistant
     */
    public function test_admin_can_filter_reports_submitted_by_assistant(): void
    {
        $assistantUser = User::create([
            'name' => 'Dewi Asisten',
            'email' => 'dewi@pramu.id',
            'phone' => '081233334444',
            'password' => bcrypt('password'),
            'active_role' => 'assistant',
        ]);

        $seekerUser = User::create([
            'name' => 'Agus Majikan',
            'email' => 'agus@pramu.id',
            'phone' => '081255556666',
            'password' => bcrypt('password'),
            'active_role' => 'seeker',
        ]);

        // Report filed by Assistant against Seeker
        Report::create([
            'reporter_id' => $assistantUser->id,
            'reported_id' => $seekerUser->id,
            'category' => 'payment',
            'description' => 'Gaji lembur belum dibayarkan oleh majikan.',
            'status' => 'submitted',
        ]);

        // Report filed by Seeker against Assistant
        Report::create([
            'reporter_id' => $seekerUser->id,
            'reported_id' => $assistantUser->id,
            'category' => 'behavior',
            'description' => 'Asisten tidak masuk kerja tanpa kabar.',
            'status' => 'submitted',
        ]);

        $response = $this->get('/admin/reports?role=assistant');

        $response->assertStatus(200);
        $response->assertSee('Gaji lembur belum dibayarkan');
        $response->assertDontSee('tidak masuk kerja tanpa kabar');
        $response->assertSee('Laporan dari Asisten');
        $response->assertSee('Dewi Asisten');
    }

    /**
     * Test admin can view reports submitted by a seeker
     */
    public function test_admin_can_filter_reports_submitted_by_seeker(): void
    {
        $assistantUser = User::create([
            'name' => 'Dewi Asisten',
            'email' => 'dewi@pramu.id',
            'phone' => '081233334444',
            'password' => bcrypt('password'),
            'active_role' => 'assistant',
        ]);

        $seekerUser = User::create([
            'name' => 'Agus Majikan',
            'email' => 'agus@pramu.id',
            'phone' => '081255556666',
            'password' => bcrypt('password'),
            'active_role' => 'seeker',
        ]);

        Report::create([
            'reporter_id' => $assistantUser->id,
            'reported_id' => $seekerUser->id,
            'category' => 'payment',
            'description' => 'Gaji lembur belum dibayarkan oleh majikan.',
            'status' => 'submitted',
        ]);

        Report::create([
            'reporter_id' => $seekerUser->id,
            'reported_id' => $assistantUser->id,
            'category' => 'behavior',
            'description' => 'Asisten tidak masuk kerja tanpa kabar.',
            'status' => 'submitted',
        ]);

        $response = $this->get('/admin/reports?role=seeker');

        $response->assertStatus(200);
        $response->assertSee('tidak masuk kerja tanpa kabar');
        $response->assertDontSee('Gaji lembur belum dibayarkan');
        $response->assertSee('Laporan dari Pencari (Majikan)');
        $response->assertSee('Agus Majikan');
    }

    /**
     * Test admin sidebar shows reporter role sub-menu items
     */
    public function test_sidebar_and_page_render_assistant_and_seeker_report_filters(): void
    {
        $assistantUser = User::create([
            'name' => 'Dewi Asisten',
            'email' => 'dewi@pramu.id',
            'phone' => '081233334444',
            'password' => bcrypt('password'),
            'active_role' => 'assistant',
        ]);

        $seekerUser = User::create([
            'name' => 'Agus Majikan',
            'email' => 'agus@pramu.id',
            'phone' => '081255556666',
            'password' => bcrypt('password'),
            'active_role' => 'seeker',
        ]);

        Report::create([
            'reporter_id' => $assistantUser->id,
            'reported_id' => $seekerUser->id,
            'category' => 'payment',
            'description' => 'Gaji lembur belum dibayarkan.',
            'status' => 'submitted',
        ]);

        $response = $this->get('/admin/reports');

        $response->assertStatus(200);
        $response->assertSee('Dari Asisten (ART)');
        $response->assertSee('Dari Pencari (Majikan)');
        $response->assertSee('role=assistant');
        $response->assertSee('role=seeker');
    }

    /**
     * Test admin can resolve report
     */
    public function test_admin_can_resolve_report(): void
    {
        $assistantUser = User::create([
            'name' => 'Dewi Asisten',
            'email' => 'dewi@pramu.id',
            'phone' => '081233334444',
            'password' => bcrypt('password'),
            'active_role' => 'assistant',
        ]);

        $seekerUser = User::create([
            'name' => 'Agus Majikan',
            'email' => 'agus@pramu.id',
            'phone' => '081255556666',
            'password' => bcrypt('password'),
            'active_role' => 'seeker',
        ]);

        $report = Report::create([
            'reporter_id' => $assistantUser->id,
            'reported_id' => $seekerUser->id,
            'category' => 'payment',
            'description' => 'Gaji lembur belum dibayarkan.',
            'status' => 'submitted',
        ]);

        $response = $this->post("/admin/reports/{$report->id}/resolve", [
            'decision' => 'Majikan diinstruksikan mentransfer kompensasi lembur.',
        ]);

        $response->assertRedirect('/admin/reports');
        $this->assertDatabaseHas('reports', [
            'id' => $report->id,
            'status' => 'resolved',
            'decision' => 'Majikan diinstruksikan mentransfer kompensasi lembur.',
        ]);
    }
}
