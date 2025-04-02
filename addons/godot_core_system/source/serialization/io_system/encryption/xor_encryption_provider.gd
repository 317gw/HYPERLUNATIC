extends EncryptionProvider
class_name XOREncryptionProvider

## XOR加密提供者
## 使用简单的XOR运算进行加密，仅用于演示，不建议在生产环境使用

func encrypt(data: PackedByteArray, key: PackedByteArray) -> PackedByteArray:
	var encrypted := PackedByteArray()
	encrypted.resize(data.size())
	for i in range(data.size()):
		encrypted[i] = data[i] ^ key[i % key.size()]
	return encrypted

func decrypt(data: PackedByteArray, key: PackedByteArray) -> PackedByteArray:
	# XOR加密是对称的，解密使用相同的算法
	return encrypt(data, key)
