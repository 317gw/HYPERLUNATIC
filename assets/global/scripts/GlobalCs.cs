using Godot;
using System;

namespace HyperLunatik;

public partial class GlobalCs : Node
{
	public const float explod_max_speed = 100.0f; // m
	public static PackedScene EFFECTS = (PackedScene)GD.Load("res://assets/global/Effects.tscn");
	public static Node3D effects = null; // Global.effects.AddChild()


	// 用于代替lerp在 _process 等中每帧调用平滑数据  4.6秒到达99%  x乘delta缩短x倍时间
	// __By 317GW 2024 8 31 半夜
	public static double ExponentialDecay(double from, double to, double delta)
	{
		double x0 = Mathf.Log(Mathf.Abs(to - from));
		return to - Mathf.Exp(x0 - delta) * Mathf.Sign(to - from);
	}

	public static Vector2 ExponentialDecayVec2(Vector2 from, Vector2 to, double delta)
	{
		return new Vector2(
			(float)ExponentialDecay(from.X, to.X, delta),
			(float)ExponentialDecay(from.Y, to.Y, delta)
		);
	}

	public static Vector3 ExponentialDecayVec3(Vector3 from, Vector3 to, double delta)
	{
		return new Vector3(
			(float)ExponentialDecay(from.X, to.X, delta),
			(float)ExponentialDecay(from.Y, to.Y, delta),
			(float)ExponentialDecay(from.Z, to.Z, delta)
		);
	}

	// 计算mesh体积
	public static float CalculateMeshVolume(Mesh mesh)
	{
		var arrays = mesh.SurfaceGetArrays(0);
		var vertices = (Vector3[])arrays[(int)Mesh.ArrayType.Vertex];
		var indices = (int[])arrays[(int)Mesh.ArrayType.Index];

		float volume = 0.0f;

		for (int i = 0; i < indices.Length; i += 3)
		{
			var v1 = vertices[indices[i]];
			var v2 = vertices[indices[i + 1]];
			var v3 = vertices[indices[i + 2]];

			var crossProduct = v2.Cross(v3);
			var dotProduct = v1.Dot(crossProduct);
			var triangleVolume = Mathf.Abs(dotProduct);

			volume += triangleVolume;
		}

		return volume / 6.0f;
	}

	public static void ChildrenQueueFree(Node node)
	{
		if (node != null)
		{
			if (node.GetChildCount() > 0)
			{
				foreach (var child in node.GetChildren())
				{
					child.QueueFree();
				}
			}
		}
	}

	public static float ClampingAccuracy(float n, int precision = 6)
	{
		if (precision < 1)
			return n;
		return (int)(n * precision) / (float)precision;
	}

	public static Vector3 ClampingAccuracyVector3(Vector3 vector3, int precision = 6)
	{
		if (precision < 1)
			return vector3;

		vector3.X = ClampingAccuracy(vector3.X, precision);
		vector3.Y = ClampingAccuracy(vector3.Y, precision);
		vector3.Z = ClampingAccuracy(vector3.Z, precision);
		return vector3;
	}

	// 递归查找节点下特定类型的子节点
	public static Node FindChildNode(Node node, string childType)
	{
		if (node.GetClass() == childType)
			return node;

		for (int i = 0; i < node.GetChildCount(); i++)
		{
			var childNode = node.GetChild(i);
			var result = FindChildNode(childNode, childType);
			if (result != null)
				return result;
		}
		return null;
	}
}
