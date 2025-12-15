import { AccountError } from '@app/accounts/enums/accounts-error.enum';

export const accountNotFoundErrorExample = {
  description: 'Account not found',
  schema: {
    example: {
      code: AccountError.ACCOUNT_NOT_FOUND,
      message: 'Account with given id was not found',
    },
  },
};
