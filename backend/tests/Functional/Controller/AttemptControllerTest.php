<?php

namespace App\Tests\Functional\Controller;

use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;

/**
 * AttemptController functional tests.
 *
 * Note: These tests require a database connection and the full Symfony kernel.
 * Run with: make backend-test (requires Docker)
 *
 * @group functional
 */
class AttemptControllerTest extends WebTestCase
{
    public function testAddPathPointsReturnsUnauthorizedWithoutToken(): void
    {
        $client = static::createClient();

        $client->request(
            'POST',
            '/api/attempts/test-id/path',
            [],
            [],
            ['CONTENT_TYPE' => 'application/json'],
            json_encode(['points' => []])
        );

        // JWT firewall intercepts and returns 401 before reaching controller
        $this->assertResponseStatusCodeSame(401);

        $response = json_decode($client->getResponse()->getContent(), true);
        $this->assertArrayHasKey('message', $response);
        $this->assertEquals('JWT Token not found', $response['message']);
    }

    public function testCompleteAttemptReturnsUnauthorizedWithoutToken(): void
    {
        $client = static::createClient();

        $client->request(
            'POST',
            '/api/attempts/test-id/complete',
            [],
            [],
            ['CONTENT_TYPE' => 'application/json'],
            json_encode([])
        );

        $this->assertResponseStatusCodeSame(401);

        $response = json_decode($client->getResponse()->getContent(), true);
        $this->assertArrayHasKey('message', $response);
        $this->assertEquals('JWT Token not found', $response['message']);
    }

    public function testAbandonAttemptReturnsUnauthorizedWithoutToken(): void
    {
        $client = static::createClient();

        $client->request(
            'POST',
            '/api/attempts/test-id/abandon',
            [],
            [],
            ['CONTENT_TYPE' => 'application/json'],
            json_encode([])
        );

        $this->assertResponseStatusCodeSame(401);

        $response = json_decode($client->getResponse()->getContent(), true);
        $this->assertArrayHasKey('message', $response);
        $this->assertEquals('JWT Token not found', $response['message']);
    }
}
