import { Inject, Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import jwtConfig from '@app/config/jwt.config';
import type { ConfigType } from '@nestjs/config';
import { AuthError } from '../enums/auth-error.enum';
import { CodeError } from '@app/common/errors/code.error';
import { JwtAuthService } from './jwt-auth.service';
import type { JwtPayload } from './interfaces/jwt.interface';

export const JWT_STRATEGY_KEY = 'jwt';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy, JWT_STRATEGY_KEY) {
  constructor(
    private jwtAuthService: JwtAuthService,
    @Inject(jwtConfig.KEY)
    private jwtConfiguration: ConfigType<typeof jwtConfig>,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      secretOrKey: jwtConfiguration.secret,
    });
  }

  async validate(payload: JwtPayload) {
    if (!payload.sub) {
      throw new UnauthorizedException(new CodeError(AuthError.INVALID_TOKEN));
    }
    return await this.jwtAuthService.validateAccountById(payload.sub);
  }
}
