
class StringBuilder extends StringBuffer {
  String? _buffer;

  StringBuilder([String content = '']) : super(content);

  _initBuffer([force = false]) {
    if (_buffer == null || force) {
      _buffer = super.toString();
    }
  }

  String operator [](int idx){
    return charAt(idx);
  }

  operator []=(int idx, String char){
    setCharAt(idx, char);
  }

  String charAt(int idx) {
    _initBuffer();
    return _buffer![idx];
  }

  void setCharAt(int index, dynamic char) {
    replace(index, index+1, (char is int) ? String.fromCharCode(char) : char);
  }

  int codePointAt(int index){
    _initBuffer();
    return _buffer!.codeUnitAt(index);
  }

  void replace(int start, int end, String str) {
    _initBuffer();
    super.clear();
    super.write(_buffer!.substring(0, start));
    super.write(str);
    if (end < _buffer!.length - 1)
      super.write(_buffer!.substring(end + 1));
    _buffer = null;
  }

  String substring(int start, [int? end]) {
    _initBuffer();
    return _buffer!.substring(start, end);
  }

  reverse() {
    _initBuffer();
    super.clear();
    super.write(_buffer!.split('').reversed.join(''));
    _buffer = null;
  }

  insert(int offset, Object? obj) {
    _initBuffer();
    super.clear();
    super.write(_buffer!.substring(0, offset));
    super.write(obj);
    if (offset < _buffer!.length - 1)
      super.write(_buffer!.substring(offset + 1));
    _buffer = null;
  }

  delete(int start, int end) {
    _initBuffer();
    super.clear();
    super.write(_buffer!.substring(0, start));
    if (end < _buffer!.length - 1) super.write(_buffer!.substring(end + 1));
    _buffer = null;
  }

  deleteCharAt(int idx) {
    delete(idx, idx + 1);
  }

  setLength(int length){
    delete(length, this.length);
  }

  void write(Object? object) {
    _buffer = null;
    super.write(object);
  }

  /// Adds the string representation of [charCode] to the buffer.
  ///
  /// Equivalent to `write(String.fromCharCode(charCode))`.
  void writeCharCode(int charCode) {
    _buffer = null;
    super.writeCharCode(charCode);
  }

  /// Writes all [objects] separated by [separator].
  ///
  /// Writes each individual object in [objects] in iteration order,
  /// and writes [separator] between any two objects.
  void writeAll(Iterable<dynamic> objects, [String separator = ""]) {
    _buffer = null;
    super.writeAll(objects, separator);
  }

  void writeln([Object? obj = ""]) {
    _buffer = null;
    super.writeln(obj);
  }

  /// Clears the string buffer.
  void clear() {
    _buffer = null;
    super.clear();
  }
}
