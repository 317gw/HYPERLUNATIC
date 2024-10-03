类：   SphereMesh
继承：   PrimitiveMesh <   Mesh <   Resource <   RefCounted <   Object

表示球形 PrimitiveMesh 的类。

描述

表示球形 PrimitiveMesh 的类。

属性

floatheight[默认： 1.0]boolis_hemisphere[默认： false]intradial_segments[默认： 64]floatradius[默认： 0.5]intrings[默认： 32]


属性说明


● floatheight [默认： 1.0]set_height(值) setterget_height() getter

球体的全高。


● boolis_hemisphere [默认： false]set_is_hemisphere(值) setterget_is_hemisphere() getter

如果为 true，则创建一个半球而不是一个完整的球体。

注意：要得到一个规则的半球，球体的高度和半径必须相等。


● intradial_segments [默认： 64]set_radial_segments(值) setterget_radial_segments() getter

球体上的径向段数。


● floatradius [默认： 0.5]set_radius(值) setterget_radius() getter

球体半径.


● intrings [默认： 32]set_rings(值) setterget_rings() getter

沿着球体高度的段数。

