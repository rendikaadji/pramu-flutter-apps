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

    /**
     * Optional helper to generate standard Google Meet URL pattern: https://meet.google.com/xxx-yyyy-zzz
     */
    public static function generateMeetingUrl(): string
    {
        $chars = 'abcdefghijklmnopqrstuvwxyz';
        $p1 = substr(str_shuffle($chars), 0, 3);
        $p2 = substr(str_shuffle($chars), 0, 4);
        $p3 = substr(str_shuffle($chars), 0, 3);

        return "https://meet.google.com/{$p1}-{$p2}-{$p3}";
    }

    public function application(): BelongsTo
    {
        return $this->belongsTo(Application::class);
    }
}
