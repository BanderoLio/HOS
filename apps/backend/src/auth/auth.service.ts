import { Inject, Injectable, UnauthorizedException } from '@nestjs/common';
import { AccountsService } from '@app/accounts/accounts.service';
import { CodeError } from '@app/common/errors/code.error';
import { AuthError } from './enums/auth-error.enum';
import { SignupDto } from './dto/signup.dto';
import { LoginDto } from './dto/login.dto';
import { JwtService } from '@nestjs/jwt';
import jwtConfig from '@app/config/jwt.config';
import type { ConfigType } from '@nestjs/config';
import { BlacklistService } from './jwt/blacklist.service';
import { JwtPayload } from './jwt/interfaces/jwt.interface';
import type { Account } from '@app/common/interfaces/account.interface';

@Injectable()
export class AuthService {
  constructor(
    private readonly accountsService: AccountsService,
    private readonly jwtService: JwtService,
    private readonly blacklistService: BlacklistService,
    @Inject(jwtConfig.KEY)
    private readonly jwtConfiguration: ConfigType<typeof jwtConfig>,
  ) {}

  async signUp(signupDto: SignupDto) {
    const account = await this.accountsService.create({
      ...signupDto,
    });
    return this.login({
      username: account.username,
      password: signupDto.password,
    });
  }

  async login(loginDto: LoginDto) {
    const account = await this.accountsService.findByCredentials(loginDto);
    if (!account) {
      throw new UnauthorizedException(
        new CodeError(AuthError.INVALID_CREDENTIALS),
      );
    }
    return this.tokensFromAccount(account);
  }
  async tokensFromAccount(account: Account) {
    const accessTokenTask = this.jwtService.signAsync(
      {
        sub: account.id_account,
        type: 'ACCESS',
      },
      {
        expiresIn: this.jwtConfiguration.accessExpIn,
      },
    );

    const refreshTokenTask = this.jwtService.signAsync(
      {
        sub: account.id_account,
        type: 'REFRESH',
      },
      {
        expiresIn: this.jwtConfiguration.refreshExpIn,
      },
    );
    const [accessToken, refreshToken] = await Promise.all([
      accessTokenTask,
      refreshTokenTask,
    ]);
    return {
      accessToken,
      refreshToken,
    };
  }

  async logout(refreshToken: string) {
    const payload = this.jwtService.decode<JwtPayload>(refreshToken);
    await this.blacklistService.addJwtToBlacklist(
      refreshToken,
      payload.exp ?? 0,
    );
  }
}
