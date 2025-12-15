import {
  Body,
  Controller,
  Inject,
  Post,
  Req,
  Res,
  UseGuards,
} from '@nestjs/common';
import { LoginDto } from './dto/login.dto';
import { AuthService } from './auth.service';
import { SignupDto } from './dto/signup.dto';
import { AuthResponseDto } from './dto/auth-response.dto';
import type { CookieOptions, Request, Response } from 'express';
import jwtConfig from '@app/config/jwt.config';
import { ConfigService, type ConfigType } from '@nestjs/config';
import {
  ApiBody,
  ApiConflictResponse,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { UseAuth } from './jwt/jwt-auth.decorator';
import { usernameAlreadyExistsErrorExample } from '@app/common/errors/examples/accounts/username-already-exists.error-example';
import { invalidTokenErrorExample } from '@app/common/errors/examples/auth/invalid-token.error-example';
import { invalidCredentialsErrorExample } from '@app/common/errors/examples/auth/invalid-credentials.error-example';
import { JwtRefreshGuard } from './jwt/jwt-auth-refresh.guard';
import { GetAccount } from './auth.decorator';
import type { Account } from '@app/common/interfaces/account.interface';

@UseAuth(false)
@Controller('auth')
export class AuthController {
  constructor(
    private readonly authService: AuthService,
    private readonly configService: ConfigService,
    @Inject(jwtConfig.KEY)
    private readonly jwtConfiguration: ConfigType<typeof jwtConfig>,
  ) {}

  @ApiBody({
    type: LoginDto,
  })
  @ApiUnauthorizedResponse(invalidCredentialsErrorExample)
  @Post('login')
  async login(
    @Body() loginDto: LoginDto,
    @Res({ passthrough: true }) res: Response,
  ) {
    const { accessToken, refreshToken } =
      await this.authService.login(loginDto);
    return this.setTokens(res, accessToken, refreshToken);
  }

  @Post('signup')
  @ApiConflictResponse(usernameAlreadyExistsErrorExample)
  async signUp(@Body() signupDto: SignupDto) {
    return new AuthResponseDto({
      accessToken: (await this.authService.signUp(signupDto)).accessToken,
    });
  }

  @Post('logout')
  @ApiUnauthorizedResponse(invalidTokenErrorExample)
  async logout(@Req() req: Request, @Res({ passthrough: true }) res: Response) {
    const refresh = req.signedCookies[
      this.jwtConfiguration.refreshTokenCookieKey
    ] as string | undefined;
    if (refresh) {
      await this.authService.logout(refresh);
      res.clearCookie(
        this.jwtConfiguration.refreshTokenCookieKey,
        // must be identical for some reason
        this.getRefreshCookieOptions(),
      );
    }
  }

  @UseGuards(JwtRefreshGuard)
  @Post('refresh')
  async refresh(
    @Res({ passthrough: true }) res: Response,
    @GetAccount() account: Account,
  ) {
    const { accessToken, refreshToken } =
      await this.authService.tokensFromAccount(account);
    return this.setTokens(res, accessToken, refreshToken);
  }

  private getRefreshCookieOptions(): CookieOptions {
    return {
      signed: true,
      httpOnly: true,
      secure: this.configService.get('NODE_ENV') === 'production',
    };
  }
  private setTokens(res: Response, accessToken: string, refreshToken: string) {
    res.cookie(
      this.jwtConfiguration.refreshTokenCookieKey,
      refreshToken,
      this.getRefreshCookieOptions(),
    );
    return new AuthResponseDto({ accessToken });
  }
}
