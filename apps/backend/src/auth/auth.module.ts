import { AccountsModule } from '@app/accounts/accounts.module';
import jwtConfig from '@app/config/jwt.config';
import { RedisModule } from '@app/external/redis/redis.module';
import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { AuthService } from './auth.service';
import { BlacklistService } from './jwt/blacklist.service';
import { JwtAuthService } from './jwt/jwt-auth.service';
import { JwtStrategy } from './jwt/jwt.strategy';
import { JwtRefreshStrategy } from './jwt/jwt-refresh.strategy';
import { APP_GUARD } from '@nestjs/core';
import { JwtAuthGuard } from './jwt/jwt-auth.guard';
import { AuthController } from './auth.controller';

@Module({
  imports: [
    AccountsModule,
    JwtModule.registerAsync(jwtConfig.asProvider()),
    RedisModule,
  ],
  providers: [
    AuthService,
    JwtAuthService,
    BlacklistService,
    JwtStrategy,
    JwtRefreshStrategy,
    {
      provide: APP_GUARD,
      useClass: JwtAuthGuard,
    },
    JwtRefreshStrategy,
  ],
  controllers: [AuthController],
})
export class AuthModule {}
