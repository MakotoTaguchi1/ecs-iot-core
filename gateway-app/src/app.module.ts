import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { IotCoreServerController } from './iot-core-server/iot-core-server.controller';
import { IotCoreServerService } from './iot-core-server/iot-core-server.service';

@Module({
  imports: [],
  controllers: [AppController, IotCoreServerController],
  providers: [AppService, IotCoreServerService],
})
export class AppModule {}
