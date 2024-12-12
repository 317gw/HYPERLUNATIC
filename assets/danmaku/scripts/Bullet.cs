using Godot;
using System;

namespace HyperLunatik.Danmaku;

public partial class Bullet : Node3D
{
	// 基本
	public Transform3D TransformLocal { get; set; }

	// 声明变量
	public float Speed { get; set; }
	public float Lifetime { get; set; }
	public Color Color { get; set; }

	private bool firstFrameFired = true;
	private bool needToChangeColour = true;

	private float bulletRadiusOriginal = 0.25f; // m
	public float BulletRadius
	{
		get => bulletRadiusOriginal;
		set => SetRadius(value);
	}

	// 设置纹理
	public static void SetAlbedo(Color albedo)
	{
		// 实现代码
	}

	// 设置半径
	public static void SetRadius(float radius)
	{
		// 实现代码
	}
}
