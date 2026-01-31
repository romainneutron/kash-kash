<?php

namespace App\Tests\Unit\Entity;

use App\Entity\User;
use PHPUnit\Framework\TestCase;
use Symfony\Component\Uid\Uuid;

class UserTest extends TestCase
{
    public function testConstructorSetsDefaultValues(): void
    {
        $user = new User();

        $this->assertInstanceOf(Uuid::class, $user->getId());
        $this->assertInstanceOf(\DateTimeImmutable::class, $user->getCreatedAt());
        $this->assertInstanceOf(\DateTimeImmutable::class, $user->getUpdatedAt());
        $this->assertCount(0, $user->getCreatedQuests());
        $this->assertCount(0, $user->getAttempts());
    }

    public function testEmailSetterAndGetter(): void
    {
        $user = new User();
        $user->setEmail('test@example.com');

        $this->assertEquals('test@example.com', $user->getEmail());
    }

    public function testDisplayNameSetterAndGetter(): void
    {
        $user = new User();
        $user->setDisplayName('Test User');

        $this->assertEquals('Test User', $user->getDisplayName());
    }

    public function testAvatarUrlSetterAndGetter(): void
    {
        $user = new User();

        $this->assertNull($user->getAvatarUrl());

        $user->setAvatarUrl('https://example.com/avatar.jpg');
        $this->assertEquals('https://example.com/avatar.jpg', $user->getAvatarUrl());

        $user->setAvatarUrl(null);
        $this->assertNull($user->getAvatarUrl());
    }

    public function testGoogleIdSetterAndGetter(): void
    {
        $user = new User();

        $this->assertNull($user->getGoogleId());

        $user->setGoogleId('google-123');
        $this->assertEquals('google-123', $user->getGoogleId());
    }

    public function testRolesIncludesDefaultUserRole(): void
    {
        $user = new User();

        $roles = $user->getRoles();

        $this->assertContains('ROLE_USER', $roles);
    }

    public function testSetRolesAddedToExisting(): void
    {
        $user = new User();
        $user->setRoles(['ROLE_ADMIN']);

        $roles = $user->getRoles();

        $this->assertContains('ROLE_USER', $roles);
        $this->assertContains('ROLE_ADMIN', $roles);
    }

    public function testRolesDeduplication(): void
    {
        $user = new User();
        $user->setRoles(['ROLE_USER', 'ROLE_ADMIN']);

        $roles = $user->getRoles();

        $this->assertCount(2, $roles);
    }

    public function testIsAdminReturnsFalseForRegularUser(): void
    {
        $user = new User();

        $this->assertFalse($user->isAdmin());
    }

    public function testIsAdminReturnsTrueForAdminUser(): void
    {
        $user = new User();
        $user->setRoles(['ROLE_ADMIN']);

        $this->assertTrue($user->isAdmin());
    }

    public function testGetUserIdentifierReturnsEmail(): void
    {
        $user = new User();
        $user->setEmail('identifier@example.com');

        $this->assertEquals('identifier@example.com', $user->getUserIdentifier());
    }

    public function testEraseCredentialsDoesNotThrow(): void
    {
        $user = new User();

        // Should not throw - OAuth users have no credentials to erase
        $user->eraseCredentials();

        $this->assertTrue(true);
    }

    public function testSetUpdatedAt(): void
    {
        $user = new User();
        $newDate = new \DateTimeImmutable('2024-01-01 00:00:00');

        $user->setUpdatedAt($newDate);

        $this->assertEquals($newDate, $user->getUpdatedAt());
    }

    public function testSettersReturnSelf(): void
    {
        $user = new User();

        $this->assertSame($user, $user->setEmail('test@example.com'));
        $this->assertSame($user, $user->setDisplayName('Test'));
        $this->assertSame($user, $user->setAvatarUrl('https://example.com'));
        $this->assertSame($user, $user->setGoogleId('google-123'));
        $this->assertSame($user, $user->setRoles(['ROLE_USER']));
        $this->assertSame($user, $user->setUpdatedAt(new \DateTimeImmutable()));
    }
}
