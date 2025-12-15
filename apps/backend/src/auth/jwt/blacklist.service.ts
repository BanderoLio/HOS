import { RedisService } from '@app/external/redis/redis.service';
import { Injectable, Logger } from '@nestjs/common';

@Injectable()
export class BlacklistService {
  private readonly logger = new Logger(BlacklistService.name);
  constructor(private readonly redisService: RedisService) {}
  async addJwtToBlacklist(token: string, expires: number) {
    const ttl = expires - Math.floor(Date.now() / 1000);
    if (ttl > 0) {
      await this.redisService.setValue(token, 'bl', ttl);
    }
  }
  async isTokenInBlacklist(token: string) {
    const val = await this.redisService.getValue(token);
    this.logger.debug(val, val === null);
    return !!val;
  }
}
