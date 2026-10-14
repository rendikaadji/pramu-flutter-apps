<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Agreement extends Model
{
    use HasUlids;

    protected $fillable = [
        'application_id',
        'version',
        'proposed_by_user_id',
        'rate_per_period',
        'period_type',
        'period_count',
        'billing_cycle',
        'start_date',
        'seeker_approved_at',
        'assistant_approved_at',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'version' => 'integer',
            'rate_per_period' => 'integer',
            'period_count' => 'integer',
            'start_date' => 'date',
            'seeker_approved_at' => 'datetime',
            'assistant_approved_at' => 'datetime',
        ];
    }

    public function application(): BelongsTo
    {
        return $this->belongsTo(Application::class);
    }

    public function proposedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'proposed_by_user_id');
    }

    public function booking(): HasOne
    {
        return $this->hasOne(Booking::class);
    }
}
