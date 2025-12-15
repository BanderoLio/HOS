import { IsNotEmpty, IsString, MaxLength, MinLength } from 'class-validator';

export class CreateAccountDto {
  @IsString()
  @IsNotEmpty()
  @MinLength(3)
  @MaxLength(255)
  username: string;
  @IsString()
  @IsNotEmpty()
  @MinLength(3)
  @MaxLength(255)
  password: string;
}
