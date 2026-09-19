<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class TpAtpResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'kode' => $this->kode,
            'fase' => $this->fase,
            'elemen' => $this->elemen,
            'judul' => $this->judul,
            'deskripsi' => $this->deskripsi,
            'order' => $this->order,
            'is_active' => $this->is_active,
            'materi_count' => $this->whenCounted('materi'),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
