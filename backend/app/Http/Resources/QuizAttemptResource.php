<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class QuizAttemptResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'user_id' => $this->user_id,
            'quiz_id' => $this->quiz_id,
            'score' => $this->score,
            'passed' => $this->passed,
            'user' => [
                'id' => $this->whenLoaded('user')?->id,
                'name' => $this->whenLoaded('user')?->name,
            ],
            'quiz' => [
                'id' => $this->whenLoaded('quiz')?->id,
                'title' => $this->whenLoaded('quiz')?->title,
            ],
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
