<?php

namespace Database\Seeders;

use App\Models\AssistantProfile;
use App\Models\Category;
use App\Models\Listing;
use App\Models\User;
use App\Models\UserRole;
use App\Models\Verification;
use App\Models\Wallet;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // 1. Categories
        $categories = [
            ['name' => 'Asisten Rumah Tangga', 'slug' => 'asisten-rumah-tangga', 'icon' => 'home'],
            ['name' => 'Pengasuh Anak (Baby Sitter)', 'slug' => 'pengasuh-anak', 'icon' => 'baby'],
            ['name' => 'Perawat Lansia', 'slug' => 'perawat-lansia', 'icon' => 'heart-pulse'],
            ['name' => 'Supir Pribadi', 'slug' => 'supir-pribadi', 'icon' => 'car'],
            ['name' => 'Tukang Kebun', 'slug' => 'tukang-kebun', 'icon' => 'flower2'],
        ];

        $categoryModels = [];
        foreach ($categories as $cat) {
            $categoryModels[$cat['slug']] = Category::firstOrCreate(['slug' => $cat['slug']], $cat);
        }

        // 2. Admin User
        $admin = User::firstOrCreate(
            ['email' => 'admin@pramu.id'],
            [
                'name' => 'Admin Pramu',
                'phone' => '081100000001',
                'password' => Hash::make('password123'),
                'active_role' => 'admin',
                'is_verified' => true,
                'status' => 'active',
            ]
        );
        UserRole::firstOrCreate(['user_id' => $admin->id, 'role' => 'admin']);

        // 3. Seeker User (Pencari Kerja / Majikan)
        $seeker = User::firstOrCreate(
            ['email' => 'pencari@pramu.id'],
            [
                'name' => 'Bu Rina Wulandari',
                'phone' => '081234567890',
                'password' => Hash::make('password123'),
                'active_role' => 'seeker',
                'is_verified' => true,
                'status' => 'active',
            ]
        );
        UserRole::firstOrCreate(['user_id' => $seeker->id, 'role' => 'seeker']);
        Verification::firstOrCreate(
            ['user_id' => $seeker->id],
            [
                'nik' => '3273010101900001',
                'ktp_path' => 'verifications/dummy_ktp_seeker.jpg',
                'selfie_path' => 'verifications/dummy_selfie_seeker.jpg',
                'status' => 'verified',
                'reviewed_at' => now(),
                'reviewed_by' => $admin->id,
            ]
        );

        // 4. Assistant User (Asisten Terverifikasi)
        $assistant = User::firstOrCreate(
            ['email' => 'asisten@pramu.id'],
            [
                'name' => 'Siti Rahmawati',
                'phone' => '081234567891',
                'password' => Hash::make('password123'),
                'active_role' => 'assistant',
                'is_verified' => true,
                'status' => 'active',
            ]
        );
        UserRole::firstOrCreate(['user_id' => $assistant->id, 'role' => 'assistant']);
        Verification::firstOrCreate(
            ['user_id' => $assistant->id],
            [
                'nik' => '3273010101950002',
                'ktp_path' => 'verifications/dummy_ktp_assistant.jpg',
                'selfie_path' => 'verifications/dummy_selfie_assistant.jpg',
                'status' => 'verified',
                'reviewed_at' => now(),
                'reviewed_by' => $admin->id,
            ]
        );
        AssistantProfile::firstOrCreate(
            ['user_id' => $assistant->id],
            [
                'category_ids' => [$categoryModels['asisten-rumah-tangga']->id, $categoryModels['pengasuh-anak']->id],
                'skills' => ['Memasak masakan rumahan', 'Mencuci & menyetrika', 'Merawat balita'],
                'experience_years' => 4,
                'rate_per_period' => 2500000,
                'period_type' => 'monthly',
                'city_id' => '3273',
                'city_name' => 'Kota Bandung',
                'availability_status' => 'available',
                'bio' => 'Berpengalaman bekerja sebagai ART dan pengasuh anak balita selama 4 tahun dengan kepribadian jujur, disiplin, dan teliti.',
            ]
        );
        Wallet::firstOrCreate(
            ['user_id' => $assistant->id],
            [
                'balance' => 0,
                'held_balance' => 0,
            ]
        );

        // 5. Unverified Assistant Demo (untuk pengujian review admin)
        $unverified = User::firstOrCreate(
            ['email' => 'joko@pramu.id'],
            [
                'name' => 'Joko Susanto',
                'phone' => '081234567892',
                'password' => Hash::make('password123'),
                'active_role' => 'assistant',
                'is_verified' => false,
                'status' => 'active',
            ]
        );
        UserRole::firstOrCreate(['user_id' => $unverified->id, 'role' => 'assistant']);
        Verification::firstOrCreate(
            ['user_id' => $unverified->id],
            [
                'nik' => '3273010101850003',
                'ktp_path' => 'verifications/dummy_ktp_joko.jpg',
                'selfie_path' => 'verifications/dummy_selfie_joko.jpg',
                'status' => 'pending',
            ]
        );
        AssistantProfile::firstOrCreate(
            ['user_id' => $unverified->id],
            [
                'category_ids' => [$categoryModels['supir-pribadi']->id],
                'skills' => ['Mengemudi mobil matic/manual', 'Paham rute Jabodetabek', 'SIM A aktif'],
                'experience_years' => 6,
                'rate_per_period' => 3000000,
                'period_type' => 'monthly',
                'city_id' => '3171',
                'city_name' => 'Jakarta Selatan',
                'availability_status' => 'available',
                'bio' => 'Supir pribadi berpengalaman rute dalam & luar kota.',
            ]
        );

        // 6. Sample Open Listing (Tayang)
        Listing::firstOrCreate(
            ['title' => 'Dibutuhkan ART Menginap di Bandung Kota'],
            [
                'user_id' => $seeker->id,
                'category_id' => $categoryModels['asisten-rumah-tangga']->id,
                'description' => 'Mencari ART harian/menginap untuk keluarga kecil dengan 1 anak. Tugas mencuci, menyetrika, dan membersihkan rumah.',
                'city_id' => '3273',
                'city_name' => 'Kota Bandung',
                'period_type' => 'monthly',
                'period_count' => 1,
                'billing_cycle' => 'monthly',
                'start_date' => now()->addDays(7)->toDateString(),
                'budget_min' => 2400000,
                'budget_max' => 2800000,
                'require_skck' => true,
                'screening_questions' => [
                    'Apakah bersedia menginap?',
                    'Apakah memiliki riwayat alergi terhadap kucing?',
                ],
                'status' => 'open',
                'paid_at' => now(),
                'expires_at' => now()->addDays(30),
            ]
        );
    }
}
