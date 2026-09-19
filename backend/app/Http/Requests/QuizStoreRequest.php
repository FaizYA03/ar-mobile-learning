<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class QuizStoreRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'title' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000',
            'time_limit' => 'nullable|integer|min:1|max:180',
            'passing_score' => 'nullable|integer|min:0|max:100',
        ];
    }

    public function messages(): array
    {
        return [
            'title.required' => 'Judul quiz wajib diisi',
            'title.max' => 'Judul quiz maksimal 255 karakter',
            'time_limit.integer' => 'Batas waktu harus berupa angka',
            'time_limit.min' => 'Batas waktu minimal 1 menit',
            'passing_score.min' => 'Passing score minimal 0',
            'passing_score.max' => 'Passing score maksimal 100',
        ];
    }
}
