<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ExampleTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Test root redirects to admin panel
     */
    public function test_root_redirects_to_admin(): void
    {
        $response = $this->get('/');
        $response->assertRedirect('/admin');
    }

    /**
     * Test admin dashboard loads successfully
     */
    public function test_admin_dashboard_loads(): void
    {
        $response = $this->get('/admin');
        $response->assertStatus(200);
        $response->assertSee('Pramu');
        $response->assertSee('Escrow');
    }

    /**
     * Test API listings returns envelope format
     */
    public function test_api_listings_returns_envelope(): void
    {
        $response = $this->getJson('/api/v1/listings');
        $response->assertStatus(200);
        $response->assertJsonStructure([
            'data',
            'meta' => [
                'current_page',
                'last_page',
                'per_page',
                'total',
            ],
        ]);
    }

    /**
     * Test API invalid login returns standard error envelope
     */
    public function test_api_invalid_login_returns_error_envelope(): void
    {
        $response = $this->postJson('/api/v1/auth/login', [
            'login' => 'user_salah@pramu.id',
            'password' => 'passwordsalah123',
        ]);

        $response->assertStatus(401);
        $response->assertJsonStructure([
            'error' => [
                'code',
                'message',
                'fields',
            ],
        ]);
        $response->assertJson([
            'error' => [
                'code' => 'INVALID_CREDENTIALS',
            ],
        ]);
    }

    /**
     * Test all admin sidebar navigation routes load successfully (200 OK)
     */
    public function test_all_admin_sidebar_routes_load_successfully(): void
    {
        $routes = [
            '/admin',
            '/admin/verifications',
            '/admin/users',
            '/admin/listings',
            '/admin/interviews',
            '/admin/bookings',
            '/admin/finances',
            '/admin/reports',
        ];

        foreach ($routes as $route) {
            $response = $this->get($route);
            $response->assertStatus(200);
            $response->assertSee('Pramu');
        }
    }

    /**
     * Test removed system route redirects safely to /admin instead of returning 404
     */
    public function test_removed_system_route_redirects_to_admin(): void
    {
        $response = $this->get('/admin/system');
        $response->assertRedirect('/admin');

        $responseRoot = $this->get('/system');
        $responseRoot->assertRedirect('/admin');
    }
}
