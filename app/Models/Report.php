<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Report extends Model
{
    use HasUlids;

    protected $fillable = [
        'reporter_id',
        'reported_id',
        'booking_id',
        'category',
        'description',
        'evidence_paths',
        'share_chat_consent',
        'consent_expires_at',
        'status',
        'decision',
    ];

    protected function casts(): array
    {
        return [
            'evidence_paths' => 'array',
            'share_chat_consent' => 'boolean',
            'consent_expires_at' => 'datetime',
        ];
    }

    public function reporter(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reporter_id');
    }

    public function reported(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reported_id');
    }

    public function booking(): BelongsTo
    {
        return $this->belongsTo(Booking::class);
    }
}

