<?php

namespace App\Tests\Unit\Entity;

use App\Entity\RefreshToken;
use App\Entity\User;
use PHPUnit\Framework\TestCase;
use Symfony\Component\Uid\Uuid;

class RefreshTokenTest extends TestCase
{
    private function createUser(): User
    {
        $user = new User();
        $user->setEmail('test@example.com');
        $user->setDisplayName('Test User');
        return $user;
    }

    public function testConstructorGeneratesUuid(): void
    {
        $user = $this->createUser();
        $token = new RefreshToken($user);

        $this->assertInstanceOf(Uuid::class, $token->getId());
    }

    public function testConstructorGeneratesRandomToken(): void
    {
        $user = $this->createUser();
        $token1 = new RefreshToken($user);
        $token2 = new RefreshToken($user);

        // Tokens should be 128 hex characters (64 bytes)
        $this->assertEquals(128, strlen($token1->getToken()));
        $this->assertEquals(128, strlen($token2->getToken()));

        // Tokens should be unique
        $this->assertNotEquals($token1->getToken(), $token2->getToken());
    }

    public function testConstructorSetsUser(): void
    {
        $user = $this->createUser();
        $token = new RefreshToken($user);

        $this->assertSame($user, $token->getUser());
    }

    public function testDefaultExpiration(): void
    {
        $user = $this->createUser();
        $beforeCreation = new \DateTimeImmutable();

        $token = new RefreshToken($user);

        $afterCreation = new \DateTimeImmutable();

        // Default TTL is 7 days
        $expectedMinExpiry = $beforeCreation->modify('+7 days');
        $expectedMaxExpiry = $afterCreation->modify('+7 days');

        $this->assertGreaterThanOrEqual($expectedMinExpiry, $token->getExpiresAt());
        $this->assertLessThanOrEqual($expectedMaxExpiry, $token->getExpiresAt());
    }

    public function testCustomTtl(): void
    {
        $user = $this->createUser();
        $beforeCreation = new \DateTimeImmutable();

        $token = new RefreshToken($user, 30);

        $afterCreation = new \DateTimeImmutable();

        // Custom TTL is 30 days
        $expectedMinExpiry = $beforeCreation->modify('+30 days');
        $expectedMaxExpiry = $afterCreation->modify('+30 days');

        $this->assertGreaterThanOrEqual($expectedMinExpiry, $token->getExpiresAt());
        $this->assertLessThanOrEqual($expectedMaxExpiry, $token->getExpiresAt());
    }

    public function testCreatedAtIsSetOnConstruction(): void
    {
        $user = $this->createUser();
        $beforeCreation = new \DateTimeImmutable();

        $token = new RefreshToken($user);

        $afterCreation = new \DateTimeImmutable();

        $this->assertGreaterThanOrEqual($beforeCreation, $token->getCreatedAt());
        $this->assertLessThanOrEqual($afterCreation, $token->getCreatedAt());
    }

    public function testIsExpiredReturnsFalseForNewToken(): void
    {
        $user = $this->createUser();
        $token = new RefreshToken($user);

        $this->assertFalse($token->isExpired());
    }

    public function testTokenStringContainsOnlyHexCharacters(): void
    {
        $user = $this->createUser();
        $token = new RefreshToken($user);

        $this->assertMatchesRegularExpression('/^[0-9a-f]+$/', $token->getToken());
    }
}
