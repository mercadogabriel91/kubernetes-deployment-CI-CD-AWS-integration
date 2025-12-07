import { Injectable } from '@nestjs/common';
import { S3Client, ListBucketsCommand } from '@aws-sdk/client-s3';
import {
  SSMClient,
  DescribeParametersCommand,
  GetParameterCommand,
  ParameterNotFound,
} from '@aws-sdk/client-ssm';

@Injectable()
export class AwsService {
  private s3Client: S3Client;
  private ssmClient: SSMClient;

  constructor() {
    // Initialize AWS clients with credentials from environment or IAM role
    const region = process.env.AWS_DEFAULT_REGION || 'us-east-1';
    
    // AWS SDK will automatically use AWS_PROFILE if set, or default credentials
    const config: any = { region };
    
    // If AWS_PROFILE is set, the SDK will use it automatically from ~/.aws/credentials
    // No need to explicitly set it here - SDK reads AWS_PROFILE env var
    
    this.s3Client = new S3Client(config);
    this.ssmClient = new SSMClient(config);
  }

  async listBuckets(): Promise<string[]> {
    try {
      const command = new ListBucketsCommand({});
      const response = await this.s3Client.send(command);
      
      if (!response.Buckets) {
        return [];
      }
      
      return response.Buckets.map((bucket) => bucket.Name || '').filter(Boolean);
    } catch (error) {
      throw new Error(`Failed to list buckets: ${error.message}`);
    }
  }

  async listParameters(): Promise<string[]> {
    try {
      const command = new DescribeParametersCommand({});
      const response = await this.ssmClient.send(command);
      
      if (!response.Parameters) {
        return [];
      }
      
      return response.Parameters.map((param) => param.Name || '').filter(Boolean);
    } catch (error) {
      throw new Error(`Failed to list parameters: ${error.message}`);
    }
  }

  async getParameter(name: string): Promise<{
    Name: string;
    Value: string;
    Type: string;
  }> {
    try {
      const command = new GetParameterCommand({
        Name: name,
        WithDecryption: true,
      });
      
      const response = await this.ssmClient.send(command);
      
      if (!response.Parameter) {
        throw new Error(`Parameter ${name} not found`);
      }
      
      return {
        Name: response.Parameter.Name || name,
        Value: response.Parameter.Value || '',
        Type: response.Parameter.Type || 'String',
      };
    } catch (error: any) {
      if (error.name === 'ParameterNotFound' || error.Code === 'ParameterNotFound') {
        const notFoundError: any = new Error(`Parameter ${name} not found`);
        notFoundError.name = 'ParameterNotFound';
        throw notFoundError;
      }
      throw new Error(`Failed to get parameter: ${error.message || error}`);
    }
  }
}

