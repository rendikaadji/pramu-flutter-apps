<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class BookingPeriod extends Model
{
    use HasUlids;

    protected $fillable = [
        'booking_id',
        'period_number',
        'amount',
        'seeker_fee',
        'assistant_fee',
        'total_to_pay',
        'total_payout',
        'due_date',
        'status',
        'invoice_id',
        'invoice_url',
        'idempotency_key',
        'paid_at',
        'completed_at',
        'auto_release_at',
        'settled_at',
    ];

    protected function casts(): array
    {
        return [
            'period_number' => 'integer',
            'amount' => 'integer',
            'seeker_fee' => 'integer',
            'assistant_fee' => 'integer',
            'total_to_pay' => 'integer',
            'total_payout' => 'integer',
            'due_date' => 'date',
            'paid_at' => 'datetime',
            'completed_at' => 'datetime',
            'auto_release_at' => 'datetime',
            'settled_at' => 'datetime',
        ];
    }

    public function booking(): BelongsTo
    {
        return $this->belongsTo(Booking::class);
    }
}

