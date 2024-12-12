using System;
using System.Linq;
using System.Runtime.Serialization.Formatters.Binary;
// using System.Collections.Generic;
using System.Reflection;
using System.Threading;
using System.Threading.Tasks;

using Godot;
using Godot.Collections;
using Godot.NativeInterop;
// using System.Collections.Generic;

//using System.ComponentModel.DataAnnotations;

namespace HyperLunatik.Danmaku;

[Tool]
public partial class Dispenser : MeshInstance3D
{
	public enum ResetMode { TIME, COUNT }
	public enum ResetDelayMode { AFTER, BEFORE, RESET_COUNT }
	public enum CapMode { STOP_LAUNCHING, DELETE_OLDEST }

	public const float FRAME_RATE = 60.0f; // 每秒发射周期数
	private const float SCALE_FACTOR = 100.0f; // 设置比例因子为100.0
	private const float EPISILON = 0.00001f; // 设置一个极小值
	private static readonly int[] VERTICES_STRIP_ORDER = { 4, 5, 0, 1, 2, 5, 6, 4, 7, 0, 3, 2, 7, 6, 0 };
	private const float GOLDEN_RATIO = 0.618033988749895f; // 黄金分割率

	// 发射器
	[ExportGroup("Dispenser")]
	[Export] public Vector3 velocity { get; set; } = Vector3.Zero; // 速度
	[Export] public Vector3 acceleration = Vector3.Zero; // 加速度
	[Export] public Vector3 center_position = Vector3.Zero; // 发射中心坐标

	// 射
	[ExportGroup("Fire")]
	[Export] public bool firing = true; // 是否开火,射弹幕
	[Export] public int fire_period { get; set; } = 6; // 发射周期 帧 1秒60帧
	[Export(PropertyHint.Range, "0, 10, 1")] public int fire_count = 1; // 发射次数 按照发射周期，同一发射帧的发射次数
	[Export] public bool interpolate_position = false; // 同一帧发射，发射位置是否插值
	[Export] public bool start_fire_once = true; // 是否开始时发射一次

	// 重置
	[ExportGroup("Reset")]
	[Export] public bool only_reset_Dispenser_class = false; // 只重置本类属性，不重置派生
	[Export] public ResetMode reset_mode = ResetMode.TIME; // 重置模式
	[Export] public float time_for_reset = 0; // 按照时间重置，为则0不启用
	[Export] public int count_for_reset = 0; // 按照发射次数重置，为0不启用
	[Export] public ResetDelayMode reset_delay_mode = ResetDelayMode.AFTER; // 重置延迟模式
	[Export] public float reset_delay_time = 0; // 重置延迟时间

	// 发射盘
	[ExportGroup("Disk", "disk_")]
	[Export(PropertyHint.Range, "0, 100, 1")] public int disk_count = 1; // 发射盘数量
	[Export] public float disk_angle = 0.0f; // 发射盘环角度
	[Export] public float disk_range = 360.0f; // 发射盘范围 角度单位
	[Export] public float disk_radius = 0.0f; // 发射盘半径

	// 发射条
	[ExportGroup("Stripe", "stripe_")]
	[Export(PropertyHint.Range, "0, 100, 1")] public int stripe_count = 1; // 发射条数量
	[Export] public float stripe_angle = 0.0f; // 发射条角度
	[Export] public float stripe_range = 360.0f; // 发射条范围 角度单位
	[Export] public float stripe_radius = 0.0f; // 发射条半径

	// 球面均匀分布
	[ExportGroup("Spherical")]
	[Export] public bool ues_spherical = false; // 使用球面均匀分布
	[Export(PropertyHint.Range, "1, 1000, 1")] public float spherical_count = 100; // 球面发射数量
	[Export] public float ratio = 1.0f; // 公比 黄金分割

	// 弹幕
	[ExportGroup("Bullet")]
	[Export] public PackedScene bullet_scene = null; // 类型 发射的弹幕预制体
	[Export] float bullet_mass = 1.0f; // 质量

	// 消除处理
	[Export(PropertyHint.Range, "0, 20000, 1")] int bullet_max_node = 2000; // 下属的最大弹幕数量
	[Export] float bullet_lifetime = 10.0f; // 生存时间 秒
	[Export] bool bullet_collision_enabled = true; // 碰撞消除
	[Export] CapMode exceeding_the_cap_mode = CapMode.STOP_LAUNCHING; // 超出容量处理模式
	
	// 移动
	[Export] float bullet_speed = 1.0f; // 弹幕速度
	[Export] Vector3 bullet_acceleration = Vector3.Zero; // 弹幕加速度
	[Export] Vector3 bullet_rotation = Vector3.Zero; // 弹幕旋转
	
	// 特效
	[Export] Color bullet_color = new(1, 1, 1, 1); // 颜色
	[Export] Vector3 bullet_scale = Vector3.One; // 缩放
	[Export] int bullet_blend_mode = 0; // 混合模式
	[Export] PackedScene spawn_effect = null; // 生成特效
	[Export] PackedScene destroy_effect = null; // 消除特效
	[Export] PackedScene trail_effect = null; // 拖影特效
	// [Export] var  // 忽略……
	
	[ExportGroup("DebugDisplay")]
	[Export] bool disk_debug_display = true; // 显示发射盘
	[Export] bool stripe_debug_display = true; // 显示发射条
	[Export] float display_radius = 2.0f; // Debug显示半径


	private Array<MultiMeshInstance3D> bullet_multi_mesh_instances = new(); // MultiMeshInstance3D
	private Array<MultiMesh> bullet_multi_meshs = new(); // MultiMesh
	private bool is_first_fire = true; // 是否是第一帧
	private Vector3 direction_vector; // 发射器朝向 方向向量
	private Array<Bullet> bullets = new(); // 存储发射的弹幕
	private int number_of_launches_in_this_frame = 0; // 这一帧内的发射次数
	private float time_since_last_fire = 0.0f; // 自上次发射以来的时间
	private float time_since_last_reset = 0.0f; // 自上次重置以来的时间
	private int count_since_last_reset = 0; // 自上次重置以来的次数

	private Array<Vector3> disk_positions = new();
	private Array<Transform3D> rotation_matrixs = new();
	private Array<Vector3> curve_points = new();
	private Array<Vector3> stripe_fire_positions = new();
	private Array<Vector3> stripe_targets = new();
	private Array<Vector3> spherical_targets = new();

	private Dictionary<string, Variant> reset_data = new();

	private const string DANMAKU_BREAK_PATH = "res://assets/special_effects/danmaku_break.tscn";
	private const string BULLETS_MULTI_MESH_INSTANCE_3D_PATH = "res://assets/danmaku/bullets_multi_mesh_instance_3d.tscn";
	private const string BULLET_BASE_AREA_3D_PATH = "res://assets/danmaku/bullet_base_area_3d.tscn";

	private PackedScene DANMAKU_BREAK = GD.Load<PackedScene>(DANMAKU_BREAK_PATH);
	private PackedScene BULLETS_MULTI_MESH_INSTANCE_3D = GD.Load<PackedScene>(BULLETS_MULTI_MESH_INSTANCE_3D_PATH);
	private PackedScene BULLET_BASE_AREA_3D = GD.Load<PackedScene>(BULLET_BASE_AREA_3D_PATH);

	private CancellationTokenSource _cts = new();
	private Task _MoveBulletsTask;


	public override void _Ready()
	{
		if (!Engine.IsEditorHint())
		{
			bullet_multi_mesh_instances.Clear();
			bullet_multi_meshs.Clear();

			// 获取要绘制的mesh
			var bullet_meshs = new Array<Mesh>();
			var bullet = (MeshInstance3D)bullet_scene.Instantiate();
			if (bullet != null)
			{
				bullet_meshs.Add(bullet.Mesh);
			}

			foreach (var child in bullet.GetChildren())
			{
				if (child is MeshInstance3D childMeshInstance)
				{
					bullet_meshs.Add(childMeshInstance.Mesh);
				}
			}

			// 配置绘制的mesh
			for (int i = 0; i < bullet_meshs.Count; i++)
			{
				var bullets_multi_mesh_instance = (MultiMeshInstance3D)BULLETS_MULTI_MESH_INSTANCE_3D.Instantiate();
				bullet_multi_mesh_instances.Add(bullets_multi_mesh_instance);
				AddChild(bullets_multi_mesh_instance);
				bullets_multi_mesh_instance.Multimesh.Mesh = bullet_meshs[i];
				bullet_multi_meshs.Add(bullets_multi_mesh_instance.Multimesh);
			}

			SaveProperties();
			Ready();
		}
	}

	public override void _PhysicsProcess(double delta)
	{
		if (Engine.IsEditorHint())
		{
			if (ues_spherical)
			{
				CalculateSphericalUniformDistribution();
			}
			else
			{
				CalculateStripeRotation();
			}
			DebugDisplay();
		}

		if (!Engine.IsEditorHint())
		{
			ProcessInGame(delta);
		}
	}

	protected virtual void Ready() 
	{
	}

	protected virtual void BulletEvent(double delta)
	{
	}

	private void ProcessInGame(double delta)
	{
		// 更新基本属性
		direction_vector = -Transform.Basis.Z;
		velocity += acceleration * (float)delta;
		GlobalPosition += velocity * (float)delta;

		if (firing)
		{
			InFiring(delta);
		}

		// _cts = new();
		GD.Print("Start MoveBulletsTask");
		_MoveBulletsTask = Task.Run(() => MoveBullets(delta));

		DrawBullet(delta);
		DeleteExpiredBullets(delta); // 检查并删除超时的弹幕

		// 处理重置
		if (reset_mode == ResetMode.TIME && time_for_reset > 0 && time_since_last_reset >= time_for_reset)
		{
			time_since_last_reset = 0.0f;
			Reset(delta);
		}
		if (reset_mode == ResetMode.COUNT && count_for_reset > 0 && count_since_last_reset >= count_for_reset)
		{
			count_since_last_reset = 0;
			Reset(delta);
		}
	}

	private void Reset(double delta)
	{
		LoadProperties();
		if (reset_delay_mode == ResetDelayMode.AFTER && reset_delay_time > 0)
		{
			float t = (float)Math.Floor(reset_delay_time / delta) * (float)delta;
			time_since_last_fire -= t;
			time_since_last_reset -= t;
		}
	}

	private void InFiring(double delta)
	{
		// 处理初次发射
		if (is_first_fire)
		{
			is_first_fire = false;
			if (start_fire_once)
			{
				time_since_last_fire += fire_period / FRAME_RATE;
			}
			if (reset_delay_mode == ResetDelayMode.BEFORE && reset_delay_time > 0)
			{
				float t = (float)Math.Floor(reset_delay_time / delta);
				time_since_last_fire -= t;
				time_since_last_reset -= t;
			}
		}

		if (time_since_last_reset > 0)
		{
			BulletEvent(delta);
			spherical_count = Mathf.Clamp(spherical_count, 1, 1000);
		}

		// 计数
		time_since_last_fire += (float)delta;
		time_since_last_reset += (float)delta;

		// 检查是否可以发射弹幕
		float timeFirePeriod = fire_period / FRAME_RATE;
		if (time_since_last_fire >= timeFirePeriod)
		{
			time_since_last_fire = 0.0f;
			if (ues_spherical)
			{
				CalculateSphericalUniformDistribution();
			}
			else
			{
				CalculateStripeRotation();
			}
			DebugDisplay(); // debug显示
			switch (exceeding_the_cap_mode)
			{
				case CapMode.STOP_LAUNCHING:
					if (GetChildCount(true) < bullet_max_node) // bullets.size()
					{
						FireBullet();
					}
					break;
				case CapMode.DELETE_OLDEST:
					FireBullet();
					break;
			}
			count_since_last_reset += 1;
		}
	}

	// 移动弹幕
	private async void MoveBullets(double delta)
	{
		if (_cts.IsCancellationRequested)
		{
			return;
		}

		var task = Task.Run(() => 
		{
			foreach (var bullet in bullets)// 更新弹幕位置
			{
				var transform = bullet.TransformLocal;// 获取当前的 transform
				transform.Origin -= transform.Basis.Z * bullet.Speed * (float)delta;// 修改副本
				bullet.TransformLocal = transform;// 赋值给弹幕
				// GD.Print("CallDeferred");
				bullet.CallDeferred(Node3D.MethodName.SetTransform, transform);
			}
		});
		await task;
	}

	private void DrawBullet(double delta)
	{
		for (int i = 0; i < bullet_multi_meshs.Count; i++)
		{
			var multi_mesh = bullet_multi_meshs[i];
			if (multi_mesh.Mesh == null)
			{
				GD.Print("bullets_multi_mesh.mesh == null");
				return;
			}

			multi_mesh.InstanceCount = bullets.Count;
			for (int j = 0; j < bullets.Count; j++)
			{
				var bullet_pos = new Transform3D();
				bullet_pos = bullet_pos.Translated(bullets[j].GlobalPosition);
				multi_mesh.SetInstanceTransform(j, bullet_pos);
			}
		}
	}

	// 发射弹幕的函数
	private void FireBullet()
	{
		number_of_launches_in_this_frame = 0;
		if (ues_spherical)
		{
			for (int i = 1; i <= (int)spherical_count; i++)
			{
				Vector3 target = spherical_targets[i - 1];
				SetBullet(center_position, target);
			}
		}
		else
		{
			for (int i = 0; i < stripe_targets.Count; i++)
			{
				Vector3 fire_pos = stripe_fire_positions[i];
				Vector3 target = stripe_targets[i];
				SetBullet(fire_pos, target);
			}
		}
	}

	private void SetBullet(Vector3 fire_pos, Vector3 target)
	{
		DeleteOutCapBullets();

		var bullet_node = BULLET_BASE_AREA_3D.Instantiate(); // 制作area3d弹幕
		bullet_node.SetScript(bullet_scene.Instantiate().GetScript());
		var bullet_instance = new Bullet();     //(Bullet)bullet_node; // 实例化弹幕

		AddChild(bullet_instance);
		bullets.Add(bullet_instance); // 存储已发射的弹幕
		number_of_launches_in_this_frame++;


		Vector3 bullet_target = target + GlobalPosition + fire_pos;
		if (Vector3.Up.Cross(bullet_target - bullet_instance.GlobalPosition) == Vector3.Zero)
		{
			bullet_instance.LookAt(bullet_target, Vector3.Forward);
		}
		else
		{
			bullet_instance.LookAt(bullet_target);
		}
		
		bullet_instance.Position = fire_pos; // 设定弹幕位置

		bullet_instance.TransformLocal = bullet_instance.Transform; // 刷新transform

		bullet_instance.Speed = bullet_speed; // 需要在弹幕脚本中定义speed属性
		bullet_instance.Lifetime = bullet_lifetime; // 设定弹幕的生存时间
		bullet_instance.Scale = bullet_scale;
	}

	private void DeleteOutCapBullets()
	{
		if (exceeding_the_cap_mode == CapMode.DELETE_OLDEST)
		{
			if (GetChildCount(true) > bullet_max_node && bullets.Count > 0)
			{
				var bullet = bullets[0];
				DeleteBullet(bullet);
			}
		}
	}

	private void DeleteExpiredBullets(double delta)
	{
		foreach (var bullet in bullets.ToArray())
		{
			if (bullet.Lifetime > 0)
			{
				bullet.Lifetime -= (float)delta;
			}
			else
			{
				DeleteBullet(bullet);
			}
		}
	}

	private void DeleteBullet(Bullet bullet)
	{
		bullets.Remove(bullet);
		if (destroy_effect == null)
		{
			bullet.QueueFree();
			return;
		}

		// var danmaku_break = (AnimatedSprite3D)destroy_effect.Instantiate();
		// var effects = GetNode<Node>("/root/Global/effects");
		// effects.AddChild(danmaku_break);
		// danmaku_break.GlobalPosition = bullet.GlobalPosition;
		// bullet.QueueFree();

		// // ↓消失特效
		// float rand_size = 0.1f;
		// danmaku_break.GlobalPosition += (
		// 	new Vector3(GD.Randf(), GD.Randf(), GD.Randf())
		// 	- new Vector3(rand_size, rand_size, rand_size) * 0.5f
		// ) * rand_size;

		// danmaku_break.Modulate = Color.FromHsv(bullet_color.H, 0.8f, 1.0f);

		// // 随机bool
		// Random rand = new Random();
		// danmaku_break.FlipH = rand.Next(2) == 0;
		// danmaku_break.FlipV = rand.Next(2) == 0;
		// danmaku_break.SpeedScale += GD.RandfRange(-1, 1) * 0.1f;

		// danmaku_break.Scale *= bullet.bullet_radius;
		// await danmaku_break.AnimationFinished;
		// danmaku_break.QueueFree();
	}

	private void CalculateStripeRotation()
	{
		disk_positions.Clear();
		rotation_matrixs.Clear();
		curve_points.Clear();
		stripe_fire_positions.Clear();
		stripe_targets.Clear();

		float range_angle = Mathf.Abs(stripe_range);
		float a = 270 - range_angle / 2.0f + stripe_angle;
		float disk_offset = disk_range / 2.0f;

		for (float i = 0; i < disk_count; i++)
		{
			Vector3 rota = Vector3.Zero;
			rota.Z = (disk_range / disk_count) * (i + 0.5f);
			rota.Z += disk_angle - disk_offset;
			rota.Z = Mathf.DegToRad(rota.Z);
			Transform3D rotation_matrix = new Transform3D(Basis.FromEuler(rota), Vector3.Zero);
			Vector3 rotated_normal = Vector3.Up.Rotated(Vector3.Up, a) * disk_radius;
			Vector3 disk_pos = center_position + rotated_normal;

			disk_positions.Add(disk_pos);
			rotation_matrixs.Add(rotation_matrix);
		}

		for (float j = 0; j < stripe_count; j++)
		{
			float angle = a + (range_angle / stripe_count) * (j + 0.5f); // 计算当前角度
			angle = Mathf.DegToRad(angle);
			Vector3 curve_point = center_position + new Vector3(Mathf.Cos(angle), 0, Mathf.Sin(angle)); // 计算每个点
			curve_points.Add(curve_point);
		}

		for (int i = 0; i < disk_count; i++)
		{
			for (int j = 0; j < stripe_count; j++)
			{
				Vector3 fire_pos = disk_positions[i] + stripe_radius * (curve_points[j] - center_position);
				stripe_fire_positions.Add(fire_pos * rotation_matrixs[i]);
				stripe_targets.Add(curve_points[j] * rotation_matrixs[i]);
			}
		}
	}

	private void CalculateSphericalUniformDistribution()
	{
		if (!ues_spherical)
			return;

		spherical_targets.Clear();

		for (int i = 1; i <= (int)spherical_count; i++)
		{
			float high = (2 * i - 1) / Mathf.Floor(spherical_count) - 1;
			float radius = Mathf.Sqrt(1 - Mathf.Pow(high, 2));
			float theta = Mathf.Tau * i * Mathf.Pow(GOLDEN_RATIO, ratio);

			Vector3 point = new Vector3(
				radius * Mathf.Cos(theta),
				high,
				radius * Mathf.Sin(theta)
			) * display_radius;

			spherical_targets.Add(point);
		}
	}

	public static Dictionary<string, Variant> ConvertToDictionary<T>(T obj) // Variant
	{
		var result = new Dictionary<string, Variant>();
		var properties = typeof(T).GetProperties(BindingFlags.Public | BindingFlags.Instance);

		foreach (var property in properties)
		{
			// 获取属性值并转换为 Variant
			var value = property.GetValue(obj);
			result[property.Name] = Variant.From(value);
		}

		return result;
	}

	private void SaveProperties()
	{
		reset_data.Clear();
		reset_data = ConvertToDictionary(this);
		reset_data.Remove("reset_data");
		GD.Print(reset_data);

		foreach (var key in reset_data.Keys.ToArray())
		{
			if (key is string)
			{
				if (key.Contains("@") || key.StartsWith("_") || key.Contains("count_since_last_reset"))
				{
					reset_data.Remove(key);
				}
			}
		}

		if (only_reset_Dispenser_class)
		{
			var keys_to_remove = new Array<string>();
			bool found = false;

			foreach (var key in reset_data.Keys.ToArray())
			{
				if (found)
				{
					keys_to_remove.Add(key);
				}
				if (key == "Here_is_the_last_one")
				{
					found = true;
				}
			}
			foreach (var key in keys_to_remove)
			{
				reset_data.Remove(key);
			}
		}
	}

	private void LoadProperties()
	{
		foreach (var property in reset_data)
		{
			if (reset_data.ContainsKey(property.Key))
			{
				Set(property.Key, reset_data[property.Key]);
			}
		}
	}


/*
下面是debug_display，画画的
*/


	private void DebugDisplay()
	{
		ImmediateMesh immediate_mesh = (ImmediateMesh)Mesh;
		ClearMesh(immediate_mesh); // 调用清除线条函数

		if (ues_spherical && spherical_targets.Count > 0)
		{
			var pointsA = new Array<Vector3>();
			var pointsB = new Array<Vector3>();

			for (int p = 0; p < (int)spherical_count; p++)
			{
				Vector3 point = spherical_targets[p] * display_radius;
				pointsA.Add(point);
				pointsB.Add(spherical_targets[p].Normalized() * 0.1f);
			}
			DrawMeshLineRepetRelative(immediate_mesh, pointsA, pointsB, Colors.Red, 10, 0);
			return;
		}

		if (disk_debug_display && disk_positions.Count > 0)
		{
			float range_angle = Mathf.Abs(stripe_range);
			float a = 270 - range_angle / 2.0f + stripe_angle;

			foreach (var disk_pos in disk_positions)
			{
				DrawPieSlice(immediate_mesh, disk_pos, display_radius, a, range_angle, Colors.OrangeRed, rotation_matrixs[disk_positions.IndexOf(disk_pos)]);
			}
		}

		if (stripe_debug_display && stripe_fire_positions.Count > 0)
		{
			foreach (var stripe_target in stripe_targets)
			{
				DrawMeshLineRelative(immediate_mesh, stripe_fire_positions[stripe_targets.IndexOf(stripe_target)], stripe_target * display_radius, Colors.Blue, 3, 0.2f);
			}
		}
	}

	private static void ClearMesh(ImmediateMesh immediatemesh)
	{
		if (immediatemesh == null)
			return;

		immediatemesh.ClearSurfaces();
	}

	private static void DrawMeshLineRelative(ImmediateMesh immediatemesh, Vector3 pointA, Vector3 pointB, Color color, float thickness = 2f, float pointyEnd = 1f)
	{
		if (immediatemesh == null)
			return;

		var imesh = immediatemesh;
		pointB = pointA + pointB; // 计算线条终点
		if (pointA.IsEqualApprox(pointB))
			return;

		imesh.SurfaceBegin(Mesh.PrimitiveType.TriangleStrip);
		imesh.SurfaceSetColor(color);
		var dir = pointA.DirectionTo(pointB); // 计算pointA指向pointB的方向
		var normal = new Vector3(-dir.Y, dir.X, 0).Normalized();
		normal *= thickness / SCALE_FACTOR; // 计算法线向量的长度

		var localB = (pointB - pointA); // 计算线段的局部方向
		for (int v = 0; v < 14; v++) // 遍历顶点顺序数组
		{
			Vector3 vertex = (VERTICES_STRIP_ORDER[v] < 4) ? normal : normal * pointyEnd + localB; // 计算顶点的位置
			var final_vert = vertex.Rotated(dir, Mathf.Pi * (0.5f * (VERTICES_STRIP_ORDER[v] % 4) + 0.25f)); // 将顶点绕dir旋转
			final_vert += pointA; // 将顶点移动到正确的位置
			imesh.SurfaceAddVertex(final_vert); // 添加顶点到表面
		}
		imesh.SurfaceEnd(); // 结束绘制三角形条带
	}

	private void DrawMeshLineRepetRelative(ImmediateMesh immediatemesh, Array<Vector3> pointsA, Array<Vector3> pointsB, Color color, float thickness = 2f, float pointyEnd = 1f)
	{
		if (immediatemesh == null)
		{
			GD.Print("not immediatemesh is ImmediateMesh");
			return;
		}
		if (pointsA.Count() != pointsB.Count())
		{
			GD.Print("not pointsA.size() == pointsB.size()");
			return;
		}

		var imesh = immediatemesh;
		imesh.SurfaceBegin(Mesh.PrimitiveType.TriangleStrip);
		imesh.SurfaceSetColor(color);

		for (int i = 0; i < pointsA.Count(); i++)
		{
			var pointA = pointsA[i];
			var pointB = pointsB[i];
			pointB = pointA + pointB; // 计算线条终点
			if (pointA.IsEqualApprox(pointB))
				continue;

			// 开始绘制线条
			var dir = pointA.DirectionTo(pointB); // 计算pointA指向pointB的方向
			var normal = new Vector3(-dir.Y, dir.X, 0).Normalized();
			normal *= thickness / SCALE_FACTOR; // 计算法线向量的长度

			var localB = (pointB - pointA); // 计算线段的局部方向
			for (int v = 0; v < 14; v++) // 遍历顶点顺序数组
			{
				Vector3 vertex = (VERTICES_STRIP_ORDER[v] < 4) ? normal : normal * pointyEnd + localB;
				var final_vert = vertex.Rotated(dir, Mathf.Pi * (0.5f * (VERTICES_STRIP_ORDER[v] % 4) + 0.25f)); // 将顶点绕dir旋转
				final_vert += pointA; // 将顶点移动到正确的位置
				imesh.SurfaceAddVertex(final_vert); // 添加顶点到表面
			}
		}
		imesh.SurfaceEnd(); // 结束绘制三角形条带
	}

	private static void DrawPieSlice(ImmediateMesh immediatemesh, Vector3 center, float radius, float start_angle, float angle_span, Color color, Transform3D rotation_matrix)
	{
		if (immediatemesh == null)
			return;

		radius = Math.Abs(radius);
		start_angle = Mathf.DegToRad(start_angle);
		angle_span = Mathf.DegToRad(angle_span);

		// 填充扇形
		immediatemesh.SurfaceBegin(Mesh.PrimitiveType.TriangleStrip); // 开始绘制三角形扇
		immediatemesh.SurfaceSetColor(color); // 设置颜色
		immediatemesh.SurfaceAddVertex(center * rotation_matrix); // 添加圆心经过旋转变换后的位置

		// 添加沿着扇形边界的点
		int num_segments = Mathf.Max((int)(angle_span / (Mathf.Pi / 18)), 1);
		float angle_increment = angle_span / num_segments; // 每段的角度增量

		for (int i = 0; i <= num_segments; i++)
		{
			float angle = start_angle + angle_increment * i; // 计算当前角度
			Vector3 curve_point = center + new Vector3(radius * Mathf.Cos(angle), 0, radius * Mathf.Sin(angle)); // 计算每个点
			// 应用旋转
			immediatemesh.SurfaceAddVertex(curve_point * rotation_matrix); // 添加当前点经过旋转变换后的位置
			immediatemesh.SurfaceAddVertex(center * rotation_matrix); // 添加圆心经过旋转变换后的位置
		}
		immediatemesh.SurfaceEnd(); // 结束绘制
	}

	private static void DrawLine(ImmediateMesh immediatemesh, Vector3 pointA, Vector3 pointB, Color color)
	{
		if (immediatemesh == null)
			return;
		if (pointA.IsEqualApprox(pointB))
			return; // 退出函数

		immediatemesh.SurfaceBegin(Mesh.PrimitiveType.Lines); // 开始绘制线条
		immediatemesh.SurfaceSetColor(color); // 设置线条颜色
		immediatemesh.SurfaceAddVertex(pointA); // 添加线条起点
		immediatemesh.SurfaceAddVertex(pointB); // 添加线条终点
		immediatemesh.SurfaceEnd(); // 结束绘制线条
	}

	private void DrawLineRelative(ImmediateMesh immediatemesh, Vector3 pointA, Vector3 pointB, Color color)
	{
		if (immediatemesh == null)
			return;
		DrawLine(immediatemesh, pointA, pointA + pointB, color); // 调用画线函数，起点为pointA，终点为pointA+pointB
	}
}
