<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class MateriResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'tp_atp_id' => $this->tp_atp_id,
            'ar_model_id' => $this->ar_model_id,
            'judul' => $this->judul,
            'slug' => $this->slug,
            'ringkasan' => $this->ringkasan,
            'konten' => $this->konten,
            'gambar_cover' => $this->gambar_cover,
            'gambar_cover_url' => $this->gambar_cover
                ? $request->getSchemeAndHttpHost() . '/storage/' . $this->gambar_cover
                : null,
            'estimasi_menit' => $this->estimasi_menit,
            'order' => $this->order,
            'is_published' => $this->is_published,
            'tp_atp' => new TpAtpResource($this->whenLoaded('tpAtp')),
            'ar_model' => new ArModelResource($this->whenLoaded('arModel')),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
