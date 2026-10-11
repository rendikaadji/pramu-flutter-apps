<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Listing extends Model
{
    use HasUlids;

    protected $fillable = [
        'user_id',
        'category_id',
        'title',
        'description',
        'city_id',
        'city_name',
        'period_type',
        'period_count',
        'billing_cycle',
        'start_date',
        'budget_min',
        'budget_max',
        'require_skck',
        'screening_questions',
        'status',
        'listing_fee_invoice_id',
        'listing_fee_invoice_url',
        'paid_at',
        'expires_at',
    ];

    protected function casts(): array
    {
        return [
            'start_date' => 'date',
            'budget_min' => 'integer',
            'budget_max' => 'integer',
            'period_count' => 'integer',
            'require_skck' => 'boolean',
            'screening_questions' => 'array',
            'paid_at' => 'datetime',
            'expires_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    public function applications(): HasMany
    {
        return $this->hasMany(Application::class);
    }
}
