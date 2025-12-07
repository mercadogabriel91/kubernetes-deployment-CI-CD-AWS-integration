import { Controller, Get, Param, HttpException, HttpStatus } from '@nestjs/common';
import { AuxiliaryService } from './auxiliary.service';

@Controller()
export class AppController {
  private readonly mainApiVersion: string;

  constructor(private readonly auxiliaryService: AuxiliaryService) {
    this.mainApiVersion = process.env.VERSION || '1.0.0';
  }

  @Get('health')
  health() {
    return {
      status: 'healthy',
      service: 'main-api',
      version: this.mainApiVersion,
    };
  }

  @Get('buckets')
  async listBuckets() {
    try {
      const buckets = await this.auxiliaryService.getBuckets();
      const auxiliaryVersion = await this.auxiliaryService.getAuxiliaryVersion();

      return {
        buckets,
        main_api_version: this.mainApiVersion,
        auxiliary_service_version: auxiliaryVersion,
      };
    } catch (error) {
      const auxiliaryVersion = await this.auxiliaryService.getAuxiliaryVersion();
      throw new HttpException(
        {
          error: error.message,
          main_api_version: this.mainApiVersion,
          auxiliary_service_version: auxiliaryVersion,
        },
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  @Get('parameters')
  async listParameters() {
    try {
      const parameters = await this.auxiliaryService.getParameters();
      const auxiliaryVersion = await this.auxiliaryService.getAuxiliaryVersion();

      return {
        parameters,
        main_api_version: this.mainApiVersion,
        auxiliary_service_version: auxiliaryVersion,
      };
    } catch (error) {
      const auxiliaryVersion = await this.auxiliaryService.getAuxiliaryVersion();
      throw new HttpException(
        {
          error: error.message,
          main_api_version: this.mainApiVersion,
          auxiliary_service_version: auxiliaryVersion,
        },
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  @Get('parameters/:name')
  async getParameter(@Param('name') name: string) {
    try {
      const parameter = await this.auxiliaryService.getParameter(name);
      const auxiliaryVersion = await this.auxiliaryService.getAuxiliaryVersion();

      return {
        name: parameter.name,
        value: parameter.value,
        type: parameter.type,
        main_api_version: this.mainApiVersion,
        auxiliary_service_version: auxiliaryVersion,
      };
    } catch (error) {
      const auxiliaryVersion = await this.auxiliaryService.getAuxiliaryVersion();
      
      if (error instanceof HttpException) {
        throw new HttpException(
          {
            error: error.message,
            main_api_version: this.mainApiVersion,
            auxiliary_service_version: auxiliaryVersion,
          },
          error.getStatus(),
        );
      }

      throw new HttpException(
        {
          error: error.message,
          main_api_version: this.mainApiVersion,
          auxiliary_service_version: auxiliaryVersion,
        },
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }
}

