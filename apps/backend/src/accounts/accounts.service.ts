import { CodeError } from '@app/common/errors/code.error';
import { PrismaService } from '@app/external/prisma/prisma.service';
import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { AccountError } from './enums/accounts-error.enum';
import type { CreateAccountDto } from './dto/create-account.dto';
import { compare, hash } from 'bcrypt';

@Injectable()
export class AccountsService {
  constructor(private readonly prismaService: PrismaService) {}

  async findById(id_account: string) {
    const account = await this.prismaService.account.findUnique({
      where: {
        id_account,
      },
      include: {
        roles: true,
      },
    });
    if (!account) {
      throw new NotFoundException(
        new CodeError(AccountError.ACCOUNT_NOT_FOUND),
      );
    }
    return account;
  }

  async create(createAccountDto: CreateAccountDto) {
    await this.checkUsername(createAccountDto.username);
    const account = await this.prismaService.account.create({
      data: {
        username: createAccountDto.username,
        password: await this.hashPassword(createAccountDto.password),
      },
      include: {
        roles: true,
      },
    });
    return account;
  }

  async findByCredentials(credentials: CreateAccountDto) {
    const account = await this.prismaService.account.findUnique({
      where: {
        username: credentials.username,
      },
      include: {
        roles: true,
      },
    });
    if (!account || !account.password) {
      return null;
    }
    const isPasswordValid = await compare(
      credentials.password,
      account.password,
    );
    if (!isPasswordValid) {
      return null;
    }
    return account;
  }

  private async hashPassword(password: string) {
    return await hash(password, 10);
  }

  private async checkUsername(username: string) {
    const account = await this.prismaService.account.findUnique({
      where: {
        username,
      },
    });
    if (account) {
      throw new ConflictException(
        new CodeError(AccountError.USERNAME_ALREADY_EXISTS),
      );
    }
  }
}
