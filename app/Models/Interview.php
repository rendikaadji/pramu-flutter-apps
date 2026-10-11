<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Interview extends Model
{
    use HasUlids;

    protected $fillable = [
        'application_id',
        'proposed_slots',
        'confirmed_slot',
        'meeting_url',
        'notes',
        'communication_score',
        'politeness_score',
        'reliability_score',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'proposed_slots' => 'array',
            'confirmed_slot' => 'datetime',
            'communication_score' => 'integer',
            'politeness_score' => 'integer',
            'reliability_score' => 'integer',
        ];
    }

    public function application(): BelongsTo
    {
        return $this->belongsTo(Application::class);
    }
}

