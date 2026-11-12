# Necrosis 无限版 —《魔兽世界：无限》插件移植

将经典术士插件 **Necrosis LdC 3.1**（2010，Cata 4.0 API）移植到
**《魔兽世界：无限》（WoW Forever，1.60.x，Mainline 代码库 / GameType = camelot）**。
含完整中文本地化（zhCN / zhTW）。

## 功能

- 术士中央球体：灵魂碎片计数（按背包物品 6265 统计）、生命石 / 灵魂石管理
- 恶魔 / 诅咒 / Buff 环形菜单、坐骑按钮、法术计时条
- 暗影冥思 / 反冲警报、反恐惧提示、放逐计时
- 一键制作 / 使用石头、自动交易生命石、语音提示
- `/necrosis` 打开设置面板

## 安装

1. 把 `Necrosis/` 文件夹放进游戏 `Interface\AddOns\`（覆盖前先删除旧文件夹）
2. 重启游戏，角色选择界面确认插件已启用（**必须是术士角色**）
3. 登录后聊天栏应显示：`[Necrosis] 无限服直连版已加载`

TOC 的 `## Interface: 16001`（= 1.60.1）。客户端升级后若显示过期，用
`/run print(select(4, GetBuildInfo()))` 的输出替换两个 `.toc` 里的 Interface 值。
目录内附带 `Necrosis_Camelot.toc`（无限客户端优先识别 `_Camelot` 后缀）。

## 移植 / 修改进度日志

### 1. 载入层
- **去除 UTF-8 BOM**：原版 7 个文件（Spells.lua、Bindings.lua 等）带 BOM，标准 Lua 5.1 直接语法报错、插件无法加载
- **`## Interface` 改为 16001** 并提供 `_Camelot.toc` 双保险
- **`GetAddOnMetadata` 已移除**（仅剩 `C_AddOns.GetAddOnMetadata`）：返回 nil 后 `Necrosis.Data.Label` 拼接崩溃，导致 `Necrosis.Translation` 从未创建、全部本地化炸掉 → 已做 C_AddOns 优先 + 老 API 兜底 + `tostring` 防 nil

### 2. API 迁移（老全局 → 现代 C_ 命名空间）
采用**各文件顶部局部函数**直连现代 API（局部变量只在本文件可见，不修改任何全局、不触碰 Frame 元表、不包装 `CreateFrame`）：

| 老调用（保持不变） | 直连实现 |
|---|---|
| `GetSpellInfo`（老多返回值签名） | `C_Spell.GetSpellInfo`（返回表）+ `C_Spell.GetSpellPowerCost` |
| `GetSpellCooldown` | `C_Spell.GetSpellCooldown` |
| `UnitBuff` / `UnitDebuff` | `C_UnitAuras.GetAuraDataByIndex` |
| `UnitMana` / `UnitManaMax` | `UnitPower` / `UnitPowerMax` |
| `GetNumPartyMembers` / `GetNumRaidMembers` | `UnitInRaid` / `UnitInParty` 近似 |
| `SendChatMessage` | `C_ChatInfo.SendChatMessage` |
| `GetCompanionInfo` 等坐骑 API | `C_MountJournal.*` |
| `GetContainerNumSlots` 等背包 API | `C_Container.*` |
| `AcceptTrade` / `DropItemOnUnit` | `C_SecureTransfer` / `C_Item` |
| `NecrosisTooltip:SetBagItem` | 局部 `SetTooltipBagItem`（SetHyperlink 兜底） |
| `SetBackdrop`（10.0 移除） | 纹理直接实现 |
| `CompanionButtonTemplate`（已移除） | `UICheckButtonTemplate` |

其他：事件更名（`UNIT_POWER`→`UNIT_POWER_UPDATE`、`LEARNED_SPELL_IN_TAB`→`SPELLS_CHANGED`）、
战斗日志改 `CombatLogGetCurrentEventInfo`、施法事件新载荷适配、法术扫描改 `C_SpellBook`、
机密值（secret values）防护、受保护动作（交易拾取）加战斗/失败守卫。

> 注：早期版本曾用"全局兼容层"（覆盖全局函数 + Frame 元表 + CreateFrame 包装）实现，
> 会污染安全框架并触发 `ADDON_ACTION_FORBIDDEN`（插件被客户端强制禁用），已废弃该方案。

### 3. 安全按钮 / 点击修复（无限客户端特有的受限执行环境）
- **`table.new` 问题**：安全片段（`_onclick`/`Execute`）里 `table.new(...)` 的语义与受限环境不符；
  同时受限环境**禁止 `{}` 直接建表**（`Direct table creation is not permitted`）→ 采用受限环境认可的 `table.new(...)`
- **球体按钮属性为空（点击无反应的根因）**：默认 `MainSpell = 53`（灵魂灼烧 74434，大灾变法术）
  在 60 级服不存在 → 法术名为 nil → `type1/spell` 属性从未设置 → 已加"回退到第一个已学会法术"逻辑
- 菜单 `state` / `_onclick` 属性恢复生效，菜单可正常展开/收起

### 4. 悬浮提示修复
- `TooltipData["SpellTimer"]` 缺少 `Label` 字段（原版潜伏 bug）→ 补齐 + 入口兜底
- 石头不在背包时 `SetBagItem` 收到空坐标 → 坐标校验
- 法力值拼接 nil 保护

### 5. 诊断工具（保留）
- 登录自检输出（构建号、初始化状态、非法术角色提示）
- 按钮 OnEnter/OnMouseDown/OnMouseUp/OnClick 探针（黄色 `[Necrosis诊断]` 输出，限量打印）

全部 39 个 Lua 文件已用 **标准 Lua 5.1 编译器**校验通过。

## 已知限制

- 法术表是 4.0 时代 ID；60 级存在的法术（暗影箭 686、恐惧 5782、放逐 710 等）正常，
  TBC/WotLK 独有法术（恶魔守卫、变身等）自动隐藏对应按钮
- 音效依赖客户端 `PlaySoundFile`，缺失时静默跳过
- 选项面板的 `OptionsButtonTemplate` / `OptionsSliderTemplate` 等老模板理论上随 Mainline
  代码库保留；若打开设置报错可再做无模板替换

## 命令

| 命令 | 作用 |
|---|---|
| `/necrosis` | 打开设置 |
| `/necrosis lock` / `unlock` | 锁定 / 解锁按钮位置 |

## 版权

原作 © Lomig、Liadora、Nyx 等，GPL v2（见 `Necrosis/GPL V2.txt`）。
本仓库为 API 兼容移植，未新增功能，遵循 GPL v2 发布。
