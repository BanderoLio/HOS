import { Module } from '@nestjs/common';
import { AccountsService } from './accounts.service';

@Module({
  exports: [AccountsService],
  providers: [AccountsService],
})
export class AccountsModule {}
