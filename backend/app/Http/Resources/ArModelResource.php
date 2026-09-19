<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ArModelResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'model_name' => $this->model_name,
            'description' => $this->description,
            'category' => $this->category,
            'glb_path' => $this->glb_path,
            'thumbnail_path' => $this->thumbnail_path,
            'version' => $this->version,
            'is_active' => $this->is_active,
            'hotspots' => ArHotspotResource::collection($this->whenLoaded('hotspots')),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
