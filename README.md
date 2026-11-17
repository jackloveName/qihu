# 栖护 iOS App


## 运行

```bash
flutter pub get
flutter run -d ios
```

## 验证

```bash
flutter analyze
flutter test
flutter build ios --release --no-codesign
```

界面文字使用 iOS 系统字体，不随安装包分发完整中文字体。
仅有 PDF 导出使用经过 GB2312、ASCII 与常用标点裁剪的
`assets/fonts/NotoSansSC-ReportSubset.ttf`。

## 协议与游客模式

- 隐私政策和平台注册协议仅读取后台配置，App 不内置兜底条款。
- 游客模式无需勾选协议即可进入；会员登录仍需主动勾选同意。
- 会员协议版本升级后会要求重新确认，游客模式不受影响。

## 本地数据

- 本地状态写入使用串行合并队列，连续修改会保留最后一次快照。
- 任务明细默认保留最近 180 天，避免历史数据无限增长。
- 注销本机数据时会清理 App 创建的头像、宠物照片和健康照片。
- iOS 最多安排 60 条待处理通知，并优先保留库存与健康复看提醒。
- 会员资料引导只在首次登录时出现，后续登录直接进入首页。
- 游客最多添加 3 只动物，数据保留 3 天；会员登录时会清空游客数据和图片。

## 城市数据

- 城市选择使用可获取的 2025–2026 年行政区划页面整理的地级城市清单，共 34 个省级区域、340 个城市入口。
- 选择器支持按城市或省份搜索，数据随 App 离线提供。
- 天气查询会通过公开地理编码服务解析所选城市坐标，再读取公开天气数据。

## App 更新

- 自动检查失败只记录调试日志；手动检查会明确提示已是最新版本或检查失败。
- iOS 使用 `iosAppVersion`、`iosAppDownloadUrl`、`iosUpdateType` 和 `iosVersionDesc`。
- Android 使用 `androidVersion`、`androidAppDownloadUrl`、`androidUpdateType` 和 `androidVersionDesc`。
- `androidUpdateWay=2` 或 `androidUpdateMode=2` 时使用应用内下载安装，其他值使用浏览器下载。
- 应用内更新会显示下载进度、调用系统安装器，并在安装页面返回后自动重启。
- `*UpdateType=2` 为强制更新，弹窗始终显示“必须更新”提示。

1、游客模式不需要同意隐私政策和平台注册协议
