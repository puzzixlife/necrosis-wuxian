# Necrosis 无限版（《魔兽世界：无限》移植）

**Necrosis LdC 3.1**（经典术士界面与灵魂碎片管理插件，原作 Lomig & Arpharazon，
Cata 4.0 版源码）→ **《魔兽世界：无限》（WoW Forever，1.60.x，Mainline 代码库 / camelot）**
移植版。带完整中文（zhCN/zhTW）本地化。

> v2 变更：**彻底移除兼容层**。上一版的 Compat.lua 通过覆盖全局函数、修改 Frame
> 元表、包装 `CreateFrame` 来还原老 API——这会污染安全框架，触发客户端的
> `ADDON_ACTION_FORBIDDEN`（"Necrosis已被禁用，因为该功能只对暴雪的UI开放"）。
> 现在全部改为**各文件内的局部直连函数**：不修改任何全局、不触碰元表、不包装
> CreateFrame，所有调用直接落到现代 C_ 命名空间 API。

## 功能

- 术士中央球体按钮：灵魂碎片计数、生命石/灵魂石管理、恶魔/诅咒/Buff 菜单
- **灵魂碎片管理**：球体显示碎片数量（无限服按背包物品 6265 计数）
- 法术计时条、暗影冥思/反冲警报、反恐惧提示、放逐计时
- 一键制作/使用石头、自动交易生命石、坐骑按钮、语音提示（原版 mp3 保留）
- `/necrosis` 打开设置面板

## 安装

1. 将 `Necrosis` 文件夹放入游戏 `Interface\AddOns\`（先删除旧版本文件夹）
2. 重启游戏，在角色选择界面启用 **Necrosis**
3. 登录后聊天栏应显示：`[Necrosis] 无限服直连版已加载`

TOC 的 `## Interface: 16001`（= 1.60.1）。若客户端升级后显示过期，
把 `Necrosis.toc` 和 `Necrosis_Camelot.toc` 里的 Interface 改成
`/run print(select(4, GetBuildInfo()))` 输出的数值即可。
文件夹内同时提供 `Necrosis_Camelot.toc`（无限客户端优先识别 `_Camelot` 后缀）。

## 移植说明（老 API → 无限客户端现代 API 直连）

无限是 Mainline 代码库（12.0 时代 API），Cata 的老全局 API 已移除或改签名。
移植方式：**每个文件顶部定义局部函数**（Lua 局部变量只在本文件可见），
函数体直接调用现代 C_ API，原有调用点保持老签名不变：

| 老调用（保持不变） | 局部函数实现（直连） |
|---|---|
| `GetSpellInfo(id)`（老多返回值） | `C_Spell.GetSpellInfo`（返回表）+ `C_Spell.GetSpellPowerCost` |
| `GetSpellCooldown(id)` | `C_Spell.GetSpellCooldown` |
| `UnitBuff/UnitDebuff` | `C_UnitAuras.GetAuraDataByIndex`（UnitHas* 重写） |
| `UnitMana/UnitManaMax` | `UnitPower/UnitPowerMax` |
| `GetNumPartyMembers/GetNumRaidMembers` | `UnitInRaid/UnitInParty` 近似（只比较 >0） |
| `SendChatMessage` | `C_ChatInfo.SendChatMessage` |
| `GetCompanionInfo/GetNumCompanions/PickupCompanion` | `C_MountJournal.*` |
| `GetContainerNumSlots` | `C_Container.GetContainerNumSlots` |
| `AcceptTrade` / `DropItemOnUnit` / `ClickTradeButton` | `C_SecureTransfer` / `C_Item` / 存在性守卫 |
| `NecrosisTooltip:SetBagItem` | 局部 `SetTooltipBagItem`（SetHyperlink 兜底） |

另有直接改写的部分：

- 事件：`UNIT_POWER` → `UNIT_POWER_UPDATE`、`LEARNED_SPELL_IN_TAB` → `SPELLS_CHANGED`（2 秒节流），事件注册逐个容错
- 战斗日志：`CombatLogGetCurrentEventInfo()`（兼容旧式载荷）
- 施法事件载荷适配（现代 payload 只给 spellID）
- 法术扫描：`C_SpellBook.FindSpellBookSlotForSpell` 按 ID 查学会状态
- **碎片计数改为背包物品扫描（6265）**，`UnitPower` 仅回退；球体贴图索引加上限保护
- `SetBackdrop`（10.0 已移除）→ 直接用纹理实现背景/边框
- `CompanionButtonTemplate`（坐骑系统已移除）→ `UICheckButtonTemplate`
- 机密值防护：受限状态下 API 返回 `<secret>` 参与运算会报错，数值使用前经 `issecretvalue` 检查
- 交易拾取（受保护动作）：仅非战斗执行、失败静默跳过
- 已去除原版 7 个文件的 UTF-8 BOM（标准 Lua 5.1 会因此语法报错）
- 修复原版 bug：`arg1 == player` → `arg1 == "player"`

全部 39 个 Lua 文件已用 **标准 Lua 5.1 编译器**语法校验通过。

## 已知降级

- **法术 ID**：原版是 4.0 时代法术表。60 级存在的法术（暗影箭 686、恐惧 5782、
  腐蚀 172、放逐 710 等原版 ID）正常；TBC/WotLK 独有法术（恶魔守卫、变身等）
  在服务器里不存在时自动隐藏对应按钮。
- **音效**：客户端缺少 `PlaySoundFile` 时静默跳过。
- **选项面板**：`OptionsButtonTemplate / OptionsSliderTemplate / UICheckButtonTemplate /
  UIDropDownMenuTemplate` 为 FrameXML 老模板，理论上随 Mainline 代码库保留；
  如果打开设置时报错，请把报错发来，会做无模板的直接替换。

## 命令

| 命令 | 作用 |
|---|---|
| `/necrosis` | 打开设置 |
| `/necrosis lock` / `unlock` | 锁定 / 解锁按钮位置 |

## 版权

原作版权归 Lomig、Liadora、Nyx 等所有（GPL v2，见 `GPL V2.txt`）。
本移植版仅做 API 兼容改造，未新增功能。
