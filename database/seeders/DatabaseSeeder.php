<?php

namespace Database\Seeders;

use App\Models\Agreement;
use App\Models\Application;
use App\Models\AssistantProfile;
use App\Models\Booking;
use App\Models\BookingPeriod;
use App\Models\Category;
use App\Models\Interview;
use App\Models\Listing;
use App\Models\Report;
use App\Models\User;
use App\Models\UserRole;
use App\Models\Verification;
use App\Models\Wallet;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database with complete domain data.
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

        // 3. Seeker Users (Pencari Kerja / Majikan)
        $seekerRina = User::firstOrCreate(
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
        UserRole::firstOrCreate(['user_id' => $seekerRina->id, 'role' => 'seeker']);
        Verification::firstOrCreate(
            ['user_id' => $seekerRina->id],
            [
                'nik' => '3273010101900001',
                'ktp_path' => 'verifications/dummy_ktp_seeker.jpg',
                'selfie_path' => 'verifications/dummy_selfie_seeker.jpg',
                'status' => 'verified',
                'reviewed_at' => now()->subDays(10),
                'reviewed_by' => $admin->id,
            ]
        );

        $seekerHendra = User::firstOrCreate(
            ['email' => 'hendra@pramu.id'],
            [
                'name' => 'Pak Hendra Pratama',
                'phone' => '081234567893',
                'password' => Hash::make('password123'),
                'active_role' => 'seeker',
                'is_verified' => true,
                'status' => 'active',
            ]
        );
        UserRole::firstOrCreate(['user_id' => $seekerHendra->id, 'role' => 'seeker']);
        Verification::firstOrCreate(
            ['user_id' => $seekerHendra->id],
            [
                'nik' => '3471010101700004',
                'ktp_path' => 'verifications/dummy_ktp_hendra.jpg',
                'selfie_path' => 'verifications/dummy_selfie_hendra.jpg',
                'status' => 'verified',
                'reviewed_at' => now()->subDays(5),
                'reviewed_by' => $admin->id,
            ]
        );

        // 4. Assistant Users (Asisten Rumah Tangga)
        $assistantSiti = User::firstOrCreate(
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
        UserRole::firstOrCreate(['user_id' => $assistantSiti->id, 'role' => 'assistant']);
        Verification::firstOrCreate(
            ['user_id' => $assistantSiti->id],
            [
                'nik' => '3273010101950002',
                'ktp_path' => 'verifications/dummy_ktp_assistant.jpg',
                'selfie_path' => 'verifications/dummy_selfie_assistant.jpg',
                'status' => 'verified',
                'reviewed_at' => now()->subDays(12),
                'reviewed_by' => $admin->id,
            ]
        );
        AssistantProfile::firstOrCreate(
            ['user_id' => $assistantSiti->id],
            [
                'category_ids' => [$categoryModels['asisten-rumah-tangga']->id, $categoryModels['pengasuh-anak']->id],
                'skills' => ['Memasak masakan rumahan', 'Mencuci & menyetrika', 'Merawat balita'],
                'experience_years' => 4,
                'rate_per_period' => 2500000,
                'period_type' => 'monthly',
                'city_id' => '3273',
                'city_name' => 'Kota Bandung',
                'availability_status' => 'busy',
                'bio' => 'Berpengalaman bekerja sebagai ART dan pengasuh anak balita selama 4 tahun dengan kepribadian jujur, disiplin, dan teliti.',
            ]
        );
        $sitiWallet = Wallet::firstOrCreate(
            ['user_id' => $assistantSiti->id],
            [
                'balance' => 2375000, // Rp2.500.000 minus 5% fee (Rp125.000)
                'held_balance' => 2375000, // Periode ke-2 tertahan di escrow
            ]
        );

        // Pending Verification Users (Untuk Antrean Review Petugas)
        $unverifiedJoko = User::firstOrCreate(
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
        UserRole::firstOrCreate(['user_id' => $unverifiedJoko->id, 'role' => 'assistant']);
        Verification::firstOrCreate(
            ['user_id' => $unverifiedJoko->id],
            [
                'nik' => '3171010101850003',
                'ktp_path' => 'verifications/dummy_ktp_joko.jpg',
                'selfie_path' => 'verifications/dummy_selfie_joko.jpg',
                'status' => 'pending',
            ]
        );
        AssistantProfile::firstOrCreate(
            ['user_id' => $unverifiedJoko->id],
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

        $unverifiedAni = User::firstOrCreate(
            ['email' => 'ani@pramu.id'],
            [
                'name' => 'Ani Sulistiawati',
                'phone' => '081234567894',
                'password' => Hash::make('password123'),
                'active_role' => 'assistant',
                'is_verified' => false,
                'status' => 'active',
            ]
        );
        UserRole::firstOrCreate(['user_id' => $unverifiedAni->id, 'role' => 'assistant']);
        Verification::firstOrCreate(
            ['user_id' => $unverifiedAni->id],
            [
                'nik' => '3578010101980005',
                'ktp_path' => 'verifications/dummy_ktp_ani.jpg',
                'selfie_path' => 'verifications/dummy_selfie_ani.jpg',
                'status' => 'pending',
            ]
        );
        AssistantProfile::firstOrCreate(
            ['user_id' => $unverifiedAni->id],
            [
                'category_ids' => [$categoryModels['pengasuh-anak']->id],
                'skills' => ['Pendidikan D3 Kebidanan', 'Sertifikat First Aid Balita', 'Montessori Dasar'],
                'experience_years' => 3,
                'rate_per_period' => 3200000,
                'period_type' => 'monthly',
                'city_id' => '3578',
                'city_name' => 'Kota Surabaya',
                'availability_status' => 'available',
                'bio' => 'Pengasuh anak bersertifikat siap mendampingi tumbuh kembang anak dengan sabar dan telaten.',
            ]
        );

        // 5. Listings (Lowongan Kerja)
        $listingBandung = Listing::firstOrCreate(
            ['title' => 'Dibutuhkan ART Menginap di Bandung Kota'],
            [
                'user_id' => $seekerRina->id,
                'category_id' => $categoryModels['asisten-rumah-tangga']->id,
                'description' => 'Mencari ART menginap untuk keluarga kecil dengan 1 balita. Tugas memasak, mencuci, dan membersihkan rumah.',
                'city_id' => '3273',
                'city_name' => 'Kota Bandung',
                'period_type' => 'monthly',
                'period_count' => 3,
                'billing_cycle' => 'monthly',
                'start_date' => now()->subMonth()->toDateString(),
                'budget_min' => 2400000,
                'budget_max' => 2800000,
                'require_skck' => true,
                'screening_questions' => [
                    'Apakah bersedia menginap?',
                    'Apakah memiliki riwayat alergi kucing?',
                ],
                'status' => 'filled',
                'paid_at' => now()->subMonth(),
                'expires_at' => now()->addDays(20),
            ]
        );

        $listingJogja = Listing::firstOrCreate(
            ['title' => 'Perawat Lansia Harian di Yogyakarta'],
            [
                'user_id' => $seekerHendra->id,
                'category_id' => $categoryModels['perawat-lansia']->id,
                'description' => 'Mencarikan perawat lansia untuk orang tua usia 78 tahun. Jam kerja 08.00 - 16.00 WIB. Membantu mobilitas dan minum obat.',
                'city_id' => '3471',
                'city_name' => 'Kota Yogyakarta',
                'period_type' => 'monthly',
                'period_count' => 1,
                'billing_cycle' => 'monthly',
                'start_date' => now()->addDays(5)->toDateString(),
                'budget_min' => 2800000,
                'budget_max' => 3500000,
                'require_skck' => true,
                'screening_questions' => [
                    'Apakah memiliki pengalaman merawat pasien pasca stroke?',
                    'Bisa mengukur tensi darah mandiri?',
                ],
                'status' => 'open',
                'paid_at' => now()->subDays(2),
                'expires_at' => now()->addDays(28),
            ]
        );

        // 6. Application & Google Meet Interview
        $applicationJogja = Application::firstOrCreate(
            ['listing_id' => $listingJogja->id, 'user_id' => $assistantSiti->id],
            [
                'message' => 'Selamat siang Pak Hendra, saya memiliki pengalaman merawat lansia selama 2 tahun dan memiliki sertifikat dasar keperawatan.',
                'proposed_rate' => 3000000,
                'answers' => [
                    'Pernah merawat pasien lansia selama 2 tahun',
                    'Bisa mengukur tensi darah digital dan manual',
                ],
                'status' => 'interview_scheduled',
            ]
        );

        Interview::firstOrCreate(
            ['application_id' => $applicationJogja->id],
            [
                'proposed_slots' => [now()->addDay()->setHour(10)->setMinute(0)->toIso8601String()],
                'confirmed_slot' => now()->addDay()->setHour(10)->setMinute(0),
                'meeting_url' => 'https://meet.google.com/qrs-tuvw-xyz',
                'status' => 'confirmed',
                'notes' => 'Pelamar memiliki pengalaman relevan, tanyakan jadwal mulai kerja.',
            ]
        );

        // 7. Active Contract / Booking with Escrow Periods (Siti & Rina)
        $appBandung = Application::firstOrCreate(
            ['listing_id' => $listingBandung->id, 'user_id' => $assistantSiti->id],
            [
                'message' => 'Saya siap bekerja menginap dan sudah terbiasa dengan anak balita.',
                'proposed_rate' => 2500000,
                'answers' => ['Bersedia menginap', 'Tidak ada alergi'],
                'status' => 'accepted',
            ]
        );

        $agreement = Agreement::firstOrCreate(
            ['application_id' => $appBandung->id],
            [
                'version' => 1,
                'proposed_by_user_id' => $seekerRina->id,
                'rate_per_period' => 2500000,
                'period_type' => 'monthly',
                'period_count' => 3,
                'billing_cycle' => 'monthly',
                'start_date' => now()->subMonth()->toDateString(),
                'seeker_approved_at' => now()->subMonth(),
                'assistant_approved_at' => now()->subMonth(),
                'status' => 'approved',
            ]
        );

        $booking = Booking::firstOrCreate(
            ['agreement_id' => $agreement->id],
            [
                'seeker_id' => $seekerRina->id,
                'assistant_id' => $assistantSiti->id,
                'listing_id' => $listingBandung->id,
                'total_amount' => 7500000, // 3 x Rp2.500.000
                'status' => 'active',
            ]
        );

        // Period 1: Selesai & Dicairkan (Settled)
        BookingPeriod::firstOrCreate(
            ['booking_id' => $booking->id, 'period_number' => 1],
            [
                'amount' => 2500000,
                'seeker_fee' => 125000,
                'assistant_fee' => 125000,
                'total_to_pay' => 2625000,
                'total_payout' => 2375000,
                'due_date' => now()->subMonth()->toDateString(),
                'status' => 'settled',
                'invoice_id' => 'inv_period_1_completed',
                'paid_at' => now()->subMonth(),
                'completed_at' => now()->subDays(2),
                'settled_at' => now()->subDays(2),
            ]
        );

        // Period 2: Sedang Berjalan & Dana Ditahan Aman di Escrow
        BookingPeriod::firstOrCreate(
            ['booking_id' => $booking->id, 'period_number' => 2],
            [
                'amount' => 2500000,
                'seeker_fee' => 125000,
                'assistant_fee' => 125000,
                'total_to_pay' => 2625000,
                'total_payout' => 2375000,
                'due_date' => now()->toDateString(),
                'status' => 'paid', // Dana ditahan di escrow
                'invoice_id' => 'inv_period_2_active',
                'paid_at' => now()->subDays(1),
                'auto_release_at' => now()->addDays(29),
            ]
        );

        // Period 3: Menunggu Pembayaran Bulan Depan
        BookingPeriod::firstOrCreate(
            ['booking_id' => $booking->id, 'period_number' => 3],
            [
                'amount' => 2500000,
                'seeker_fee' => 125000,
                'assistant_fee' => 125000,
                'total_to_pay' => 2625000,
                'total_payout' => 2375000,
                'due_date' => now()->addMonth()->toDateString(),
                'status' => 'awaiting_payment',
            ]
        );

        // 8. Sample Dispute Report
        Report::firstOrCreate(
            ['reporter_id' => $seekerRina->id, 'reported_id' => $unverifiedJoko->id],
            [
                'booking_id' => null,
                'category' => 'behavior',
                'description' => 'Pelamar membatalkan janji wawancara secara sepihak dan meminta transfer uang muka di luar aplikasi sebelum memulai kerja.',
                'evidence_paths' => ['reports/chat_screenshot_01.jpg'],
                'share_chat_consent' => true,
                'consent_expires_at' => now()->addDays(6),
                'status' => 'under_review',
                'decision' => null,
            ]
        );
    }
}
