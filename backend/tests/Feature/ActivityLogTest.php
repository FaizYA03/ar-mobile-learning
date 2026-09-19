<?php

namespace Tests\Feature;

use App\Models\ActivityLog;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ActivityLogTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed();
    }

    public function test_activity_log_created_on_login(): void
    {
        $user = User::where('role', 'siswa')->first();

        $response = $this->postJson('/api/login', [
            'email' => $user->email,
            'password' => 'password',
        ]);

        $response->assertStatus(200);

        $this->assertDatabaseHas('activity_logs', [
            'user_id' => $user->id,
            'action' => 'login',
        ]);
    }

    public function test_activity_log_created_on_quiz_creation(): void
    {
        $guru = User::where('role', 'guru')->first();
        Sanctum::actingAs($guru);

        $response = $this->postJson('/api/guru/quizzes', [
            'title' => 'Quiz With Logging',
        ]);

        $response->assertStatus(201);

        $quizId = $response->json('data.id');
        $this->assertDatabaseHas('activity_logs', [
            'user_id' => $guru->id,
            'action' => 'quiz.created',
            'entity_type' => 'quiz',
            'entity_id' => $quizId,
        ]);
    }

    public function test_activity_log_created_on_user_deletion(): void
    {
        $admin = User::where('role', 'admin')->first();
        Sanctum::actingAs($admin);

        $user = User::where('role', 'siswa')->first();
        $userId = $user->id;
        $userName = $user->name;

        $response = $this->deleteJson("/api/admin/users/{$userId}");

        $response->assertStatus(200);

        $this->assertDatabaseHas('activity_logs', [
            'user_id' => $admin->id,
            'action' => 'user.deleted',
            'entity_type' => 'user',
            'entity_id' => $userId,
        ]);
    }

    public function test_activity_log_user_relationship(): void
    {
        $admin = User::where('role', 'admin')->first();
        Sanctum::actingAs($admin);

        $this->postJson('/api/guru/quizzes', ['title' => 'Test']);

        $log = ActivityLog::where('user_id', $admin->id)->first();
        $this->assertNotNull($log);
        $this->assertNotNull($log->user);
        $this->assertEquals($admin->id, $log->user->id);
    }

    public function test_activity_log_stores_ip_and_user_agent(): void
    {
        $user = User::where('role', 'siswa')->first();

        $this->postJson('/api/login', [
            'email' => $user->email,
            'password' => 'password',
        ], [
            'HTTP_USER_AGENT' => 'TestAgent/1.0',
        ]);

        $log = ActivityLog::where('user_id', $user->id)->where('action', 'login')->first();
        $this->assertNotNull($log);
        $this->assertNotNull($log->ip_address);
        $this->assertNotNull($log->user_agent);
    }
}
