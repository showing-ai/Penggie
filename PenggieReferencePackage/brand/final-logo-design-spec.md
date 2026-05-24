# ShowCLI 品牌视觉系统

ShowCLI 最终品牌系统由 Penggie 图标和 ShowCLI 字标组成。Penggie 负责快速图形识别，ShowCLI 字标负责产品名称识别。

## 核心概念

Penggie 是 ShowCLI 的产品识别符号：一个带有终端气质的像素企鹅。它不是写实插画，而是把 agent、CLI、TUI 和 friendly tool 压缩成一个可缩放的几何图形。

- Agent / CLI：竖向光标块眼睛表达 terminal、prompt 和 agent 工作状态。
- Friendly Tool：紧凑企鹅轮廓降低传统命令行工具的冷硬感。
- Pixel Product DNA：身体、眼睛、嘴和脚保持块状几何，和 terminal grid 直接关联。

## 图标规格

```text
viewBox: 0 0 100 100
Body:  x=20-80, y=22-75
Wings: y=39-56, eased 0.4px joints into body
Face:  x=28, y=32, w=44, h=30, rx=0.4
Eyes:  6x9 vertical cursor blocks
Beak:  single-piece sharp T path
Feet:  12x6, rx=0.4, y=74-80, drawn behind body
```

关键决定：

- 圆角统一为 `0.4`，保留像素感，同时避免翅膀与身体连接处出现尖角。
- 脚绘制在身体后方，身体压住脚顶部 1px，连接关系更自然。
- 嘴巴使用单个 T 形 path，避免上下喙出现渲染分割线。
- 不增加独立腿部结构，保持小尺寸可读性。

## 颜色系统

```text
Body gray:   #707070
Face:        #FAFAF7
Ink:         #1A1A1A
Logo accent: #CC6B2C
Dark accent: #E8773C
Text accent: #9B471A
Cream body:  #EDEAE2
```

橙色 `#CC6B2C` 保留为标识色和大尺寸强调色；小字号文本使用 `#9B471A`，避免浅色背景上的对比不足。

## 字标系统

品牌名必须连续写作：

```text
ShowCLI
```

正式字标已转换为 SVG path，不依赖运行环境字体。canonical 资产为：

```text
wordmark/showcli-wordmark-horizontal.svg
wordmark/showcli-wordmark-dark-horizontal.svg
wordmark/showcli-wordmark-stacked.svg
```

使用建议：

- 标准横向字标：默认品牌露出，用于官网页眉、文档封面和产品介绍。
- 深色横向字标：用于深色主题、社交图和发布图。
- 堆叠组合字标：用于启动页、中心构图和垂直空间。

## 资产层级

正式图标：

```text
penggie-logo-light.svg
penggie-logo-light-preview.png
penggie-logo-dark.svg
penggie-logo-dark-preview.png
```

静态图标：

```text
penggie-logo-light-static.svg
penggie-logo-light-static-preview.png
penggie-logo-dark-static.svg
penggie-logo-dark-static-preview.png
```

平台与入口资产：

```text
penggie-brand-tile-dark.svg
penggie-brand-tile-dark-preview.png
penggie-app-icon-macos.svg
penggie-app-icon-macos-preview.png
penggie-app-icon-macos-1024.png
penggie-favicon.svg
penggie-favicon-32.png
penggie-favicon-16.png
```

正式字标：

```text
wordmark/showcli-wordmark-horizontal.svg
wordmark/showcli-wordmark-horizontal.png
wordmark/showcli-wordmark-dark-horizontal.svg
wordmark/showcli-wordmark-dark-horizontal.png
wordmark/showcli-wordmark-stacked.svg
wordmark/showcli-wordmark-stacked.png
wordmark/showcli-wordmark-showcase.html
wordmark/showcli-wordmark-overview.png
```

探索稿归档在：

```text
wordmark/explorations/
```

探索稿只作为过程记录，不进入主品牌系统。

## 使用规则

- 不要改变浅色和深色版本的 Penggie 几何比例。
- 不要把品牌名拆开写，必须写作 `ShowCLI`。
- 不要新增腿部、羽毛、阴影、高光或复杂表情。
- 低于 32px 时优先使用静态版本，避免 blink 动效影响识别。
- 小字号文本不要直接使用 `#CC6B2C`，改用 `#9B471A`。

## 设计结论

最终 Logo 的方向是：terminal-native、friendly、compact、pixel-aware。它不靠复杂插画建立记忆点，而是用块状身体、终端光标眼睛、T 形嘴、短而稳的脚形成稳定识别。浅色版本负责通用品牌露出，深色版本和平台图标负责高对比入口。
