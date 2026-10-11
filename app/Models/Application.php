<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Application extends Model
{
    use HasUlids;

    protected $fillable = [
        'listing_id',
        'user_id',
        'message',
        'proposed_rate',
        'answers',
        'status',
        'rejection_reason',
    ];

    protected function casts(): array
    {
        return [
            'proposed_rate' => 'integer',
            'answers' => 'array',
        ];
    }

    public function listing(): BelongsTo
    {
        return $this->belongsTo(Listing::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function interview(): HasOne
    {
        return $this->hasOne(Interview::class);
    }

    public function agreements(): HasMany
    {
        return $this->hasMany(Agreement::class);
    }
}

