import { CodeError } from '@app/common/errors/code.error';
import {
  Inject,
  Injectable,
  Logger,
  UnauthorizedException,
} from '@nestjs/common';
import type { Request } from 'express';
import { AuthError } from '../enums/auth-error.enum';
import { AccountsService } from '@app/accounts/accounts.service';
import { BlacklistService } from './blacklist.service';
import jwtConfig from '@app/config/jwt.config';
import type { ConfigType } from '@nestjs/config';

@Injectable()
export class JwtAuthService {
  private readonly logger = new Logger(JwtAuthService.name);
  constructor(
    private readonly accountsService: AccountsService,
    private readonly blacklistService: BlacklistService,
    @Inject(jwtConfig.KEY)
    private readonly jwtConfiguration: ConfigType<typeof jwtConfig>,
  ) {}

  async validateAccountById(accountId: string) {
    this.logger.log(`Validating account by ID ${accountId}`);
    return await this.accountsService.findById(accountId);
  }

  async validateByRefresh(
    refreshToken: string,
    id_account: string,
    expires: number,
  ) {
    const inBlacklist =
      await this.blacklistService.isTokenInBlacklist(refreshToken);
    if (inBlacklist) {
      throw new UnauthorizedException(new CodeError(AuthError.INVALID_TOKEN));
    }
    await this.blacklistService.addJwtToBlacklist(refreshToken, expires);
    this.logger.log(`Validating refresh token for account ${id_account}`);
    return this.validateAccountById(id_account);
  }

  getRefreshToken(request: Request) {
    const refresh = request.signedCookies[
      this.jwtConfiguration.refreshTokenCookieKey
    ] as string | undefined;
    if (!refresh) {
      throw new UnauthorizedException(new CodeError(AuthError.INVALID_TOKEN));
    }
    return refresh;
  }
}
