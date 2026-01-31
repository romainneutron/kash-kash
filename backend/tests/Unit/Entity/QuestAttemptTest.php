<?php

namespace App\Tests\Unit\Entity;

use App\Entity\PathPoint;
use App\Entity\Quest;
use App\Entity\QuestAttempt;
use App\Entity\User;
use PHPUnit\Framework\TestCase;
use Symfony\Component\Uid\Uuid;

class QuestAttemptTest extends TestCase
{
    private function createUser(): User
    {
        $user = new User();
        $user->setEmail('test@example.com');
        $user->setDisplayName('Test User');
        return $user;
    }

    private function createQuest(): Quest
    {
        $quest = new Quest();
        $quest->setTitle('Test Quest');
        $quest->setLatitude(48.8566);
        $quest->setLongitude(2.3522);
        $quest->setCreatedBy($this->createUser());
        return $quest;
    }

    public function testConstructorSetsDefaultValues(): void
    {
        $attempt = new QuestAttempt();

        $this->assertInstanceOf(Uuid::class, $attempt->getId());
        $this->assertInstanceOf(\DateTimeImmutable::class, $attempt->getStartedAt());
        $this->assertCount(0, $attempt->getPathPoints());
        $this->assertEquals(QuestAttempt::STATUS_IN_PROGRESS, $attempt->getStatus());
    }

    public function testStatusConstants(): void
    {
        $this->assertEquals('in_progress', QuestAttempt::STATUS_IN_PROGRESS);
        $this->assertEquals('completed', QuestAttempt::STATUS_COMPLETED);
        $this->assertEquals('abandoned', QuestAttempt::STATUS_ABANDONED);
    }

    public function testQuestSetterAndGetter(): void
    {
        $quest = $this->createQuest();
        $attempt = new QuestAttempt();

        $attempt->setQuest($quest);

        $this->assertSame($quest, $attempt->getQuest());
    }

    public function testUserSetterAndGetter(): void
    {
        $user = $this->createUser();
        $attempt = new QuestAttempt();

        $attempt->setUser($user);

        $this->assertSame($user, $attempt->getUser());
    }

    public function testStatusSetterAndGetter(): void
    {
        $attempt = new QuestAttempt();

        $attempt->setStatus(QuestAttempt::STATUS_COMPLETED);

        $this->assertEquals(QuestAttempt::STATUS_COMPLETED, $attempt->getStatus());
    }

    public function testCompletedAtSetterAndGetter(): void
    {
        $attempt = new QuestAttempt();
        $completedAt = new \DateTimeImmutable();

        $this->assertNull($attempt->getCompletedAt());

        $attempt->setCompletedAt($completedAt);
        $this->assertEquals($completedAt, $attempt->getCompletedAt());
    }

    public function testAbandonedAtSetterAndGetter(): void
    {
        $attempt = new QuestAttempt();
        $abandonedAt = new \DateTimeImmutable();

        $this->assertNull($attempt->getAbandonedAt());

        $attempt->setAbandonedAt($abandonedAt);
        $this->assertEquals($abandonedAt, $attempt->getAbandonedAt());
    }

    public function testDurationSecondsSetterAndGetter(): void
    {
        $attempt = new QuestAttempt();

        $this->assertNull($attempt->getDurationSeconds());

        $attempt->setDurationSeconds(3600);
        $this->assertEquals(3600, $attempt->getDurationSeconds());
    }

    public function testDistanceWalkedSetterAndGetter(): void
    {
        $attempt = new QuestAttempt();

        $this->assertNull($attempt->getDistanceWalked());

        $attempt->setDistanceWalked(1500.5);
        $this->assertEquals(1500.5, $attempt->getDistanceWalked());
    }

    public function testComplete(): void
    {
        $attempt = new QuestAttempt();
        $startTime = $attempt->getStartedAt();

        // Wait a tiny bit to ensure duration > 0
        usleep(1000);

        $attempt->complete();

        $this->assertEquals(QuestAttempt::STATUS_COMPLETED, $attempt->getStatus());
        $this->assertNotNull($attempt->getCompletedAt());
        $this->assertNotNull($attempt->getDurationSeconds());
        $this->assertGreaterThanOrEqual(0, $attempt->getDurationSeconds());
    }

    public function testAbandon(): void
    {
        $attempt = new QuestAttempt();

        $attempt->abandon();

        $this->assertEquals(QuestAttempt::STATUS_ABANDONED, $attempt->getStatus());
        $this->assertNotNull($attempt->getAbandonedAt());
        $this->assertNotNull($attempt->getDurationSeconds());
    }

    public function testAddPathPoint(): void
    {
        $attempt = new QuestAttempt();
        $pathPoint = new PathPoint();

        $attempt->addPathPoint($pathPoint);

        $this->assertCount(1, $attempt->getPathPoints());
        $this->assertTrue($attempt->getPathPoints()->contains($pathPoint));
    }

    public function testAddPathPointDoesNotAddDuplicate(): void
    {
        $attempt = new QuestAttempt();
        $pathPoint = new PathPoint();

        $attempt->addPathPoint($pathPoint);
        $attempt->addPathPoint($pathPoint);

        $this->assertCount(1, $attempt->getPathPoints());
    }

    public function testSettersReturnSelf(): void
    {
        $attempt = new QuestAttempt();
        $quest = $this->createQuest();
        $user = $this->createUser();

        $this->assertSame($attempt, $attempt->setQuest($quest));
        $this->assertSame($attempt, $attempt->setUser($user));
        $this->assertSame($attempt, $attempt->setStatus(QuestAttempt::STATUS_IN_PROGRESS));
        $this->assertSame($attempt, $attempt->setCompletedAt(new \DateTimeImmutable()));
        $this->assertSame($attempt, $attempt->setAbandonedAt(new \DateTimeImmutable()));
        $this->assertSame($attempt, $attempt->setDurationSeconds(100));
        $this->assertSame($attempt, $attempt->setDistanceWalked(100.0));
    }
}
