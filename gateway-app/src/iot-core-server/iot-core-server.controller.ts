import { Controller, Post, Body, Param } from '@nestjs/common';
import { IotCoreServerService } from './iot-core-server.service';

@Controller('iot-core')
export class IotCoreServerController {
  constructor(private readonly iotCoreServerService: IotCoreServerService) {}

  @Post('shadow/:thingName')
  async updateDeviceShadow(
    @Param('thingName') thingName: string,
    @Body() state: any,
  ) {
    await this.iotCoreServerService.updateDeviceShadow(thingName, state);
    return { success: true };
  }
}
