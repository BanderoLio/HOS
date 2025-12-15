import { registerAs } from '@nestjs/config';
import type { RedisOptions } from 'ioredis';

export default registerAs(
  'redis',
  (): RedisOptions => ({
    host: process.env.REDIS_HOST ?? 'localhost',
    port: +(process.env.REDIS_PORT ?? '6379'),
    password: process.env.REDIS_PASSWORD ?? '',
    username: process.env.REDIS_USERNAME ?? '',
  }),
);
