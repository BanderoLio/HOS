import { Injectable, type ExecutionContext } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AuthGuard } from '@nestjs/passport';
import { USE_AUTH_KEY } from './jwt-auth.decorator';

@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {
  constructor(private reflector: Reflector) {
    super();
  }

  canActivate(context: ExecutionContext) {
    const useAuth = this.reflector.getAllAndOverride<boolean | undefined>(
      USE_AUTH_KEY,
      [context.getHandler(), context.getClass()],
    );
    if (useAuth === false) {
      return true;
    }
    return super.canActivate(context);
  }
}
