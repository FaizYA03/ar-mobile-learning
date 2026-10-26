<?php

namespace App\Policies\Concerns;

use App\Models\User;

trait ChecksContentOwnership
{
    protected function canManage(User $user, ?int $createdBy): bool
    {
        if ($user->role === 'admin') {
            return true;
        }

        if ($user->role !== 'guru') {
            return false;
        }

        return $createdBy === null || (int) $createdBy === $user->id;
    }
}
