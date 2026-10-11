<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // 1. Roles per User
        Schema::create('user_roles', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('user_id')->constrained()->cascadeOnDelete();
            $table->string('role'); // seeker, assistant, admin
            $table->timestamps();
            $table->unique(['user_id', 'role']);
        });

        // 2. OTP Verification
        Schema::create('otps', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->string('phone')->index();
            $table->string('code', 6);
            $table->integer('attempts')->default(0);
            $table->timestamp('expires_at');
            $table->timestamp('verified_at')->nullable();
            $table->timestamps();
        });

        // 3. User Verifications (KTP + Selfie)
        Schema::create('verifications', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('user_id')->unique()->constrained()->cascadeOnDelete();
            $table->string('nik', 16)->index();
            $table->string('ktp_path');
            $table->string('selfie_path');
            $table->string('status')->default('pending'); // pending, verified, rejected
            $table->text('rejection_reason')->nullable();
            $table->timestamp('reviewed_at')->nullable();
            $table->foreignUlid('reviewed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
        });

        // 4. SKCK Documents
        Schema::create('skcks', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('user_id')->constrained()->cascadeOnDelete();
            $table->string('file_path');
            $table->string('status')->default('pending'); // pending, verified, rejected
            $table->text('rejection_reason')->nullable();
            $table->timestamp('reviewed_at')->nullable();
            $table->timestamps();
        });

        // 5. Job Categories
        Schema::create('categories', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->string('name');
            $table->string('slug')->unique();
            $table->string('icon')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        // 6. Assistant Profiles
        Schema::create('assistant_profiles', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('user_id')->unique()->constrained()->cascadeOnDelete();
            $table->json('category_ids')->nullable();
            $table->json('skills')->nullable();
            $table->integer('experience_years')->default(0);
            $table->unsignedBigInteger('rate_per_period')->default(0); // in Rupiah
            $table->string('period_type')->default('monthly'); // hourly, daily, weekly, monthly
            $table->string('city_id')->nullable()->index();
            $table->string('city_name')->nullable();
            $table->string('availability_status')->default('available'); // available, busy, not_available
            $table->text('bio')->nullable();
            $table->timestamps();
        });

        // 7. Listings (Job Posts by Seeker)
        Schema::create('listings', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('user_id')->constrained()->cascadeOnDelete();
            $table->foreignUlid('category_id')->constrained()->cascadeOnDelete();
            $table->string('title');
            $table->text('description');
            $table->string('city_id')->nullable()->index();
            $table->string('city_name')->nullable();
            $table->string('period_type')->default('monthly');
            $table->integer('period_count')->default(1);
            $table->string('billing_cycle')->default('monthly');
            $table->date('start_date');
            $table->unsignedBigInteger('budget_min'); // in Rupiah
            $table->unsignedBigInteger('budget_max'); // in Rupiah
            $table->boolean('require_skck')->default(false);
            $table->json('screening_questions')->nullable();
            $table->string('status')->default('draft'); // draft, awaiting_payment, open, filled, closed, expired
            $table->string('listing_fee_invoice_id')->nullable();
            $table->string('listing_fee_invoice_url')->nullable();
            $table->timestamp('paid_at')->nullable();
            $table->timestamp('expires_at')->nullable();
            $table->timestamps();
        });

        // 8. Applications (Job Applications by Assistant)
        Schema::create('applications', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('listing_id')->constrained()->cascadeOnDelete();
            $table->foreignUlid('user_id')->constrained()->cascadeOnDelete();
            $table->text('message')->nullable();
            $table->unsignedBigInteger('proposed_rate'); // in Rupiah
            $table->json('answers')->nullable();
            $table->string('status')->default('pending'); // pending, shortlisted, interview_scheduled, interviewed, accepted, rejected, withdrawn
            $table->text('rejection_reason')->nullable();
            $table->timestamps();
            $table->unique(['listing_id', 'user_id']);
        });

        // 9. Interviews
        Schema::create('interviews', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('application_id')->constrained()->cascadeOnDelete();
            $table->json('proposed_slots');
            $table->dateTime('confirmed_slot')->nullable();
            $table->string('meeting_url')->nullable();
            $table->text('notes')->nullable(); // Private to seeker
            $table->tinyInteger('communication_score')->nullable(); // 1-5
            $table->tinyInteger('politeness_score')->nullable(); // 1-5
            $table->tinyInteger('reliability_score')->nullable(); // 1-5
            $table->string('status')->default('proposed'); // proposed, confirmed, done, cancelled, no_show
            $table->timestamps();
        });

        // 10. Agreements (Kesepakatan Dua Arah)
        Schema::create('agreements', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('application_id')->constrained()->cascadeOnDelete();
            $table->integer('version')->default(1);
            $table->foreignUlid('proposed_by_user_id')->constrained('users')->cascadeOnDelete();
            $table->unsignedBigInteger('rate_per_period'); // in Rupiah
            $table->string('period_type')->default('monthly');
            $table->integer('period_count')->default(1);
            $table->string('billing_cycle')->default('monthly');
            $table->date('start_date');
            $table->timestamp('seeker_approved_at')->nullable();
            $table->timestamp('assistant_approved_at')->nullable();
            $table->string('status')->default('proposed'); // proposed, countered, approved, rejected
            $table->timestamps();
        });

        // 11. Bookings (Kontrak)
        Schema::create('bookings', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('agreement_id')->constrained()->cascadeOnDelete();
            $table->foreignUlid('seeker_id')->constrained('users')->cascadeOnDelete();
            $table->foreignUlid('assistant_id')->constrained('users')->cascadeOnDelete();
            $table->foreignUlid('listing_id')->constrained()->cascadeOnDelete();
            $table->unsignedBigInteger('total_amount'); // in Rupiah
            $table->string('status')->default('active'); // active, paused, completed, cancelled, disputed
            $table->timestamps();
        });

        // 12. Booking Periods (Escrow / Termin Kerja)
        Schema::create('booking_periods', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('booking_id')->constrained()->cascadeOnDelete();
            $table->integer('period_number');
            $table->unsignedBigInteger('amount'); // Nominal gaji periode
            $table->unsignedBigInteger('seeker_fee'); // 5% fee layanan pencari
            $table->unsignedBigInteger('assistant_fee'); // 5% fee layanan asisten
            $table->unsignedBigInteger('total_to_pay'); // amount + seeker_fee
            $table->unsignedBigInteger('total_payout'); // amount - assistant_fee
            $table->date('due_date');
            $table->string('status')->default('awaiting_payment'); // awaiting_payment, paid, in_progress, awaiting_confirmation, completed, settled, expired, cancelled, disputed
            $table->string('invoice_id')->nullable();
            $table->string('invoice_url')->nullable();
            $table->string('idempotency_key')->nullable()->index();
            $table->timestamp('paid_at')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->timestamp('auto_release_at')->nullable();
            $table->timestamp('settled_at')->nullable();
            $table->timestamps();
        });

        // 13. Assistant Wallets
        Schema::create('wallets', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('user_id')->unique()->constrained()->cascadeOnDelete();
            $table->unsignedBigInteger('balance')->default(0); // Rupiah
            $table->unsignedBigInteger('held_balance')->default(0); // Rupiah
            $table->timestamps();
        });

        // 14. Bank Accounts
        Schema::create('bank_accounts', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('user_id')->constrained()->cascadeOnDelete();
            $table->string('bank_code');
            $table->string('bank_name');
            $table->string('account_number');
            $table->string('account_holder_name');
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        // 15. Payouts (Penarikan Dana)
        Schema::create('payouts', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('wallet_id')->constrained()->cascadeOnDelete();
            $table->foreignUlid('bank_account_id')->constrained()->cascadeOnDelete();
            $table->unsignedBigInteger('amount'); // in Rupiah
            $table->string('status')->default('queued'); // queued, processing, success, failed
            $table->string('external_id')->nullable();
            $table->string('idempotency_key')->nullable()->index();
            $table->text('failure_reason')->nullable();
            $table->timestamps();
        });

        // 16. Wallet Transactions (Ledger)
        Schema::create('wallet_transactions', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('wallet_id')->constrained()->cascadeOnDelete();
            $table->string('type'); // credit, debit
            $table->string('category'); // period_settlement, payout, fee, refund
            $table->unsignedBigInteger('amount');
            $table->string('reference_type')->nullable();
            $table->string('reference_id')->nullable();
            $table->string('description');
            $table->timestamps();
        });

        // 17. Reviews
        Schema::create('reviews', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('booking_id')->constrained()->cascadeOnDelete();
            $table->foreignUlid('reviewer_id')->constrained('users')->cascadeOnDelete();
            $table->foreignUlid('reviewee_id')->constrained('users')->cascadeOnDelete();
            $table->tinyInteger('rating'); // 1-5
            $table->text('comment')->nullable();
            $table->boolean('is_auto')->default(false);
            $table->timestamp('revealed_at')->nullable();
            $table->timestamps();
        });

        // 18. Reports & Disputes
        Schema::create('reports', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('reporter_id')->constrained('users')->cascadeOnDelete();
            $table->foreignUlid('reported_id')->constrained('users')->cascadeOnDelete();
            $table->foreignUlid('booking_id')->nullable()->constrained()->nullOnDelete();
            $table->string('category'); // behavior, fraud, payment, not_as_described, other
            $table->text('description');
            $table->json('evidence_paths')->nullable();
            $table->boolean('share_chat_consent')->default(false);
            $table->timestamp('consent_expires_at')->nullable();
            $table->string('status')->default('submitted'); // submitted, under_review, info_needed, resolved
            $table->text('decision')->nullable();
            $table->timestamps();
        });

        // 19. Webhook Events (Idempotent Webhooks)
        Schema::create('webhook_events', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->string('event_id')->unique();
            $table->string('source')->default('xendit');
            $table->string('event_type');
            $table->json('payload');
            $table->timestamp('processed_at')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('webhook_events');
        Schema::dropIfExists('reports');
        Schema::dropIfExists('reviews');
        Schema::dropIfExists('wallet_transactions');
        Schema::dropIfExists('payouts');
        Schema::dropIfExists('bank_accounts');
        Schema::dropIfExists('wallets');
        Schema::dropIfExists('booking_periods');
        Schema::dropIfExists('bookings');
        Schema::dropIfExists('agreements');
        Schema::dropIfExists('interviews');
        Schema::dropIfExists('applications');
        Schema::dropIfExists('listings');
        Schema::dropIfExists('assistant_profiles');
        Schema::dropIfExists('categories');
        Schema::dropIfExists('skcks');
        Schema::dropIfExists('verifications');
        Schema::dropIfExists('otps');
        Schema::dropIfExists('user_roles');
    }
};

