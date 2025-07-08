class_name MathFunctionTester

# 测试数学函数并返回数据集
# 参数：
#   target_func: 要测试的数学函数（Callable）
#   var_indices: 要作为变量的参数索引列表（例如 [0,2]）
#   domains: 每个变量的定义域数组 [min, max, step]
#   fixed_args: 固定参数的数组（按参数位置排列，变量位置用null占位）
# 返回：包含测试数据的字典 {inputs: Array[Array], outputs: Array}

static func test_function(target_func: Callable, var_indices: Array, domains: Array, fixed_args: Array) -> Dictionary:
	# 验证输入
	assert(target_func != null, "Target function is null")
	assert(var_indices.size() == domains.size(), "Variable indices and domains size mismatch")

	# 准备参数模板（替换变量位置为占位符）
	var arg_template = fixed_args.duplicate()
	for idx in var_indices:
		if idx >= arg_template.size():
			arg_template.resize(idx + 1)
		arg_template[idx] = null  # 标记变量位置

	# 生成测试值网格
	var value_grid = _generate_value_grid(domains)
	var results = {
		"inputs": [],
		"outputs": [],
	}

	# 遍历所有参数组合
	for values in value_grid:
		# 构建完整参数列表
		var args = arg_template.duplicate()
		for i in range(var_indices.size()):
			var var_idx = var_indices[i]
			args[var_idx] = values[i]

		# 调用目标函数
		var result = target_func.callv(args)

		# 收集结果
		results["inputs"].append(values)
		results["outputs"].append(result)

	return results

# 生成所有变量的值组合网格
static func _generate_value_grid(domains: Array) -> Array:
	var grids = []
	for d in domains:
		grids.append(_generate_values(d[0], d[1], d[2]))

	# 计算笛卡尔积
	var result = []
	var indices = PackedInt32Array()
	indices.resize(grids.size())

	while true:
		# 添加当前组合
		var current = []
		for i in range(grids.size()):
			current.append(grids[i][indices[i]])
		result.append(current)

		# 增加索引
		var carry = true
		for dim in range(grids.size()-1, -1, -1):
			if carry:
				indices[dim] += 1
				if indices[dim] >= grids[dim].size():
					indices[dim] = 0
					carry = true
				else:
					carry = false
		if carry: break

	return result

# 生成单个变量的值序列
static func _generate_values(min_val: float, max_val: float, step: float) -> Array:
	assert(step > 0, "Step must be positive")
	var values = []
	var current = min_val
	while current <= max_val + step * 0.001:  # 处理浮点精度
		values.append(current)
		current += step
	return values
