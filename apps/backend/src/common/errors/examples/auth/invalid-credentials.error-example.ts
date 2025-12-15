import { AuthError } from '@app/auth/enums/auth-error.enum';

export const invalidCredentialsErrorExample = {
  description: 'Invalid credentials',
  schema: {
    example: {
      code: AuthError.INVALID_CREDENTIALS,
      message: 'Email or password is incorrect',
    },
  },
};
