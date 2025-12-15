import redisConfig from '@app/config/redis.config';
import { Inject, Injectable, Logger, OnModuleDestroy } from '@nestjs/common';
import type { ConfigType } from '@nestjs/config';
import Redis from 'ioredis';

@Injectable()
export class RedisService implements OnModuleDestroy {
  private readonly redisClient: Redis;
  private readonly logger = new Logger(RedisService.name);

  constructor(
    @Inject(redisConfig.KEY)
    private readonly redisConfiguration: ConfigType<typeof redisConfig>,
  ) {
    this.redisClient = new Redis(this.redisConfiguration);

    this.redisClient.on('connect', () =>
      this.logger.log(
        `Connected to Redis on ${this.redisConfiguration.host}:${this.redisConfiguration.port}`,
      ),
    );
    this.redisClient.on('error', (err) =>
      this.logger.error(`Redis Error: ${err}`),
    );
  }

  onModuleDestroy() {
    void this.redisClient.quit();
  }

  getClient(): Redis {
    return this.redisClient;
  }

  /**
   * Get a value from Redis
   * @param {string} key - The key to get
   * @returns {Promise<string | null>}
   */
  async getValue(key: string): Promise<string | null> {
    return this.redisClient.get(key);
  }

  /**
   * Set a value in Redis
   * @param {string} key - The key to set
   * @param {string} value - The value to set
   * @param {number} [ttl] - The time to live in seconds
   * @returns {Promise<void>}
   */
  async setValue(key: string, value: string, ttl?: number): Promise<void> {
    if (ttl) {
      await this.redisClient.set(key, value, 'EX', ttl);
    } else {
      await this.redisClient.set(key, value);
    }
  }
}
