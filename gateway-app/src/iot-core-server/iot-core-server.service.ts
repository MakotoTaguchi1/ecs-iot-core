import {
  Injectable,
  OnModuleInit,
  OnModuleDestroy,
  Logger,
} from '@nestjs/common';
import { mqtt, iot, iotshadow } from 'aws-iot-device-sdk-v2';

@Injectable()
export class IotCoreServerService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(IotCoreServerService.name);
  private connection: mqtt.MqttClientConnection;
  private shadowClient: iotshadow.IotShadowClient;

  constructor() {
    this.logger = new Logger(IotCoreServerService.name);

    // 環境変数のチェック
    if (!process.env.AWS_IOT_ENDPOINT) {
      this.logger.error('AWS_IOT_ENDPOINT is not set');
      return;
    }
    if (!process.env.CERTIFICATE) {
      this.logger.error('CERTIFICATE is not set');
      return;
    }
    if (!process.env.PRIVATE_KEY) {
      this.logger.error('PRIVATE_KEY is not set');
      return;
    }

    try {
      const config = iot.AwsIotMqttConnectionConfigBuilder.new_mtls_builder(
        process.env.CERTIFICATE,
        process.env.PRIVATE_KEY,
      )
        .with_endpoint(process.env.AWS_IOT_ENDPOINT)
        .build();

      const client = new mqtt.MqttClient();
      this.connection = client.new_connection(config);
      this.shadowClient = new iotshadow.IotShadowClient(this.connection);
    } catch (error) {
      this.logger.error('Failed to initialize IoT Core service', error);
    }
  }

  /**
   * NestJSモジュールの初期化時に実行されます
   * AWS IoT Coreへの接続を確立し、シャドウトピックの購読を開始します
   */
  async onModuleInit() {
    try {
      this.logger.log('Attempting to connect to AWS IoT Core...');
      this.logger.log(`Endpoint: ${process.env.AWS_IOT_ENDPOINT}`);
      await this.connection.connect();
      this.logger.log('Connected to AWS IoT Core');
      await this.subscribeToShadowTopics();
    } catch (err) {
      this.logger.error('Failed to initialize IoT Core connection', err);
      throw err;
    }
  }

  /**
   * NestJSモジュールの破棄時に実行されます
   * AWS IoT Coreとの接続を安全に切断します
   */
  async onModuleDestroy() {
    try {
      await this.connection.disconnect();
      this.logger.log('Disconnected from AWS IoT Core');
    } catch (err) {
      this.logger.error('Error during disconnect', err);
    }
  }

  /**
   * デバイスシャドウの更新通知を購読します
   * 更新の成功と失敗の両方のトピックを監視します
   */
  private async subscribeToShadowTopics(): Promise<void> {
    try {
      await this.shadowClient.subscribeToUpdateShadowAccepted(
        { thingName: '+' },
        mqtt.QoS.AtLeastOnce,
        (error, response) => {
          if (error) {
            this.logger.error('Error in shadow update accepted', error);
            return;
          }
          this.handleShadowUpdate(response);
        },
      );

      await this.shadowClient.subscribeToUpdateShadowRejected(
        { thingName: '+' },
        mqtt.QoS.AtLeastOnce,
        (error) => {
          if (error) {
            this.logger.error('Shadow update rejected', error);
          }
        },
      );

      this.logger.log('Subscribed to shadow topics');
    } catch (err) {
      this.logger.error('Failed to subscribe to shadow topics', err);
      throw err;
    }
  }

  /**
   * シャドウの更新通知を受信した際の処理を行います
   * desired stateが含まれている場合、デバイスへのコマンド送信を試みます
   * @param response シャドウ更新の応答データ
   */
  private handleShadowUpdate(response: any): void {
    try {
      const { state, clientToken, timestamp, thingName } = response;
      if (state?.desired) {
        this.logger.debug('Shadow update received:', {
          thingName,
          clientToken,
          timestamp,
          state: state.desired,
        });
        this.sendCommandToDevice(state.desired);
      }
    } catch (err) {
      this.logger.error('Error handling shadow update', err);
    }
  }

  /**
   * デバイスへコマンドを送信します
   * 現在は実装が保留されており、受信したコマンドのログ出力のみを行います
   * @param command デバイスへ送信するコマンド
   */
  private async sendCommandToDevice(command: any): Promise<void> {
    try {
      this.logger.log('Command received for device:', {
        command,
        timestamp: new Date().toISOString(),
      });
    } catch (err) {
      this.logger.error('Error processing device command', err);
    }
  }

  /**
   * 指定されたデバイスのシャドウ状態を更新します
   * デバイスの報告された状態（reported state）を更新します
   * @param thingName 更新対象のデバイス名
   * @param state 更新する状態データ
   */
  async updateDeviceShadow(thingName: string, state: any): Promise<void> {
    try {
      await this.shadowClient.publishUpdateShadow(
        {
          thingName,
          state: {
            reported: state,
          },
        },
        mqtt.QoS.AtLeastOnce,
      );

      this.logger.log(`Updated shadow for ${thingName}:`, state);
    } catch (err) {
      this.logger.error(`Failed to update shadow for ${thingName}`, err);
      throw err;
    }
  }
}
