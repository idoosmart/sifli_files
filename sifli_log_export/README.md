# Sifli log export

### Android:

```java
//init
SFReaderManager.getInstance().init(context)
//Asset log:
SFReaderManager.getInstance().setManagerCallback()
SFReaderManager.getInstance().readAssetRequest(logDir,deviceMac)
  
//Serial port log：
SFReaderManager.getInstance().setManagerCallback()
SFReaderManager.getInstance().readLogRequest(logDir,deviceMac)
```



### iOS:

参考IDOSFReaderManager.h