import { AccountError } from '@app/accounts/enums/accounts-error.enum';

export const usernameAlreadyExistsErrorExample = {
  description: 'Username already exists',
  schema: {
    example: {
      code: AccountError.USERNAME_ALREADY_EXISTS,
      message: 'User with this username already exists',
    },
  },
};
