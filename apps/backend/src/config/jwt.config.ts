import { registerAs } from '@nestjs/config';
import { type StringValue } from 'ms';

// TODO separate into jwt module and jwt configs
export default registerAs('jwt', () => ({
  secret: process.env.JWT_SECRET ?? 'c2ff690ee404f4c48663330c31829117',
  accessExpIn: <StringValue>(process.env.ACCESS_TOKEN_EXP ?? '15m'),
  refreshExpIn: <StringValue>(process.env.REFRESH_TOKEN_EXP ?? '7d'),
  refreshTokenCookieKey: 'refreshToken',
}));
