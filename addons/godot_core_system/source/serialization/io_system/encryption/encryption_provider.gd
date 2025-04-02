extends RefCounted
class_name EncryptionProvider

## 加密提供者基类
## 用于提供自定义的加密和解密实现

## 加密数据
## [param data] 要加密的数据
## [param key] 密钥
## [return] 加密后的数据
func encrypt(data: PackedByteArray, key: PackedByteArray) -> PackedByteArray:
	push_error("EncryptionProvider.encrypt() must be implemented by child class")
	return data

## 解密数据
## [param data] 要解密的数据
## [param key] 密钥
## [return] 解密后的数据
func decrypt(data: PackedByteArray, key: PackedByteArray) -> PackedByteArray:
	push_error("EncryptionProvider.decrypt() must be implemented by child class")
	return data
