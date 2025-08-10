"""
HYPERLUNATIC  © 2025 by AlbedoHummingbird is licensed under CC BY 4.0. To view a copy of this license, visit https://creativecommons.org/licenses/by/4.0/
"""

class_name HL
extends NAMESPACE
# NameSpace daze⭐

# OMG! is .gd !!!!!!!!!
const DoubleClick = preload("res://assets/global/scripts/double_click.gd")
#const FrameSkiper = preload("res://assets/global/scripts/frame_skiper.gd")

const Attack = preload("res://assets/global/scripts/attack.gd")
const Weapon = preload("res://assets/weapons/scripts/weapon.gd")

const ForceControlCharacterBody3D = preload("res://assets/global/scripts/force_control_character_body3d.gd")

# Config 配置文件
const SettingsConfigManager = preload("res://assets/global/scripts/settings_config_manager.gd")

# Controller 控制
const Player = preload("res://assets/controllers/scripts/PlayerController.gd")
const Camera = preload("res://assets/controllers/scripts/Camera3D.gd")
const WeaponManager = preload("res://assets/weapons/scripts/weapon_manager.gd")

# Weapons 武器
const Rifle = preload("res://assets/weapons/rifle/rifle.gd")
const HolyFisher = preload("res://assets/weapons/holy_fisher/holy_fisher.gd")

# Physics 物理
const FluidMechanics = preload("res://assets/systems/water_physics/scripts/fluid_mechanics.gd")
const FluidMechanicsManager = preload("res://assets/systems/water_physics/scripts/fluid_mechanics_manager.gd")
const WaterMesh = preload("res://assets/systems/water_physics/scripts/water_mesh.gd")

# Route 线路
const Route = preload("res://assets/maps/map_blocks/scripts/route.gd")
const RouteTerminal = preload("res://assets/maps/map_blocks/terminal/route_terminal.gd")

const MarchingCubes = preload("res://assets/systems/marching_cubes/marching_cubes.gd")
const ChunkManager = preload("res://assets/systems/spatial_partition/chunk_manager.gd")

# ui UIUIUI
const MainMenus = preload("res://assets/arts_graphic/ui/menu/main_menus.gd")
const OptionWindow = preload("res://assets/arts_graphic/ui/menu/option_window.gd")
#const Propertie = preload("res://assets/arts_graphic/ui/menu/propertie.gd")
const PlayerFP_UI = preload("res://assets/arts_graphic/ui/player_ui/player_fp_ui.gd")
const FrontSight = preload("res://assets/arts_graphic/ui/player_ui/front_sight.gd")
const ToolUi = preload("res://assets/arts_graphic/ui/player_ui/tool_ui.gd")
const DebugMenu = preload("res://assets/arts_graphic/ui/debug_menu/debug_menu.gd")

# danmaku 弹幕
const DanmakuManager = preload("res://assets/danmaku/scripts/danmaku_manager.gd")
const DmParticles = preload("res://assets/danmaku/scripts/dm_particles.gd")

# map?
const SkyLimit = preload("res://assets/maps/map_blocks/scripts/sky_limit.gd")

# 常数
class Viscositys:
	const AIR: float = 0.0000178
	const WATER: float = 0.001
	const QUICKSILVER: float = 0.00155

const E: float = 2.718281828459045
const GOLDEN_RATIO: float = 0.618033988749895 ## 黄金分割率

# 小写英文字母
const LowercaseAlphabet: String = "abcdefghijklmnopqrstuvwxyz"
const LowercaseAlphabetArray: Array = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]
# 大写英文字母
const UppercaseAlphabet: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
const UppercaseAlphabetArray: Array = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
# 小写大写英文字母
const Alphabet: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
const AlphabetArray: Array = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]
# 数字
const Digits: String = "0123456789"
const DigitsArray: Array = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
# 英文字母和数字
const Alphanumeric: String = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
const AlphanumericArray: Array = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]


const NEW_BOX_SHAPE_3D = preload("res://assets/models/low_prefabricate/new_box_shape_3d.tres")
const NEW_CAPSULE_SHAPE_3D = preload("res://assets/models/low_prefabricate/new_capsule_shape_3d.tres")
const NEW_CYLINDER_SHAPE_3D = preload("res://assets/models/low_prefabricate/new_cylinder_shape_3d.tres")
const NEW_SEPARATION_RAY_SHAPE_3D = preload("res://assets/models/low_prefabricate/new_separation_ray_shape_3d.tres")
const NEW_SPHERE_SHAPE_3D = preload("res://assets/models/low_prefabricate/new_sphere_shape_3d.tres")
const shape_3d_array: Array = [NEW_BOX_SHAPE_3D, NEW_CAPSULE_SHAPE_3D, NEW_CYLINDER_SHAPE_3D, NEW_SEPARATION_RAY_SHAPE_3D, NEW_SPHERE_SHAPE_3D]


const NEW_BOX_MESH = preload("res://assets/models/low_prefabricate/new_box_mesh.tres")
const NEW_CAPSULE_MESH = preload("res://assets/models/low_prefabricate/new_capsule_mesh.tres")
const NEW_CYLINDER_MESH = preload("res://assets/models/low_prefabricate/new_cylinder_mesh.tres")
const NEW_PLANE_MESH = preload("res://assets/models/low_prefabricate/new_plane_mesh.tres")
const NEW_PRISM_MESH = preload("res://assets/models/low_prefabricate/new_prism_mesh.tres")
const NEW_QUAD_MESH = preload("res://assets/models/low_prefabricate/new_quad_mesh.tres")
const NEW_SPHERE_MESH = preload("res://assets/models/low_prefabricate/new_sphere_mesh.tres")
const NEW_TORUS_MESH = preload("res://assets/models/low_prefabricate/new_torus_mesh.tres")
const mesh_array: Array = [NEW_BOX_MESH, NEW_CAPSULE_MESH, NEW_CYLINDER_MESH, NEW_PLANE_MESH, NEW_PRISM_MESH, NEW_QUAD_MESH, NEW_SPHERE_MESH, NEW_TORUS_MESH]


## ↓常用复用静态函数
static func _pass(value): return value
static func _true(value) -> bool: return true
static func _nop(_arg = null): pass
