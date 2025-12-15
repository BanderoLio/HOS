import type { Account } from './common/interfaces/account.interface';

declare module 'express' {
  export interface Request {
    account?: Account;
  }
}
