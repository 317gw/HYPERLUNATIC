using Godot;
using System;

public partial class NewScript : Node
{

	//变量声明
	private int count = 0;
	
	public override void _Ready()
	{
		GD.Print("Hello, world!");
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{

	}
}
