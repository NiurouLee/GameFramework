---@class System.Type : System.Reflection.MemberInfo
---@field MemberType System.Reflection.MemberTypes
---@field DeclaringType System.Type
---@field DeclaringMethod System.Reflection.MethodBase
---@field ReflectedType System.Type
---@field StructLayoutAttribute System.Runtime.InteropServices.StructLayoutAttribute
---@field GUID System.Guid
---@field DefaultBinder System.Reflection.Binder
---@field Module System.Reflection.Module
---@field Assembly System.Reflection.Assembly
---@field TypeHandle System.RuntimeTypeHandle
---@field FullName string
---@field Namespace string
---@field AssemblyQualifiedName string
---@field BaseType System.Type
---@field TypeInitializer System.Reflection.ConstructorInfo
---@field IsNested bool
---@field Attributes System.Reflection.TypeAttributes
---@field GenericParameterAttributes System.Reflection.GenericParameterAttributes
---@field IsVisible bool
---@field IsNotPublic bool
---@field IsPublic bool
---@field IsNestedPublic bool
---@field IsNestedPrivate bool
---@field IsNestedFamily bool
---@field IsNestedAssembly bool
---@field IsNestedFamANDAssem bool
---@field IsNestedFamORAssem bool
---@field IsAutoLayout bool
---@field IsLayoutSequential bool
---@field IsExplicitLayout bool
---@field IsClass bool
---@field IsInterface bool
---@field IsValueType bool
---@field IsAbstract bool
---@field IsSealed bool
---@field IsEnum bool
---@field IsSpecialName bool
---@field IsImport bool
---@field IsSerializable bool
---@field IsAnsiClass bool
---@field IsUnicodeClass bool
---@field IsAutoClass bool
---@field IsArray bool
---@field IsGenericType bool
---@field IsGenericTypeDefinition bool
---@field IsConstructedGenericType bool
---@field IsGenericParameter bool
---@field GenericParameterPosition int
---@field ContainsGenericParameters bool
---@field IsByRef bool
---@field IsPointer bool
---@field IsPrimitive bool
---@field IsCOMObject bool
---@field HasElementType bool
---@field IsContextful bool
---@field IsMarshalByRef bool
---@field GenericTypeArguments table
---@field IsSecurityCritical bool
---@field IsSecuritySafeCritical bool
---@field IsSecurityTransparent bool
---@field UnderlyingSystemType System.Type
---@field IsSZArray bool
---@field FilterAttribute System.Reflection.MemberFilter
---@field FilterName System.Reflection.MemberFilter
---@field FilterNameIgnoreCase System.Reflection.MemberFilter
---@field Missing object
---@field Delimiter char
---@field EmptyTypes table
local m = {}
---@overload fun(typeName:string, assemblyResolver:System.Func, typeResolver:System.Func, throwOnError:bool):System.Type
---@overload fun(typeName:string, assemblyResolver:System.Func, typeResolver:System.Func, throwOnError:bool, ignoreCase:bool):System.Type
---@overload fun():System.Type
---@overload fun(typeName:string):System.Type
---@overload fun(typeName:string, throwOnError:bool):System.Type
---@overload fun(typeName:string, throwOnError:bool, ignoreCase:bool):System.Type
---@param typeName string
---@param assemblyResolver System.Func
---@param typeResolver System.Func
---@return System.Type
function m.GetType(typeName, assemblyResolver, typeResolver) end
---@return System.Type
function m:MakePointerType() end
---@return System.Type
function m:MakeByRefType() end
---@overload fun(rank:int):System.Type
---@return System.Type
function m:MakeArrayType() end
---@overload fun(progID:string, throwOnError:bool):System.Type
---@overload fun(progID:string, server:string):System.Type
---@overload fun(progID:string, server:string, throwOnError:bool):System.Type
---@param progID string
---@return System.Type
function m.GetTypeFromProgID(progID) end
---@overload fun(clsid:System.Guid, throwOnError:bool):System.Type
---@overload fun(clsid:System.Guid, server:string):System.Type
---@overload fun(clsid:System.Guid, server:string, throwOnError:bool):System.Type
---@param clsid System.Guid
---@return System.Type
function m.GetTypeFromCLSID(clsid) end
---@param type System.Type
---@return System.TypeCode
function m.GetTypeCode(type) end
---@overload fun(name:string, invokeAttr:System.Reflection.BindingFlags, binder:System.Reflection.Binder, target:object, args:table, culture:System.Globalization.CultureInfo):object
---@overload fun(name:string, invokeAttr:System.Reflection.BindingFlags, binder:System.Reflection.Binder, target:object, args:table):object
---@param name string
---@param invokeAttr System.Reflection.BindingFlags
---@param binder System.Reflection.Binder
---@param target object
---@param args table
---@param modifiers table
---@param culture System.Globalization.CultureInfo
---@param namedParameters table
---@return object
function m:InvokeMember(name, invokeAttr, binder, target, args, modifiers, culture, namedParameters) end
---@param o object
---@return System.RuntimeTypeHandle
function m.GetTypeHandle(o) end
---@return int
function m:GetArrayRank() end
---@overload fun(bindingAttr:System.Reflection.BindingFlags, binder:System.Reflection.Binder, types:table, modifiers:table):System.Reflection.ConstructorInfo
---@overload fun(types:table):System.Reflection.ConstructorInfo
---@param bindingAttr System.Reflection.BindingFlags
---@param binder System.Reflection.Binder
---@param callConvention System.Reflection.CallingConventions
---@param types table
---@param modifiers table
---@return System.Reflection.ConstructorInfo
function m:GetConstructor(bindingAttr, binder, callConvention, types, modifiers) end
---@overload fun(bindingAttr:System.Reflection.BindingFlags):table
---@return table
function m:GetConstructors() end
---@overload fun(name:string, bindingAttr:System.Reflection.BindingFlags, binder:System.Reflection.Binder, types:table, modifiers:table):System.Reflection.MethodInfo
---@overload fun(name:string, types:table, modifiers:table):System.Reflection.MethodInfo
---@overload fun(name:string, types:table):System.Reflection.MethodInfo
---@overload fun(name:string, bindingAttr:System.Reflection.BindingFlags):System.Reflection.MethodInfo
---@overload fun(name:string):System.Reflection.MethodInfo
---@param name string
---@param bindingAttr System.Reflection.BindingFlags
---@param binder System.Reflection.Binder
---@param callConvention System.Reflection.CallingConventions
---@param types table
---@param modifiers table
---@return System.Reflection.MethodInfo
function m:GetMethod(name, bindingAttr, binder, callConvention, types, modifiers) end
---@overload fun(bindingAttr:System.Reflection.BindingFlags):table
---@return table
function m:GetMethods() end
---@overload fun(name:string):System.Reflection.FieldInfo
---@param name string
---@param bindingAttr System.Reflection.BindingFlags
---@return System.Reflection.FieldInfo
function m:GetField(name, bindingAttr) end
---@overload fun(bindingAttr:System.Reflection.BindingFlags):table
---@return table
function m:GetFields() end
---@overload fun(name:string, ignoreCase:bool):System.Type
---@param name string
---@return System.Type
function m:GetInterface(name) end
---@return table
function m:GetInterfaces() end
---@param filter System.Reflection.TypeFilter
---@param filterCriteria object
---@return table
function m:FindInterfaces(filter, filterCriteria) end
---@overload fun(name:string, bindingAttr:System.Reflection.BindingFlags):System.Reflection.EventInfo
---@param name string
---@return System.Reflection.EventInfo
function m:GetEvent(name) end
---@overload fun(bindingAttr:System.Reflection.BindingFlags):table
---@return table
function m:GetEvents() end
---@overload fun(name:string, returnType:System.Type, types:table, modifiers:table):System.Reflection.PropertyInfo
---@overload fun(name:string, bindingAttr:System.Reflection.BindingFlags):System.Reflection.PropertyInfo
---@overload fun(name:string, returnType:System.Type, types:table):System.Reflection.PropertyInfo
---@overload fun(name:string, types:table):System.Reflection.PropertyInfo
---@overload fun(name:string, returnType:System.Type):System.Reflection.PropertyInfo
---@overload fun(name:string):System.Reflection.PropertyInfo
---@param name string
---@param bindingAttr System.Reflection.BindingFlags
---@param binder System.Reflection.Binder
---@param returnType System.Type
---@param types table
---@param modifiers table
---@return System.Reflection.PropertyInfo
function m:GetProperty(name, bindingAttr, binder, returnType, types, modifiers) end
---@overload fun():table
---@param bindingAttr System.Reflection.BindingFlags
---@return table
function m:GetProperties(bindingAttr) end
---@overload fun(bindingAttr:System.Reflection.BindingFlags):table
---@return table
function m:GetNestedTypes() end
---@overload fun(name:string, bindingAttr:System.Reflection.BindingFlags):System.Type
---@param name string
---@return System.Type
function m:GetNestedType(name) end
---@overload fun(name:string, bindingAttr:System.Reflection.BindingFlags):table
---@overload fun(name:string, type:System.Reflection.MemberTypes, bindingAttr:System.Reflection.BindingFlags):table
---@param name string
---@return table
function m:GetMember(name) end
---@overload fun(bindingAttr:System.Reflection.BindingFlags):table
---@return table
function m:GetMembers() end
---@return table
function m:GetDefaultMembers() end
---@param memberType System.Reflection.MemberTypes
---@param bindingAttr System.Reflection.BindingFlags
---@param filter System.Reflection.MemberFilter
---@param filterCriteria object
---@return table
function m:FindMembers(memberType, bindingAttr, filter, filterCriteria) end
---@return table
function m:GetGenericParameterConstraints() end
---@param typeArguments table
---@return System.Type
function m:MakeGenericType(typeArguments) end
---@return System.Type
function m:GetElementType() end
---@return table
function m:GetGenericArguments() end
---@return System.Type
function m:GetGenericTypeDefinition() end
---@return table
function m:GetEnumNames() end
---@return table
function m:GetEnumValues() end
---@return System.Type
function m:GetEnumUnderlyingType() end
---@param value object
---@return bool
function m:IsEnumDefined(value) end
---@param value object
---@return string
function m:GetEnumName(value) end
---@param c System.Type
---@return bool
function m:IsSubclassOf(c) end
---@param o object
---@return bool
function m:IsInstanceOfType(o) end
---@param c System.Type
---@return bool
function m:IsAssignableFrom(c) end
---@param other System.Type
---@return bool
function m:IsEquivalentTo(other) end
---@return string
function m:ToString() end
---@param args table
---@return table
function m.GetTypeArray(args) end
---@overload fun(o:System.Type):bool
---@param o object
---@return bool
function m:Equals(o) end
---@param left System.Type
---@param right System.Type
---@return bool
function m.op_Equality(left, right) end
---@param left System.Type
---@param right System.Type
---@return bool
function m.op_Inequality(left, right) end
---@return int
function m:GetHashCode() end
---@param interfaceType System.Type
---@return System.Reflection.InterfaceMapping
function m:GetInterfaceMap(interfaceType) end
---@param typeName string
---@param throwIfNotFound bool
---@param ignoreCase bool
---@return System.Type
function m.ReflectionOnlyGetType(typeName, throwIfNotFound, ignoreCase) end
---@param handle System.RuntimeTypeHandle
---@return System.Type
function m.GetTypeFromHandle(handle) end
System = {}
System.Type = m
return m