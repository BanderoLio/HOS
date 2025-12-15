import type { AccountGetPayload } from '@orm/models';

export type Account = AccountGetPayload<{
  include: {
    roles: true;
  };
}>;
