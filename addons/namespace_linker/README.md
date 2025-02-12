# godot_namespace_linker

![logo-01](https://github.com/user-attachments/assets/9342e86a-3597-433d-a0ec-1f4cda7b6512)

This is a very simple godot plugin used to quickly jump to the corresponding script or scene file when using the custom NAMESPACE method.
这是一个非常简单的godot 插件用于在使用自定义NAMESPACE方法时，快速跳转到对应的脚本或者场景文件。

In Godot, we can create a separate script file as our namespace and load other script objects we want to create into this namespace script through preload instead of using the class_name method in each script.

在godot中我们可以创建一个单独的脚本文件作为我们的命名空间，并把我们想要创建的其他脚本对象通过preload的方式加载到这个命名空间脚本中而不是在每个脚本中使用class_name方法
![image](https://github.com/user-attachments/assets/91369a87-1ff5-493e-9d50-4f271273de95)

Then, in other scripts, we reference and instantiate all script objects or scene objects through the namespace script we have set up

然后我们在其他脚本中通过我们设置的命名空间脚本引用和实例化所有脚本对象或者场景对象
![image](https://github.com/user-attachments/assets/6171812b-0141-4388-9b54-67cb786cd2a9)

With the help of namespace_linker, when we Ctrl+LeftMouse click on a script object following the namespace（like NS_Any.Foo), 
the script editor will not jump to the namespace but will directly navigate to the corresponding script file.

在namespace_linker的帮助下，当我们Ctrl+LeftMouse 点击命名空间后面的脚本对象时，脚本编辑器不会跳转到命名空间，而是直接跳转到对应的脚本文件。

In order to facilitate plugin identification, the namespace script needs to inherit the NAMESPACE object

为了方便插件识别，命名空间脚本需要继承NAMESPACE对象

====

To instantiate complex scene object and automatically cast the type we can create static methods in the namespace

为了实例化更复杂的场景并自动获取类型我们可以在命名空间中创建静态方法
![image](https://github.com/user-attachments/assets/ae999f84-4997-479e-bf6b-d2d500ba8514)
![image](https://github.com/user-attachments/assets/df90e393-d6e1-4bfa-9580-5d682f418468)
