# 贡献指南

感谢你考虑为 godot_core_system 做出贡献！

## 行为准则

本项目采用[贡献者公约](CODE_OF_CONDUCT.md)。参与本项目即表示你同意遵守其条款。

## 如何贡献

### 报告 Bug

1. 使用 GitHub 的[issue tracker](https://github.com/Liweimin0512/godot_core_system/issues)
2. 检查是否已经存在相同的 issue
3. 如果没有，创建一个新的 issue，包含：
   - 清晰的标题和描述
   - 重现步骤
   - 期望的行为
   - 实际的行为
   - Godot 版本和操作系统信息
   - 相关的代码片段或截图

### 提出新功能

1. 先在 issues 中提出建议
2. 说明这个功能解决什么问题
3. 描述你设想的实现方式
4. 等待社区反馈和讨论

### 提交代码

1. Fork 本仓库
2. 创建你的特性分支：`git checkout -b feature/AmazingFeature`
3. 提交你的修改：`git commit -m 'Add some AmazingFeature'`
4. 推送到分支：`git push origin feature/AmazingFeature`
5. 创建 Pull Request

### 代码风格

- 遵循[GDScript 风格指南](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
- 使用 Tab 进行缩进
- 类名使用 PascalCase
- 函数和变量名使用 snake_case
- 常量使用 SCREAMING_SNAKE_CASE
- 添加适当的注释和文档字符串

### 提交信息规范

使用清晰的提交信息，格式如下：

```xml

<类型>: <描述>

[可选的详细描述]

[可选的关闭issue引用]
```

类型包括：

- feat: 新功能
- fix: Bug 修复
- docs: 文档更新
- style: 代码风格修改
- refactor: 代码重构
- test: 测试相关
- chore: 构建过程或辅助工具的变动

例如：

```xml

feat: 添加主题切换动画

添加了在切换主题时的渐变动画效果，提升用户体验。

Closes #123
```

### 文档

- 为新功能编写文档
- 更新受影响的文档
- 使用清晰的中文描述
- 包含代码示例

### 测试

- 添加适当的测试用例
- 确保所有测试通过
- 测试覆盖主要功能点

## 发布流程

1. 版本号遵循[语义化版本](https://semver.org/lang/zh-CN/)
2. 更新 CHANGELOG.md
3. 创建新的发布标签
4. 编写发布说明

## 问题讨论

- 使用 GitHub Discussions 进行讨论
- 保持友善和专业
- 尊重他人观点
- 聚焦于技术讨论

## 审查标准

Pull Request 在合并前需要满足：

1. 通过所有测试
2. 符合代码规范
3. 有适当的文档
4. 至少一个维护者审查通过
5. 没有未解决的问题

## 许可

贡献的代码将采用 MIT 许可证。
