<?php

namespace App\Tests\Unit\Entity;

use App\Entity\PathPoint;
use App\Entity\Quest;
use App\Entity\QuestAttempt;
use App\Entity\User;
use PHPUnit\Framework\TestCase;
use Symfony\Component\Uid\Uuid;

class PathPointTest extends TestCase
{
    private function createAttempt(): QuestAttempt
    {
        $user = new User();
        $user->setEmail('test@example.com');
        $user->setDisplayName('Test User');

        $quest = new Quest();
        $quest->setTitle('Test Quest');
        $quest->setLatitude(0);
        $quest->setLongitude(0);
        $quest->setCreatedBy($user);

        $attempt = new QuestAttempt();
        $attempt->setQuest($quest);
        $attempt->setUser($user);

        return $attempt;
    }

    public function testConstructorSetsDefaultValues(): void
    {
        $point = new PathPoint();

        $this->assertInstanceOf(Uuid::class, $point->getId());
        $this->assertInstanceOf(\DateTimeImmutable::class, $point->getTimestamp());
    }

    public function testAttemptSetterAndGetter(): void
    {
        $attempt = $this->createAttempt();
        $point = new PathPoint();

        $point->setAttempt($attempt);

        $this->assertSame($attempt, $point->getAttempt());
    }

    public function testLatitudeSetterAndGetter(): void
    {
        $point = new PathPoint();

        $point->setLatitude(48.8566);

        $this->assertEquals(48.8566, $point->getLatitude());
    }

    public function testLongitudeSetterAndGetter(): void
    {
        $point = new PathPoint();

        $point->setLongitude(2.3522);

        $this->assertEquals(2.3522, $point->getLongitude());
    }

    public function testTimestampSetterAndGetter(): void
    {
        $point = new PathPoint();
        $timestamp = new \DateTimeImmutable('2024-01-01 12:00:00');

        $point->setTimestamp($timestamp);

        $this->assertEquals($timestamp, $point->getTimestamp());
    }

    public function testAccuracySetterAndGetter(): void
    {
        $point = new PathPoint();

        $point->setAccuracy(5.5);

        $this->assertEquals(5.5, $point->getAccuracy());
    }

    public function testSpeedSetterAndGetter(): void
    {
        $point = new PathPoint();

        $point->setSpeed(1.5);

        $this->assertEquals(1.5, $point->getSpeed());
    }

    public function testCoordinateBoundaries(): void
    {
        $point = new PathPoint();

        // Test extreme latitude values
        $point->setLatitude(-90.0);
        $this->assertEquals(-90.0, $point->getLatitude());

        $point->setLatitude(90.0);
        $this->assertEquals(90.0, $point->getLatitude());

        // Test extreme longitude values
        $point->setLongitude(-180.0);
        $this->assertEquals(-180.0, $point->getLongitude());

        $point->setLongitude(180.0);
        $this->assertEquals(180.0, $point->getLongitude());
    }

    public function testSettersReturnSelf(): void
    {
        $point = new PathPoint();
        $attempt = $this->createAttempt();

        $this->assertSame($point, $point->setAttempt($attempt));
        $this->assertSame($point, $point->setLatitude(0.0));
        $this->assertSame($point, $point->setLongitude(0.0));
        $this->assertSame($point, $point->setTimestamp(new \DateTimeImmutable()));
        $this->assertSame($point, $point->setAccuracy(1.0));
        $this->assertSame($point, $point->setSpeed(1.0));
    }

    public function testUniqueIdsForMultipleInstances(): void
    {
        $point1 = new PathPoint();
        $point2 = new PathPoint();

        $this->assertNotEquals($point1->getId()->toRfc4122(), $point2->getId()->toRfc4122());
    }
}
