import { CodeError } from '@app/common/errors/code.error';
import jwtConfig from '@app/config/jwt.config';
import { Inject, Injectable, UnauthorizedException } from '@nestjs/common';
import type { ConfigType } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import type { Request } from 'express';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { AuthError } from '../enums/auth-error.enum';
import type { JwtPayload } from './interfaces/jwt.interface';
import { JwtAuthService } from './jwt-auth.service';

export const JWT_REFRESH_STRATEGY_KEY = 'jwt-refresh';

@Injectable()
export class JwtRefreshStrategy extends PassportStrategy(
  Strategy,
  JWT_REFRESH_STRATEGY_KEY,
) {
  constructor(
    @Inject(jwtConfig.KEY)
    private jwtConfiguration: ConfigType<typeof jwtConfig>,
    private jwtAuthService: JwtAuthService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromExtractors([
        (request: Request) => this.jwtAuthService.getRefreshToken(request),
      ]),
      secretOrKey: jwtConfiguration.secret ?? '',
      passReqToCallback: true,
    });
  }
  async validate(request: Request, payload: JwtPayload) {
    const refresh = this.jwtAuthService.getRefreshToken(request);
    if (!payload.sub || payload.type !== 'REFRESH') {
      throw new UnauthorizedException(new CodeError(AuthError.INVALID_TOKEN));
    }
    const account = await this.jwtAuthService.validateByRefresh(
      refresh,
      payload.sub,
      payload.exp ?? 0,
    );
    request.account = account;
    return account;
  }
}
