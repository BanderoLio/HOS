import { SetMetadata } from '@nestjs/common';

export const USE_AUTH_KEY = 'USE_AUTH';
export const UseAuth = (checkAuth: boolean = true) =>
  SetMetadata(USE_AUTH_KEY, checkAuth);
