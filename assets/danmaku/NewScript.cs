using Godot;
using System;

public partial class NewScript : Node
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
	[Export]
	public Vector3 velocity { get; set; } = Vector3.Zero; // 速度
	[Export]
	public Vector3 acceleration = Vector3.Zero; // 加速度
	[Export]
	public Vector3 center_position = Vector3.Zero; // 发射中心坐标
	
	
	
	public override void _Ready()
	{
		GD.Print("Hello, world!");
	}

	public override void _Process(double delta)
	{

	}
}
