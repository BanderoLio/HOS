import { createParamDecorator, type ExecutionContext } from '@nestjs/common';
import type { Request } from 'express';

export const GetAccount = createParamDecorator(
  (_, context: ExecutionContext) => {
    const req = context.switchToHttp().getRequest<Request>();
    return req.account;
  },
);
