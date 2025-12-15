import { Catch, HttpException, type ArgumentsHost } from '@nestjs/common';
import { BaseExceptionFilter } from '@nestjs/core';
import { CodeError } from './errors/code.error';

@Catch(HttpException)
export class CodeErrorFilter extends BaseExceptionFilter {
  catch(exception: HttpException, host: ArgumentsHost) {
    const res = exception.getResponse();
    if (typeof res === 'object' && res instanceof CodeError) {
      if (!res.message) {
        res.message = exception.message;
      }
      if (!res.statusCode) {
        res.statusCode = exception.getStatus();
      }
    }
    return super.catch(exception, host);
  }
}
