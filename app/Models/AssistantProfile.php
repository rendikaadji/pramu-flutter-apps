<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AssistantProfile extends Model
{
    use HasUlids;

    protected $fillable = [
        'user_id',
        'category_ids',
        'skills',
        'experience_years',
        'rate_per_period',
        'period_type',
        'city_id',
        'city_name',
        'availability_status',
        'bio',
    ];

    protected function casts(): array
    {
        return [
            'category_ids' => 'array',
            'skills' => 'array',
            'experience_years' => 'integer',
            'rate_per_period' => 'integer',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}

