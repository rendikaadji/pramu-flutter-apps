<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\JsonResponse;

trait ApiResponse
{
    /**
     * Format standard success envelope
     */
    protected function successResponse(mixed $data = null, mixed $meta = null, int $status = 200): JsonResponse
    {
        $payload = ['data' => $data];

        if ($meta !== null) {
            $payload['meta'] = $meta;
        }

        return response()->json($payload, $status);
    }

    /**
     * Format standard error envelope
     */
    protected function errorResponse(string $code, string $message, ?array $fields = null, int $status = 400): JsonResponse
    {
        return response()->json([
            'error' => [
                'code' => $code,
                'message' => $message,
                'fields' => $fields ?? (object)[],
            ],
        ], $status);
    }
}

