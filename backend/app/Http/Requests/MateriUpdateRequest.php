<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class MateriUpdateRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'tp_atp_id' => 'sometimes|exists:tp_atp,id',
            'ar_model_id' => 'nullable|exists:ar_models,id',
            'judul' => 'sometimes|string|max:255',
            'ringkasan' => 'nullable|string|max:1000',
            'konten' => 'sometimes|string',
            'estimasi_menit' => 'nullable|integer|min:1|max:180',
            'order' => 'nullable|integer|min:0',
            'is_published' => 'nullable|boolean',
            'gambar_cover' => 'nullable',
        ];
    }

    public function messages(): array
    {
        return [
            'tp_atp_id.exists' => 'TP/ATP tidak valid',
            'judul.max' => 'Judul materi maksimal 255 karakter',
            'estimasi_menit.integer' => 'Estimasi waktu harus berupa angka',
            'estimasi_menit.min' => 'Estimasi waktu minimal 1 menit',
        ];
    }
}
