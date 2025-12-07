import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { HttpModule } from '@nestjs/axios';
import { AppController } from './app.controller';
import { AuxiliaryService } from './auxiliary.service';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '../.env', // Shared .env file at services root
    }),
    HttpModule,
  ],
  controllers: [AppController],
  providers: [AuxiliaryService],
})
export class AppModule {}

