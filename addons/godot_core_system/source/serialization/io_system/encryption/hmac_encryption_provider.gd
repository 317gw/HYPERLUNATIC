extends EncryptionProvider
class_name HMACEncryptionProvider

## HMAC加密提供者
## 使用HMAC-SHA256进行消息认证和加密
## 这不是真正的加密，而是一种消息认证码，但可以用于简单的数据保护

var _crypto: Crypto

func _init():
	_crypto = Crypto.new()

## 使用HMAC-SHA256进行加密
## 这实际上是在计算HMAC，不是真正的加密
## 但对于简单的数据保护来说已经足够
func encrypt(data: PackedByteArray, key: PackedByteArray) -> PackedByteArray:
	# 生成随机IV
	var iv = _crypto.generate_random_bytes(16)
	
	# 计算HMAC
	var hmac = _crypto.hmac_digest(
		HashingContext.HASH_SHA256,
		key,
		data
	)
	
	# 组合IV、HMAC和原始数据
	return iv + hmac + data

## 验证HMAC并提取原始数据
func decrypt(data: PackedByteArray, key: PackedByteArray) -> PackedByteArray:
	if data.size() < 48:  # 16(IV) + 32(HMAC) = 48
		push_error("Invalid data size")
		return PackedByteArray()
	
	# 分离IV、HMAC和数据
	var iv = data.slice(0, 16)
	var stored_hmac = data.slice(16, 48)
	var original_data = data.slice(48)
	
	# 计算HMAC
	var computed_hmac = _crypto.hmac_digest(
		HashingContext.HASH_SHA256,
		key,
		original_data
	)
	
	# 验证HMAC
	if not _crypto.constant_time_compare(stored_hmac, computed_hmac):
		push_error("HMAC verification failed")
		return PackedByteArray()
	
	return original_data
