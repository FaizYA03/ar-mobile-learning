<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class QuestionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $isAdmin = $request->user() && in_array($request->user()->role, ['admin', 'guru']);

        return [
            'id' => $this->id,
            'quiz_id' => $this->quiz_id,
            'text' => $this->text,
            'order' => $this->order,
            'options' => $this->whenLoaded('options', function () use ($isAdmin) {
                return $this->options->map(function ($option) use ($isAdmin) {
                    $data = [
                        'id' => $option->id,
                        'question_id' => $option->question_id,
                        'text' => $option->text,
                        'order' => $option->order,
                    ];
                    if ($isAdmin) {
                        $data['is_correct'] = $option->is_correct;
                    }
                    return $data;
                });
            }),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
