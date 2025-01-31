part of three_webgl;

class WebGLAttributes {
  dynamic gl;
  WebGLCapabilities capabilities;

  bool isWebGL2 = true;

  WeakMap buffers = WeakMap();

  WebGLAttributes(this.gl, this.capabilities) {
    isWebGL2 = capabilities.isWebGL2;
  }

  Map<String, dynamic> createBuffer(BufferAttribute attribute, int bufferType,
      {String? name}) {
    final array = attribute.array;
    var usage = attribute.usage;

    //dynamic arrayType = attribute.runtimeType;

    // print(" WebGLAttributes.createBuffer attribute: ${attribute.runtimeType} arrayType: ${arrayType} array: ${array.length} ${array.runtimeType} name: ${name} ");

    var type = gl.FLOAT;
    int bytesPerElement = 4;

    // TODO 优化判断？？？
    if (attribute is Float32BufferAttribute) {
      // arrayList = Float32Array.fromList(array.map((e) => e.toDouble()).toList());
    } else if (attribute is Uint16BufferAttribute) {
      // arrayList = Uint16Array.fromList(array.map((e) => e.toInt()).toList());
    } else if (attribute is Uint32BufferAttribute) {
      // arrayList = Uint32Array.fromList(array.map((e) => e.toInt()).toList());
    } else if (attribute is InterleavedBufferAttribute) {
      // arrayList = array;
      // String arrayType = array.runtimeType.toString();
      if (array is Uint8Array) {
        type = gl.UNSIGNED_BYTE;
        bytesPerElement = Uint8List.bytesPerElement;
      } else if (array is Float32Array) {
        type = gl.FLOAT;
        bytesPerElement = Float32List.bytesPerElement;
      } else if (array is Uint32Array) {
        type = gl.UNSIGNED_INT;
        bytesPerElement = Uint32List.bytesPerElement;
      } else if (array is Uint16Array) {
        type = gl.UNSIGNED_SHORT;
        bytesPerElement = Uint16List.bytesPerElement;
      } else {
        // 保持抛出异常 及时发现异常情况
        throw ("WebGLAttributes.createBuffer InterleavedBufferAttribute arrayType: ${array.runtimeType} is not support  ");
      }
    } else if (attribute is InstancedBufferAttribute) {
      type = gl.UNSIGNED_BYTE;
      bytesPerElement = Uint8List.bytesPerElement;
      // arrayList = array;

      //String _arrayType = array.runtimeType.toString();

      if (array is Uint8Array) {
        type = gl.UNSIGNED_BYTE;
        bytesPerElement = Uint8List.bytesPerElement;
      } else if (array is Float32Array) {
        type = gl.FLOAT;
        bytesPerElement = Float32List.bytesPerElement;
      } else if (array is Uint32Array) {
        type = gl.UNSIGNED_INT;
        bytesPerElement = Uint32List.bytesPerElement;
      } else {
        // 保持抛出异常 及时发现异常情况
        throw ("WebGLAttributes.createBuffer InstancedBufferAttribute arrayType: ${array.runtimeType} is not support  ");
      }
    } else if (attribute is InstancedInterleavedBuffer) {
      type = gl.UNSIGNED_BYTE;
      bytesPerElement = Uint8List.bytesPerElement;

      if (array is Uint8Array) {
        type = gl.UNSIGNED_BYTE;
        bytesPerElement = Uint8List.bytesPerElement;
      } else if (array is Float32Array) {
        type = gl.FLOAT;
        bytesPerElement = Float32List.bytesPerElement;
      } else if (array is Uint32Array) {
        type = gl.UNSIGNED_INT;
        bytesPerElement = Uint32List.bytesPerElement;
      } else {
        // 保持抛出异常 及时发现异常情况
        throw ("WebGLAttributes.createBuffer InstancedInterleavedBuffer arrayType: ${array.runtimeType} is not support  ");
      }
    } else if (array is Float32Array) {
      type = gl.FLOAT;
      bytesPerElement = Float32List.bytesPerElement;
    } else if (array is Uint32Array) {
      type = gl.UNSIGNED_INT;
      bytesPerElement = Uint32List.bytesPerElement;
    } else if (array is Uint8Array) {
      type = gl.UNSIGNED_BYTE;
      bytesPerElement = Uint8List.bytesPerElement;
    } else if (array is Int32Array) {
      type = gl.INT;
      bytesPerElement = Int32List.bytesPerElement;  
    } else {
      print("createBuffer array: ${array.runtimeType} ");
      // arrayList = Float32Array.fromList(array.map((e) => e.toDouble()).toList());
      throw ("1 WebGLAttributes.createBuffer BufferAttribute arrayType: ${array.runtimeType} is not support  ");
    }

    var buffer = gl.createBuffer();

    gl.bindBuffer(bufferType, buffer);

    gl.bufferData(bufferType, array.lengthInBytes, array, usage);

    if (attribute.onUploadCallback != null) {
      attribute.onUploadCallback!();
    }

    if (attribute is Float32BufferAttribute) {
      type = gl.FLOAT;
      bytesPerElement = Float32List.bytesPerElement;
    } else if (attribute is Float64BufferAttribute) {
      print(
          'THREE.WebGLAttributes: Unsupported data buffer format: Float64Array.');
    } else if (attribute is Uint16BufferAttribute) {
      bytesPerElement = Uint16List.bytesPerElement;

      if (attribute is Float16BufferAttribute) {
        if (isWebGL2) {
          type = gl.HALF_FLOAT;
        } else {
          print(
              'THREE.WebGLAttributes: Usage of Float16BufferAttribute requires WebGL2.');
        }
      } else {
        type = gl.UNSIGNED_SHORT;
      }
    } else if (attribute is Int16BufferAttribute) {
      bytesPerElement = Int16List.bytesPerElement;

      type = gl.SHORT;
    } else if (attribute is Uint32BufferAttribute) {
      bytesPerElement = Uint32List.bytesPerElement;

      type = gl.UNSIGNED_INT;
    } else if (attribute is Int32BufferAttribute) {
      bytesPerElement = Int32List.bytesPerElement;

      type = gl.INT;
    } else if (attribute is Int8BufferAttribute) {
      bytesPerElement = Int8List.bytesPerElement;

      type = gl.BYTE;
    } else if (attribute is Uint8BufferAttribute) {
      bytesPerElement = Uint8List.bytesPerElement;

      type = gl.UNSIGNED_BYTE;
    }

    final _v = {
      "buffer": buffer,
      "type": type,
      "bytesPerElement": bytesPerElement,
      "array": array,
      "version": attribute.version
    };

    return _v;
  }

  updateBuffer(buffer, attribute, bufferType) {
    var array = attribute.array;
    var updateRange = attribute.updateRange;

    gl.bindBuffer(bufferType, buffer);

    if (updateRange["count"] == -1) {
      // Not using update ranges
      gl.bufferSubData(bufferType, 0, array, 0, array.lengthInBytes);
    } else {
      print(" WebGLAttributes.dart gl.bufferSubData need debug confirm.... ");
      gl.bufferSubData(bufferType, updateRange["offset"] * attribute.itemSize,
          array, updateRange["offset"], updateRange["count"]);

      updateRange["count"] = -1; // reset range

    }
  }

  get(BaseBufferAttribute attribute) {
    if (attribute.type == "InterleavedBufferAttribute") {
      return buffers.get(attribute.data!);
    } else {
      return buffers.get(attribute);
    }
  }

  remove(BufferAttribute attribute) {
    if (attribute.type == "InterleavedBufferAttribute") {
      var data = buffers.get(attribute.data);

      if (data) {
        gl.deleteBuffer(data.buffer);

        buffers.delete(attribute.data);
      }
    } else {
      var data = buffers.get(attribute);

      if (data != null) {
        gl.deleteBuffer(data["buffer"]);

        buffers.delete(attribute);
      }
    }
  }

  update(attribute, bufferType, {String? name}) {
    // print(" WebGLAttributes.update attribute: ${attribute.type} ${attribute.runtimeType} name: ${name} ");

    if (attribute.type == "GLBufferAttribute") {
      var cached = buffers.get(attribute);

      if (cached == null || cached["version"] < attribute.version) {
        buffers.add(
            key: attribute,
            value: createBuffer(attribute, bufferType, name: name));
      }

      return;
    }

    if (attribute.type == "InterleavedBufferAttribute") {
      var data = buffers.get(attribute.data);

      if (data == null) {
        buffers.add(
            key: attribute.data,
            value: createBuffer(attribute.data, bufferType, name: name));
      } else if (data["version"] < attribute.data!.version) {
        updateBuffer(data["buffer"], attribute.data, bufferType);
        data["version"] = attribute.data!.version;
      }
    } else {
      var data = buffers.get(attribute);

      if (data == null) {
        buffers.add(
            key: attribute,
            value: createBuffer(attribute, bufferType, name: name));
      } else if (data["version"] < attribute.version) {
        updateBuffer(data["buffer"], attribute, bufferType);
        data["version"] = attribute.version;
      }
    }
  }
}
