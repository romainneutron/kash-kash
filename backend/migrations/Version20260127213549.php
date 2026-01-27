<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

final class Version20260127213549 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'Create initial schema: users, refresh_tokens, quests, quest_attempts, path_points';
    }

    public function up(Schema $schema): void
    {
        $this->addSql('CREATE TABLE users (id UUID NOT NULL, email VARCHAR(180) NOT NULL, display_name VARCHAR(255) NOT NULL, avatar_url VARCHAR(500) DEFAULT NULL, roles JSON NOT NULL, google_id VARCHAR(255) DEFAULT NULL, created_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL, updated_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL, PRIMARY KEY (id))');
        $this->addSql('CREATE UNIQUE INDEX UNIQ_1483A5E9E7927C74 ON users (email)');

        $this->addSql('CREATE TABLE refresh_tokens (id UUID NOT NULL, token VARCHAR(128) NOT NULL, expires_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL, created_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL, user_id UUID NOT NULL, PRIMARY KEY (id))');
        $this->addSql('CREATE UNIQUE INDEX UNIQ_9BACE7E15F37A13B ON refresh_tokens (token)');
        $this->addSql('CREATE INDEX IDX_9BACE7E1A76ED395 ON refresh_tokens (user_id)');
        $this->addSql('CREATE INDEX idx_refresh_token ON refresh_tokens (token)');
        $this->addSql('CREATE INDEX idx_refresh_token_expires ON refresh_tokens (expires_at)');
        $this->addSql('ALTER TABLE refresh_tokens ADD CONSTRAINT FK_9BACE7E1A76ED395 FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE NOT DEFERRABLE');

        $this->addSql('CREATE TABLE quests (id UUID NOT NULL, title VARCHAR(255) NOT NULL, description TEXT DEFAULT NULL, latitude DOUBLE PRECISION NOT NULL, longitude DOUBLE PRECISION NOT NULL, radius_meters DOUBLE PRECISION NOT NULL, published BOOLEAN NOT NULL, difficulty VARCHAR(20) DEFAULT NULL, location_type VARCHAR(20) DEFAULT NULL, created_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL, updated_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL, created_by_id UUID NOT NULL, PRIMARY KEY (id))');
        $this->addSql('CREATE INDEX IDX_989E5D34B03A8386 ON quests (created_by_id)');
        $this->addSql('ALTER TABLE quests ADD CONSTRAINT FK_989E5D34B03A8386 FOREIGN KEY (created_by_id) REFERENCES users (id) NOT DEFERRABLE');

        $this->addSql('CREATE TABLE quest_attempts (id UUID NOT NULL, started_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL, completed_at TIMESTAMP(0) WITHOUT TIME ZONE DEFAULT NULL, abandoned_at TIMESTAMP(0) WITHOUT TIME ZONE DEFAULT NULL, status VARCHAR(20) NOT NULL, duration_seconds INT DEFAULT NULL, distance_walked DOUBLE PRECISION DEFAULT NULL, quest_id UUID NOT NULL, user_id UUID NOT NULL, PRIMARY KEY (id))');
        $this->addSql('CREATE INDEX IDX_5E9D58C1209E9EF4 ON quest_attempts (quest_id)');
        $this->addSql('CREATE INDEX IDX_5E9D58C1A76ED395 ON quest_attempts (user_id)');
        $this->addSql('ALTER TABLE quest_attempts ADD CONSTRAINT FK_5E9D58C1209E9EF4 FOREIGN KEY (quest_id) REFERENCES quests (id) NOT DEFERRABLE');
        $this->addSql('ALTER TABLE quest_attempts ADD CONSTRAINT FK_5E9D58C1A76ED395 FOREIGN KEY (user_id) REFERENCES users (id) NOT DEFERRABLE');

        $this->addSql('CREATE TABLE path_points (id UUID NOT NULL, latitude DOUBLE PRECISION NOT NULL, longitude DOUBLE PRECISION NOT NULL, timestamp TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL, accuracy DOUBLE PRECISION NOT NULL, speed DOUBLE PRECISION NOT NULL, attempt_id UUID NOT NULL, PRIMARY KEY (id))');
        $this->addSql('CREATE INDEX IDX_46241352B191BE6B ON path_points (attempt_id)');
        $this->addSql('ALTER TABLE path_points ADD CONSTRAINT FK_46241352B191BE6B FOREIGN KEY (attempt_id) REFERENCES quest_attempts (id) NOT DEFERRABLE');
    }

    public function down(Schema $schema): void
    {
        $this->addSql('ALTER TABLE path_points DROP CONSTRAINT FK_46241352B191BE6B');
        $this->addSql('ALTER TABLE quest_attempts DROP CONSTRAINT FK_5E9D58C1209E9EF4');
        $this->addSql('ALTER TABLE quest_attempts DROP CONSTRAINT FK_5E9D58C1A76ED395');
        $this->addSql('ALTER TABLE quests DROP CONSTRAINT FK_989E5D34B03A8386');
        $this->addSql('ALTER TABLE refresh_tokens DROP CONSTRAINT FK_9BACE7E1A76ED395');
        $this->addSql('DROP TABLE path_points');
        $this->addSql('DROP TABLE quest_attempts');
        $this->addSql('DROP TABLE quests');
        $this->addSql('DROP TABLE refresh_tokens');
        $this->addSql('DROP TABLE users');
    }
}
