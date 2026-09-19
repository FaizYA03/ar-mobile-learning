<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class QuestionOptionResource extends JsonResource
{
    private bool $revealCorrect = false;

    public function revealCorrect(bool $reveal): static
    {
        $this->revealCorrect = $reveal;
        return $this;
    }

    public function toArray(Request $request): array
    {
        $data = [
            'id' => $this->id,
            'question_id' => $this->question_id,
            'text' => $this->text,
            'order' => $this->order,
        ];

        if ($this->revealCorrect) {
            $data['is_correct'] = $this->is_correct;
        }

        return $data;
    }
}
