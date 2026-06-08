# Voxen 维讯

Voxen 是面向工业现场的 iOS 多模态异常识别应用，使用摄像头、语音识别、端侧规则和 Agent 将现场提报转换为结构化异常信息，并支持 RealityKit AR 空间标注。

## 主要能力

- 普通话、粤语、四川话、英语和越南语现场提报
- 摄像头与麦克风实时采集
- 端侧优先的异常分类与离线降级
- Agent 多模态补充判定
- ITSM、WMS、EAM、MES 异常流转
- RealityKit AR 异常位置标注

## 本地配置

1. 复制 `demo3/AgentSecrets.sample.plist` 为 `demo3/AgentSecrets.plist`。
2. 在本地文件中填写 Agent 和语音识别配置。
3. 不要提交 `AgentSecrets.plist`，该文件已被 `.gitignore` 排除。

## 运行环境

- Xcode 26.5 或兼容版本
- iOS 26.5 或项目当前配置的部署目标
- 真机运行摄像头、麦克风和 AR 功能
