<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class QuizSubmitRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'answers' => 'required|array|min:1',
            'answers.*.question_id' => 'required|exists:questions,id',
            'answers.*.option_id' => 'required|exists:question_options,id',
        ];
    }

    public function messages(): array
    {
        return [
            'answers.required' => 'Jawaban wajib diisi',
            'answers.min' => 'Minimal 1 jawaban harus diisi',
            'answers.*.question_id.required' => 'ID soal wajib diisi',
            'answers.*.question_id.exists' => 'Soal tidak ditemukan',
            'answers.*.option_id.required' => 'ID opsi wajib diisi',
            'answers.*.option_id.exists' => 'Opsi jawaban tidak ditemukan',
        ];
    }
}
