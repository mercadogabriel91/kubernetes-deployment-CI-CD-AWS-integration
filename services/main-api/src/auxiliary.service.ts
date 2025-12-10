import { Injectable, HttpException, HttpStatus } from "@nestjs/common";
import { HttpService } from "@nestjs/axios";
import { firstValueFrom } from "rxjs";
import { AxiosError } from "axios";

@Injectable()
export class AuxiliaryService {
  private readonly baseUrl: string;

  constructor(private readonly httpService: HttpService) {
    this.baseUrl = process.env.AUXILIARY_SERVICE_URL || "http://localhost:3001";
  }

  async getVersion(): Promise<string> {
    try {
      const response = await firstValueFrom(
        this.httpService.get(`${this.baseUrl}/version`)
      );
      return response.data.version || "unknown";
    } catch (error) {
      return "unknown";
    }
  }

  async getBuckets(): Promise<string[]> {
    try {
      const response = await firstValueFrom(
        this.httpService.get(`${this.baseUrl}/aws/buckets`)
      );
      return response.data.buckets || [];
    } catch (error) {
      const axiosError = error as AxiosError;
      throw new HttpException(
        `Failed to retrieve buckets from auxiliary service: ${axiosError.message}`,
        HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  async getParameters(): Promise<string[]> {
    try {
      const response = await firstValueFrom(
        this.httpService.get(`${this.baseUrl}/aws/parameters`)
      );
      return response.data.parameters || [];
    } catch (error) {
      const axiosError = error as AxiosError;
      throw new HttpException(
        `Failed to retrieve parameters from auxiliary service: ${axiosError.message}`,
        HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  async getParameter(name: string): Promise<{
    name: string;
    value: string;
    type: string;
  }> {
    try {
      // Use query parameter to handle parameter names with slashes
      const response = await firstValueFrom(
        this.httpService.get(`${this.baseUrl}/aws/parameters`, {
          params: {
            name: name,
          },
        })
      );
      return {
        name: response.data.name,
        value: response.data.value,
        type: response.data.type,
      };
    } catch (error) {
      const axiosError = error as AxiosError;
      if (axiosError.response?.status === 404) {
        throw new HttpException(
          `Parameter ${name} not found`,
          HttpStatus.NOT_FOUND
        );
      }
      throw new HttpException(
        `Failed to retrieve parameter from auxiliary service: ${axiosError.message}`,
        HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  async getAuxiliaryVersion(): Promise<string> {
    try {
      const response = await firstValueFrom(
        this.httpService.get(`${this.baseUrl}/version`)
      );
      return response.data.version || "unknown";
    } catch (error) {
      return "unknown";
    }
  }
}
