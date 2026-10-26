<?php

namespace App\Policies;

use App\Models\Quiz;
use App\Models\User;
use App\Policies\Concerns\ChecksContentOwnership;

class QuizPolicy
{
    use ChecksContentOwnership;

    public function viewAny(User $user): bool
    {
        return true;
    }

    public function view(User $user, Quiz $quiz): bool
    {
        return true;
    }

    public function create(User $user): bool
    {
        return in_array($user->role, ['guru', 'admin'], true);
    }

    public function update(User $user, Quiz $quiz): bool
    {
        return $this->canManage($user, $quiz->created_by);
    }

    public function delete(User $user, Quiz $quiz): bool
    {
        return $this->canManage($user, $quiz->created_by);
    }
}
