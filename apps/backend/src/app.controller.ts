import { Controller, Get } from '@nestjs/common';
import { ACCESS_TOKEN_AUTH } from './config/constants';
import { ApiBearerAuth } from '@nestjs/swagger';

@ApiBearerAuth(ACCESS_TOKEN_AUTH)
@Controller()
export class AppController {
  @Get()
  test() {
    return {
      hello: 'hello',
    };
  }
}
