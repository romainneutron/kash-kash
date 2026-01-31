<?php

namespace App\Tests\Unit\Entity;

use App\Entity\Quest;
use App\Entity\User;
use PHPUnit\Framework\TestCase;
use Symfony\Component\Uid\Uuid;

class QuestTest extends TestCase
{
    private function createUser(): User
    {
        $user = new User();
        $user->setEmail('test@example.com');
        $user->setDisplayName('Test User');
        return $user;
    }

    public function testConstructorSetsDefaultValues(): void
    {
        $quest = new Quest();

        $this->assertInstanceOf(Uuid::class, $quest->getId());
        $this->assertInstanceOf(\DateTimeImmutable::class, $quest->getCreatedAt());
        $this->assertInstanceOf(\DateTimeImmutable::class, $quest->getUpdatedAt());
        $this->assertCount(0, $quest->getAttempts());
        $this->assertEquals(3.0, $quest->getRadiusMeters());
        $this->assertFalse($quest->isPublished());
    }

    public function testTitleSetterAndGetter(): void
    {
        $quest = new Quest();
        $quest->setTitle('Test Quest');

        $this->assertEquals('Test Quest', $quest->getTitle());
    }

    public function testDescriptionSetterAndGetter(): void
    {
        $quest = new Quest();

        $this->assertNull($quest->getDescription());

        $quest->setDescription('A description');
        $this->assertEquals('A description', $quest->getDescription());

        $quest->setDescription(null);
        $this->assertNull($quest->getDescription());
    }

    public function testCoordinateSettersAndGetters(): void
    {
        $quest = new Quest();

        $quest->setLatitude(48.8566);
        $quest->setLongitude(2.3522);

        $this->assertEquals(48.8566, $quest->getLatitude());
        $this->assertEquals(2.3522, $quest->getLongitude());
    }

    public function testRadiusMetersSetterAndGetter(): void
    {
        $quest = new Quest();
        $quest->setRadiusMeters(5.5);

        $this->assertEquals(5.5, $quest->getRadiusMeters());
    }

    public function testCreatedBySetterAndGetter(): void
    {
        $user = $this->createUser();
        $quest = new Quest();
        $quest->setCreatedBy($user);

        $this->assertSame($user, $quest->getCreatedBy());
    }

    public function testPublishedSetterAndGetter(): void
    {
        $quest = new Quest();

        $this->assertFalse($quest->isPublished());

        $quest->setPublished(true);
        $this->assertTrue($quest->isPublished());

        $quest->setPublished(false);
        $this->assertFalse($quest->isPublished());
    }

    public function testDifficultySetterAndGetter(): void
    {
        $quest = new Quest();

        $this->assertNull($quest->getDifficulty());

        $quest->setDifficulty(Quest::DIFFICULTY_HARD);
        $this->assertEquals(Quest::DIFFICULTY_HARD, $quest->getDifficulty());
    }

    public function testLocationTypeSetterAndGetter(): void
    {
        $quest = new Quest();

        $this->assertNull($quest->getLocationType());

        $quest->setLocationType(Quest::LOCATION_FOREST);
        $this->assertEquals(Quest::LOCATION_FOREST, $quest->getLocationType());
    }

    public function testUpdatedAtSetterAndGetter(): void
    {
        $quest = new Quest();
        $newDate = new \DateTimeImmutable('2024-01-01 00:00:00');

        $quest->setUpdatedAt($newDate);

        $this->assertEquals($newDate, $quest->getUpdatedAt());
    }

    public function testDifficultyConstants(): void
    {
        $this->assertEquals('easy', Quest::DIFFICULTY_EASY);
        $this->assertEquals('medium', Quest::DIFFICULTY_MEDIUM);
        $this->assertEquals('hard', Quest::DIFFICULTY_HARD);
        $this->assertEquals('expert', Quest::DIFFICULTY_EXPERT);
    }

    public function testLocationTypeConstants(): void
    {
        $this->assertEquals('city', Quest::LOCATION_CITY);
        $this->assertEquals('forest', Quest::LOCATION_FOREST);
        $this->assertEquals('park', Quest::LOCATION_PARK);
        $this->assertEquals('water', Quest::LOCATION_WATER);
        $this->assertEquals('mountain', Quest::LOCATION_MOUNTAIN);
        $this->assertEquals('indoor', Quest::LOCATION_INDOOR);
    }

    public function testSettersReturnSelf(): void
    {
        $quest = new Quest();
        $user = $this->createUser();

        $this->assertSame($quest, $quest->setTitle('Test'));
        $this->assertSame($quest, $quest->setDescription('Desc'));
        $this->assertSame($quest, $quest->setLatitude(0.0));
        $this->assertSame($quest, $quest->setLongitude(0.0));
        $this->assertSame($quest, $quest->setRadiusMeters(5.0));
        $this->assertSame($quest, $quest->setCreatedBy($user));
        $this->assertSame($quest, $quest->setPublished(true));
        $this->assertSame($quest, $quest->setDifficulty(Quest::DIFFICULTY_EASY));
        $this->assertSame($quest, $quest->setLocationType(Quest::LOCATION_CITY));
        $this->assertSame($quest, $quest->setUpdatedAt(new \DateTimeImmutable()));
    }
}
