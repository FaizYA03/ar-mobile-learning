<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class MateriStoreRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'tp_atp_id' => 'required|exists:tp_atp,id',
            'ar_model_id' => 'nullable|exists:ar_models,id',
            'judul' => 'required|string|max:255',
            'ringkasan' => 'nullable|string|max:1000',
            'konten' => 'required|string',
            'estimasi_menit' => 'nullable|integer|min:1|max:180',
            'order' => 'nullable|integer|min:0',
            'is_published' => 'nullable|boolean',
            'gambar_cover' => 'nullable|image|mimes:jpg,jpeg,png,webp|max:5120',
        ];
    }

    public function messages(): array
    {
        return [
            'tp_atp_id.required' => 'TP/ATP wajib dipilih',
            'tp_atp_id.exists' => 'TP/ATP tidak valid',
            'judul.required' => 'Judul materi wajib diisi',
            'judul.max' => 'Judul materi maksimal 255 karakter',
            'konten.required' => 'Konten materi wajib diisi',
            'estimasi_menit.integer' => 'Estimasi waktu harus berupa angka',
            'estimasi_menit.min' => 'Estimasi waktu minimal 1 menit',
            'gambar_cover.image' => 'Gambar cover harus berupa file gambar',
            'gambar_cover.mimes' => 'Gambar cover harus berformat JPG, PNG, atau WEBP',
            'gambar_cover.max' => 'Ukuran gambar cover maksimal 5 MB',
        ];
    }
}
