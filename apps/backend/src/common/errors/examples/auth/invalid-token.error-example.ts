import { AuthError } from '@app/auth/enums/auth-error.enum';

export const invalidTokenErrorExample = {
  description: 'Invalid token',
  schema: {
    example: {
      code: AuthError.INVALID_TOKEN,
      message: 'Token is missing, expired, or malformed',
    },
  },
};
