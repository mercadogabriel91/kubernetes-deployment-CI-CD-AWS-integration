import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AppController } from './app.controller';
import { AwsService } from './aws.service';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '../.env', // Shared .env file at services root
    }),
  ],
  controllers: [AppController],
  providers: [AwsService],
})
export class AppModule {}

