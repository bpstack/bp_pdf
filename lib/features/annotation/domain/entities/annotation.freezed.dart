// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'annotation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
Annotation _$AnnotationFromJson(
  Map<String, dynamic> json
) {
        switch (json['runtimeType']) {
                  case 'text':
          return TextAnnotation.fromJson(
            json
          );
                case 'rect':
          return RectAnnotation.fromJson(
            json
          );
                case 'stroke':
          return StrokeAnnotation.fromJson(
            json
          );
                case 'highlight':
          return HighlightAnnotation.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'runtimeType',
  'Annotation',
  'Invalid union type "${json['runtimeType']}"!'
);
        }
      
}

/// @nodoc
mixin _$Annotation {

 String get id; int get pageNumber; PageRect get rect; int get colorArgb;
/// Create a copy of Annotation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnnotationCopyWith<Annotation> get copyWith => _$AnnotationCopyWithImpl<Annotation>(this as Annotation, _$identity);

  /// Serializes this Annotation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Annotation&&(identical(other.id, id) || other.id == id)&&(identical(other.pageNumber, pageNumber) || other.pageNumber == pageNumber)&&(identical(other.rect, rect) || other.rect == rect)&&(identical(other.colorArgb, colorArgb) || other.colorArgb == colorArgb));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,pageNumber,rect,colorArgb);

@override
String toString() {
  return 'Annotation(id: $id, pageNumber: $pageNumber, rect: $rect, colorArgb: $colorArgb)';
}


}

/// @nodoc
abstract mixin class $AnnotationCopyWith<$Res>  {
  factory $AnnotationCopyWith(Annotation value, $Res Function(Annotation) _then) = _$AnnotationCopyWithImpl;
@useResult
$Res call({
 String id, int pageNumber, PageRect rect, int colorArgb
});


$PageRectCopyWith<$Res> get rect;

}
/// @nodoc
class _$AnnotationCopyWithImpl<$Res>
    implements $AnnotationCopyWith<$Res> {
  _$AnnotationCopyWithImpl(this._self, this._then);

  final Annotation _self;
  final $Res Function(Annotation) _then;

/// Create a copy of Annotation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? pageNumber = null,Object? rect = null,Object? colorArgb = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,pageNumber: null == pageNumber ? _self.pageNumber : pageNumber // ignore: cast_nullable_to_non_nullable
as int,rect: null == rect ? _self.rect : rect // ignore: cast_nullable_to_non_nullable
as PageRect,colorArgb: null == colorArgb ? _self.colorArgb : colorArgb // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of Annotation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PageRectCopyWith<$Res> get rect {
  
  return $PageRectCopyWith<$Res>(_self.rect, (value) {
    return _then(_self.copyWith(rect: value));
  });
}
}


/// Adds pattern-matching-related methods to [Annotation].
extension AnnotationPatterns on Annotation {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TextAnnotation value)?  text,TResult Function( RectAnnotation value)?  rect,TResult Function( StrokeAnnotation value)?  stroke,TResult Function( HighlightAnnotation value)?  highlight,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TextAnnotation() when text != null:
return text(_that);case RectAnnotation() when rect != null:
return rect(_that);case StrokeAnnotation() when stroke != null:
return stroke(_that);case HighlightAnnotation() when highlight != null:
return highlight(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TextAnnotation value)  text,required TResult Function( RectAnnotation value)  rect,required TResult Function( StrokeAnnotation value)  stroke,required TResult Function( HighlightAnnotation value)  highlight,}){
final _that = this;
switch (_that) {
case TextAnnotation():
return text(_that);case RectAnnotation():
return rect(_that);case StrokeAnnotation():
return stroke(_that);case HighlightAnnotation():
return highlight(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TextAnnotation value)?  text,TResult? Function( RectAnnotation value)?  rect,TResult? Function( StrokeAnnotation value)?  stroke,TResult? Function( HighlightAnnotation value)?  highlight,}){
final _that = this;
switch (_that) {
case TextAnnotation() when text != null:
return text(_that);case RectAnnotation() when rect != null:
return rect(_that);case StrokeAnnotation() when stroke != null:
return stroke(_that);case HighlightAnnotation() when highlight != null:
return highlight(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String id,  int pageNumber,  PageRect rect,  String text,  String fontFamily,  double fontSize,  int colorArgb)?  text,TResult Function( String id,  int pageNumber,  PageRect rect,  int colorArgb,  double opacity)?  rect,TResult Function( String id,  int pageNumber,  List<PagePoint> points,  PageRect rect,  int colorArgb,  double strokeWidth)?  stroke,TResult Function( String id,  int pageNumber,  PageRect rect,  int colorArgb,  double opacity)?  highlight,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TextAnnotation() when text != null:
return text(_that.id,_that.pageNumber,_that.rect,_that.text,_that.fontFamily,_that.fontSize,_that.colorArgb);case RectAnnotation() when rect != null:
return rect(_that.id,_that.pageNumber,_that.rect,_that.colorArgb,_that.opacity);case StrokeAnnotation() when stroke != null:
return stroke(_that.id,_that.pageNumber,_that.points,_that.rect,_that.colorArgb,_that.strokeWidth);case HighlightAnnotation() when highlight != null:
return highlight(_that.id,_that.pageNumber,_that.rect,_that.colorArgb,_that.opacity);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String id,  int pageNumber,  PageRect rect,  String text,  String fontFamily,  double fontSize,  int colorArgb)  text,required TResult Function( String id,  int pageNumber,  PageRect rect,  int colorArgb,  double opacity)  rect,required TResult Function( String id,  int pageNumber,  List<PagePoint> points,  PageRect rect,  int colorArgb,  double strokeWidth)  stroke,required TResult Function( String id,  int pageNumber,  PageRect rect,  int colorArgb,  double opacity)  highlight,}) {final _that = this;
switch (_that) {
case TextAnnotation():
return text(_that.id,_that.pageNumber,_that.rect,_that.text,_that.fontFamily,_that.fontSize,_that.colorArgb);case RectAnnotation():
return rect(_that.id,_that.pageNumber,_that.rect,_that.colorArgb,_that.opacity);case StrokeAnnotation():
return stroke(_that.id,_that.pageNumber,_that.points,_that.rect,_that.colorArgb,_that.strokeWidth);case HighlightAnnotation():
return highlight(_that.id,_that.pageNumber,_that.rect,_that.colorArgb,_that.opacity);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String id,  int pageNumber,  PageRect rect,  String text,  String fontFamily,  double fontSize,  int colorArgb)?  text,TResult? Function( String id,  int pageNumber,  PageRect rect,  int colorArgb,  double opacity)?  rect,TResult? Function( String id,  int pageNumber,  List<PagePoint> points,  PageRect rect,  int colorArgb,  double strokeWidth)?  stroke,TResult? Function( String id,  int pageNumber,  PageRect rect,  int colorArgb,  double opacity)?  highlight,}) {final _that = this;
switch (_that) {
case TextAnnotation() when text != null:
return text(_that.id,_that.pageNumber,_that.rect,_that.text,_that.fontFamily,_that.fontSize,_that.colorArgb);case RectAnnotation() when rect != null:
return rect(_that.id,_that.pageNumber,_that.rect,_that.colorArgb,_that.opacity);case StrokeAnnotation() when stroke != null:
return stroke(_that.id,_that.pageNumber,_that.points,_that.rect,_that.colorArgb,_that.strokeWidth);case HighlightAnnotation() when highlight != null:
return highlight(_that.id,_that.pageNumber,_that.rect,_that.colorArgb,_that.opacity);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class TextAnnotation extends Annotation {
  const TextAnnotation({required this.id, required this.pageNumber, required this.rect, required this.text, required this.fontFamily, required this.fontSize, required this.colorArgb, final  String? $type}): $type = $type ?? 'text',super._();
  factory TextAnnotation.fromJson(Map<String, dynamic> json) => _$TextAnnotationFromJson(json);

@override final  String id;
@override final  int pageNumber;
@override final  PageRect rect;
 final  String text;
 final  String fontFamily;
 final  double fontSize;
@override final  int colorArgb;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of Annotation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TextAnnotationCopyWith<TextAnnotation> get copyWith => _$TextAnnotationCopyWithImpl<TextAnnotation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TextAnnotationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TextAnnotation&&(identical(other.id, id) || other.id == id)&&(identical(other.pageNumber, pageNumber) || other.pageNumber == pageNumber)&&(identical(other.rect, rect) || other.rect == rect)&&(identical(other.text, text) || other.text == text)&&(identical(other.fontFamily, fontFamily) || other.fontFamily == fontFamily)&&(identical(other.fontSize, fontSize) || other.fontSize == fontSize)&&(identical(other.colorArgb, colorArgb) || other.colorArgb == colorArgb));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,pageNumber,rect,text,fontFamily,fontSize,colorArgb);

@override
String toString() {
  return 'Annotation.text(id: $id, pageNumber: $pageNumber, rect: $rect, text: $text, fontFamily: $fontFamily, fontSize: $fontSize, colorArgb: $colorArgb)';
}


}

/// @nodoc
abstract mixin class $TextAnnotationCopyWith<$Res> implements $AnnotationCopyWith<$Res> {
  factory $TextAnnotationCopyWith(TextAnnotation value, $Res Function(TextAnnotation) _then) = _$TextAnnotationCopyWithImpl;
@override @useResult
$Res call({
 String id, int pageNumber, PageRect rect, String text, String fontFamily, double fontSize, int colorArgb
});


@override $PageRectCopyWith<$Res> get rect;

}
/// @nodoc
class _$TextAnnotationCopyWithImpl<$Res>
    implements $TextAnnotationCopyWith<$Res> {
  _$TextAnnotationCopyWithImpl(this._self, this._then);

  final TextAnnotation _self;
  final $Res Function(TextAnnotation) _then;

/// Create a copy of Annotation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? pageNumber = null,Object? rect = null,Object? text = null,Object? fontFamily = null,Object? fontSize = null,Object? colorArgb = null,}) {
  return _then(TextAnnotation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,pageNumber: null == pageNumber ? _self.pageNumber : pageNumber // ignore: cast_nullable_to_non_nullable
as int,rect: null == rect ? _self.rect : rect // ignore: cast_nullable_to_non_nullable
as PageRect,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,fontFamily: null == fontFamily ? _self.fontFamily : fontFamily // ignore: cast_nullable_to_non_nullable
as String,fontSize: null == fontSize ? _self.fontSize : fontSize // ignore: cast_nullable_to_non_nullable
as double,colorArgb: null == colorArgb ? _self.colorArgb : colorArgb // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of Annotation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PageRectCopyWith<$Res> get rect {
  
  return $PageRectCopyWith<$Res>(_self.rect, (value) {
    return _then(_self.copyWith(rect: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class RectAnnotation extends Annotation {
  const RectAnnotation({required this.id, required this.pageNumber, required this.rect, required this.colorArgb, this.opacity = 1.0, final  String? $type}): $type = $type ?? 'rect',super._();
  factory RectAnnotation.fromJson(Map<String, dynamic> json) => _$RectAnnotationFromJson(json);

@override final  String id;
@override final  int pageNumber;
@override final  PageRect rect;
@override final  int colorArgb;
@JsonKey() final  double opacity;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of Annotation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RectAnnotationCopyWith<RectAnnotation> get copyWith => _$RectAnnotationCopyWithImpl<RectAnnotation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RectAnnotationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RectAnnotation&&(identical(other.id, id) || other.id == id)&&(identical(other.pageNumber, pageNumber) || other.pageNumber == pageNumber)&&(identical(other.rect, rect) || other.rect == rect)&&(identical(other.colorArgb, colorArgb) || other.colorArgb == colorArgb)&&(identical(other.opacity, opacity) || other.opacity == opacity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,pageNumber,rect,colorArgb,opacity);

@override
String toString() {
  return 'Annotation.rect(id: $id, pageNumber: $pageNumber, rect: $rect, colorArgb: $colorArgb, opacity: $opacity)';
}


}

/// @nodoc
abstract mixin class $RectAnnotationCopyWith<$Res> implements $AnnotationCopyWith<$Res> {
  factory $RectAnnotationCopyWith(RectAnnotation value, $Res Function(RectAnnotation) _then) = _$RectAnnotationCopyWithImpl;
@override @useResult
$Res call({
 String id, int pageNumber, PageRect rect, int colorArgb, double opacity
});


@override $PageRectCopyWith<$Res> get rect;

}
/// @nodoc
class _$RectAnnotationCopyWithImpl<$Res>
    implements $RectAnnotationCopyWith<$Res> {
  _$RectAnnotationCopyWithImpl(this._self, this._then);

  final RectAnnotation _self;
  final $Res Function(RectAnnotation) _then;

/// Create a copy of Annotation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? pageNumber = null,Object? rect = null,Object? colorArgb = null,Object? opacity = null,}) {
  return _then(RectAnnotation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,pageNumber: null == pageNumber ? _self.pageNumber : pageNumber // ignore: cast_nullable_to_non_nullable
as int,rect: null == rect ? _self.rect : rect // ignore: cast_nullable_to_non_nullable
as PageRect,colorArgb: null == colorArgb ? _self.colorArgb : colorArgb // ignore: cast_nullable_to_non_nullable
as int,opacity: null == opacity ? _self.opacity : opacity // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

/// Create a copy of Annotation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PageRectCopyWith<$Res> get rect {
  
  return $PageRectCopyWith<$Res>(_self.rect, (value) {
    return _then(_self.copyWith(rect: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class StrokeAnnotation extends Annotation {
  const StrokeAnnotation({required this.id, required this.pageNumber, required final  List<PagePoint> points, required this.rect, required this.colorArgb, this.strokeWidth = 2.0, final  String? $type}): _points = points,$type = $type ?? 'stroke',super._();
  factory StrokeAnnotation.fromJson(Map<String, dynamic> json) => _$StrokeAnnotationFromJson(json);

@override final  String id;
@override final  int pageNumber;
 final  List<PagePoint> _points;
 List<PagePoint> get points {
  if (_points is EqualUnmodifiableListView) return _points;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_points);
}

@override final  PageRect rect;
@override final  int colorArgb;
@JsonKey() final  double strokeWidth;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of Annotation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StrokeAnnotationCopyWith<StrokeAnnotation> get copyWith => _$StrokeAnnotationCopyWithImpl<StrokeAnnotation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StrokeAnnotationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StrokeAnnotation&&(identical(other.id, id) || other.id == id)&&(identical(other.pageNumber, pageNumber) || other.pageNumber == pageNumber)&&const DeepCollectionEquality().equals(other._points, _points)&&(identical(other.rect, rect) || other.rect == rect)&&(identical(other.colorArgb, colorArgb) || other.colorArgb == colorArgb)&&(identical(other.strokeWidth, strokeWidth) || other.strokeWidth == strokeWidth));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,pageNumber,const DeepCollectionEquality().hash(_points),rect,colorArgb,strokeWidth);

@override
String toString() {
  return 'Annotation.stroke(id: $id, pageNumber: $pageNumber, points: $points, rect: $rect, colorArgb: $colorArgb, strokeWidth: $strokeWidth)';
}


}

/// @nodoc
abstract mixin class $StrokeAnnotationCopyWith<$Res> implements $AnnotationCopyWith<$Res> {
  factory $StrokeAnnotationCopyWith(StrokeAnnotation value, $Res Function(StrokeAnnotation) _then) = _$StrokeAnnotationCopyWithImpl;
@override @useResult
$Res call({
 String id, int pageNumber, List<PagePoint> points, PageRect rect, int colorArgb, double strokeWidth
});


@override $PageRectCopyWith<$Res> get rect;

}
/// @nodoc
class _$StrokeAnnotationCopyWithImpl<$Res>
    implements $StrokeAnnotationCopyWith<$Res> {
  _$StrokeAnnotationCopyWithImpl(this._self, this._then);

  final StrokeAnnotation _self;
  final $Res Function(StrokeAnnotation) _then;

/// Create a copy of Annotation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? pageNumber = null,Object? points = null,Object? rect = null,Object? colorArgb = null,Object? strokeWidth = null,}) {
  return _then(StrokeAnnotation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,pageNumber: null == pageNumber ? _self.pageNumber : pageNumber // ignore: cast_nullable_to_non_nullable
as int,points: null == points ? _self._points : points // ignore: cast_nullable_to_non_nullable
as List<PagePoint>,rect: null == rect ? _self.rect : rect // ignore: cast_nullable_to_non_nullable
as PageRect,colorArgb: null == colorArgb ? _self.colorArgb : colorArgb // ignore: cast_nullable_to_non_nullable
as int,strokeWidth: null == strokeWidth ? _self.strokeWidth : strokeWidth // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

/// Create a copy of Annotation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PageRectCopyWith<$Res> get rect {
  
  return $PageRectCopyWith<$Res>(_self.rect, (value) {
    return _then(_self.copyWith(rect: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class HighlightAnnotation extends Annotation {
  const HighlightAnnotation({required this.id, required this.pageNumber, required this.rect, this.colorArgb = 0xFFFFFF00, this.opacity = 0.4, final  String? $type}): $type = $type ?? 'highlight',super._();
  factory HighlightAnnotation.fromJson(Map<String, dynamic> json) => _$HighlightAnnotationFromJson(json);

@override final  String id;
@override final  int pageNumber;
@override final  PageRect rect;
@override@JsonKey() final  int colorArgb;
@JsonKey() final  double opacity;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of Annotation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HighlightAnnotationCopyWith<HighlightAnnotation> get copyWith => _$HighlightAnnotationCopyWithImpl<HighlightAnnotation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HighlightAnnotationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HighlightAnnotation&&(identical(other.id, id) || other.id == id)&&(identical(other.pageNumber, pageNumber) || other.pageNumber == pageNumber)&&(identical(other.rect, rect) || other.rect == rect)&&(identical(other.colorArgb, colorArgb) || other.colorArgb == colorArgb)&&(identical(other.opacity, opacity) || other.opacity == opacity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,pageNumber,rect,colorArgb,opacity);

@override
String toString() {
  return 'Annotation.highlight(id: $id, pageNumber: $pageNumber, rect: $rect, colorArgb: $colorArgb, opacity: $opacity)';
}


}

/// @nodoc
abstract mixin class $HighlightAnnotationCopyWith<$Res> implements $AnnotationCopyWith<$Res> {
  factory $HighlightAnnotationCopyWith(HighlightAnnotation value, $Res Function(HighlightAnnotation) _then) = _$HighlightAnnotationCopyWithImpl;
@override @useResult
$Res call({
 String id, int pageNumber, PageRect rect, int colorArgb, double opacity
});


@override $PageRectCopyWith<$Res> get rect;

}
/// @nodoc
class _$HighlightAnnotationCopyWithImpl<$Res>
    implements $HighlightAnnotationCopyWith<$Res> {
  _$HighlightAnnotationCopyWithImpl(this._self, this._then);

  final HighlightAnnotation _self;
  final $Res Function(HighlightAnnotation) _then;

/// Create a copy of Annotation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? pageNumber = null,Object? rect = null,Object? colorArgb = null,Object? opacity = null,}) {
  return _then(HighlightAnnotation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,pageNumber: null == pageNumber ? _self.pageNumber : pageNumber // ignore: cast_nullable_to_non_nullable
as int,rect: null == rect ? _self.rect : rect // ignore: cast_nullable_to_non_nullable
as PageRect,colorArgb: null == colorArgb ? _self.colorArgb : colorArgb // ignore: cast_nullable_to_non_nullable
as int,opacity: null == opacity ? _self.opacity : opacity // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

/// Create a copy of Annotation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PageRectCopyWith<$Res> get rect {
  
  return $PageRectCopyWith<$Res>(_self.rect, (value) {
    return _then(_self.copyWith(rect: value));
  });
}
}

// dart format on
