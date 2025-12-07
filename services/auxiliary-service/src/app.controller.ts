import { Controller, Get, Param } from '@nestjs/common';
import { AwsService } from './aws.service';

@Controller()
export class AppController {
  constructor(private readonly awsService: AwsService) {}

  @Get('health')
  health() {
    return {
      status: 'healthy',
      service: 'auxiliary-service',
      version: process.env.VERSION || '1.0.0',
    };
  }

  @Get('version')
  getVersion() {
    return {
      version: process.env.VERSION || '1.0.0',
      service: 'auxiliary-service',
    };
  }

  @Get('aws/buckets')
  async getBuckets() {
    try {
      const buckets = await this.awsService.listBuckets();
      return {
        buckets,
        version: process.env.VERSION || '1.0.0',
      };
    } catch (error) {
      return {
        error: error.message,
        version: process.env.VERSION || '1.0.0',
      };
    }
  }

  @Get('aws/parameters')
  async getParameters() {
    try {
      const parameters = await this.awsService.listParameters();
      return {
        parameters,
        version: process.env.VERSION || '1.0.0',
      };
    } catch (error) {
      return {
        error: error.message,
        version: process.env.VERSION || '1.0.0',
      };
    }
  }

  @Get('aws/parameters/:name')
  async getParameter(@Param('name') name: string) {
    try {
      // Ensure parameter name starts with /
      const parameterName = name.startsWith('/') ? name : `/${name}`;
      const parameter = await this.awsService.getParameter(parameterName);
      return {
        name: parameter.Name,
        value: parameter.Value,
        type: parameter.Type,
        version: process.env.VERSION || '1.0.0',
      };
    } catch (error: any) {
      if (error.name === 'ParameterNotFound') {
        return {
          error: `Parameter ${name} not found`,
          version: process.env.VERSION || '1.0.0',
        };
      }
      return {
        error: error.message || String(error),
        version: process.env.VERSION || '1.0.0',
      };
    }
  }
}

