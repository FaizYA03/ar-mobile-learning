<?php

namespace App\Policies;

use App\Models\ArModel;
use App\Models\User;
use App\Policies\Concerns\ChecksContentOwnership;

class ArModelPolicy
{
    use ChecksContentOwnership;

    public function viewAny(User $user): bool
    {
        return true;
    }

    public function view(User $user, ArModel $arModel): bool
    {
        return true;
    }

    public function create(User $user): bool
    {
        return in_array($user->role, ['guru', 'admin'], true);
    }

    public function update(User $user, ArModel $arModel): bool
    {
        return $this->canManage($user, $arModel->created_by);
    }

    public function delete(User $user, ArModel $arModel): bool
    {
        return $this->canManage($user, $arModel->created_by);
    }
}
