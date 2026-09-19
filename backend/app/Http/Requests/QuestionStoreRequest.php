<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class QuestionStoreRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'text' => 'required|string|max:1000',
            'options' => 'required|array|min:2|max:10',
            'options.*.text' => 'required|string|max:500',
            'options.*.is_correct' => 'required|boolean',
        ];
    }

    public function messages(): array
    {
        return [
            'text.required' => 'Soal wajib diisi',
            'text.max' => 'Soal maksimal 1000 karakter',
            'options.required' => 'Opsi jawaban wajib diisi',
            'options.min' => 'Minimal 2 opsi jawaban',
            'options.*.text.required' => 'Teks opsi wajib diisi',
            'options.*.is_correct.required' => 'Pilihan jawaban benar wajib ditentukan',
        ];
    }
}
