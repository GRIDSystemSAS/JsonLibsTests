///*******************************************************
///
/// JsonLibsTests
///
/// 2026-2027 Grid System SAS
///
///
///*******************************************************

unit gs.json.impl.uJson;

interface

uses sysutils,
     classes,
     gs.Json,
     uJSON;

type

TgsJsonImplUJson = class(TInterfacedObject, igsJson)
private
protected
  FJson : TZAbstractObject;
  FOwned : boolean;
public
  constructor Create; virtual;
  destructor Destroy; override;

  function parse(aJsonStr : string) : igsJson;
  function put(name : string; val : double) : igsJson; overload;
  function put(name : string; val : boolean) : igsJson; overload;
  function put(name : string; val : string) : igsJson; overload;

  //Array
  function put(name : string; vals : array of const) : igsJson; overload;
  function put(vals : array of const) : igsJson; overload;

  //Add an object.
  function put(name : string; val : igsJson) : igsJson; overload;
  function put(val : igsJson) : igsJson; overload;

  function stringify(var aStr : string) : igsJson; overload;
  function stringify : string; overload;

  function get(name : string; var value : string) : igsJson; overload;
  function get(index : integer; var value : string) : igsJson; overload;

  function get(name : string; var value : integer) : igsJson; overload;
  function get(index : integer; var value : integer) : igsJson; overload;

  function get(name : string; var value : Double) : igsJson; overload;
  function get(index : integer; var value : Double) : igsJson; overload;

  function get(name : string; var value : Boolean) : igsJson; overload;
  function get(index : integer; var value : Boolean) : igsJson; overload;

  //Object / Array
  function get(name : string; var value : igsJson) : igsJson; overload;
  function get(index : integer; var value : igsJson) : igsJson; overload;

  //Analyses.
  function jsonElementCount : integer;
  function jsonElementType(index : integer) : TgsJsonElementType;
  function jsonType : TgsJsonElementType;
  function jsonElementName(index : integer) : string;

  function clear : igsJson;

  //Base type easy access.
  function asString(name : String) : string;
  function asInteger(name : String) : integer;
  function asNumber(name : String) : double;
  function asBoolean(name : String) : Boolean;
  function asObj(name : String) : igsJson; overload;
  function asObj(index : integer) : igsJson; overload;

  function add(val : igsJson) : igsJson; overload;
  function add(val : double) : igsJson; overload;
  function add(val : integer) : igsJson; overload;
  function add(val : string) : igsJson; overload;
  function add(val : byte) : igsJson; overload;
  function add(val : boolean) : igsJson; overload;

  function isNameExists(name: String): boolean;

  function ToObj : igsJson;
  function ToArray : igsJson;
end;

TgsJsonImplUJsonFactory = class(TInterfacedObject, igsJsonFactory)
  function getAuthor : string;
  function getTitle : string;
  function getDesc : string;
  function getId : string;
  function getJson : igsJson;
end;

implementation

function isSingleton(obj : TZAbstractObject) : boolean;
begin
  result := (obj = TJSONObject.ObjNULL)
         or (obj = TJSONBool._TRUE)
         or (obj = TJSONBool._FALSE);
end;

procedure safeFreeJson(var obj : TZAbstractObject; owned : boolean);
begin
  if owned and (obj <> nil) and (not isSingleton(obj)) then
    FreeAndNil(obj)
  else
    obj := nil;
end;

function itemToElementType(aItem : TZAbstractObject) : TgsJsonElementType;
begin
  result := TgsJsonElementType.etEmpty;
  if aItem = nil then
    exit;
  if aItem is TJSONNull then
    result := TgsJsonElementType.etNull
  else if aItem is TJSONBool then
    result := TgsJsonElementType.etBoolean
  else if aItem is TJSONNumber then
    result := TgsJsonElementType.etNumber
  else if aItem is TJSONString then
    result := TgsJsonElementType.etString
  else if aItem is TJSONObject then
    result := TgsJsonElementType.etJson
  else if aItem is TJSONArray then
    result := TgsJsonElementType.etJsonArray;
end;

procedure extractValue(source : TZAbstractObject; var value : igsJson);
begin
  if not assigned(value) then
    value := TgsJsonImplUJson.Create;

  if TgsJsonImplUJson(value).FOwned and (TgsJsonImplUJson(value).FJson <> nil)
    and (not isSingleton(TgsJsonImplUJson(value).FJson)) then
    TgsJsonImplUJson(value).FJson.Free;
  TgsJsonImplUJson(value).FJson := source;
  TgsJsonImplUJson(value).FOwned := false;
end;

function getAsObj(var FJson : TZAbstractObject; var FOwned : boolean) : TJSONObject;
begin
  if not (FJson is TJSONObject) then begin
    safeFreeJson(FJson, FOwned);
    FJson := TJSONObject.Create;
    FOwned := true;
  end;
  result := TJSONObject(FJson);
end;

function getAsArr(var FJson : TZAbstractObject; var FOwned : boolean) : TJSONArray;
begin
  if not (FJson is TJSONArray) then begin
    safeFreeJson(FJson, FOwned);
    FJson := TJSONArray.Create;
    FOwned := true;
  end;
  result := TJSONArray(FJson);
end;

procedure addToArray(arr : TJSONArray; const vals : array of const);
begin
  for var i := Low(vals) to High(vals) do begin
    case vals[i].VType of
      vtString : arr.put(TJSONString.Create(String(vals[i].VString^)));
      vtWideString : arr.put(TJSONString.Create(String(vals[i].VWideString)));
      vtUnicodeString : arr.put(TJSONString.Create(UnicodeString(vals[i].VUnicodeString)));
      vtInteger : arr.put(TJSONInteger.Create(vals[i].VInteger));
      vtBoolean : arr.put(TJSONBool.valueOf(vals[i].VBoolean));
      vtExtended : arr.put(TJSONDouble.Create(vals[i].VExtended^));
      vtInterface : begin
        var js := igsJson(vals[i].VInterface);
        var parsed := TJSONObject.Create(js.stringify);
        arr.put(parsed);
      end;
    end;
  end;
end;

function firstNonWhitespace(const s : string) : char;
begin
  result := #0;
  for var i := 1 to Length(s) do begin
    if not CharInSet(s[i], [' ', #9, #10, #13]) then begin
      result := s[i];
      exit;
    end;
  end;
end;

{ TgsJsonImplUJson }

constructor TgsJsonImplUJson.Create;
begin
  FJson := nil;
  FOwned := true;
end;

destructor TgsJsonImplUJson.Destroy;
begin
  safeFreeJson(FJson, FOwned);
  inherited;
end;

function TgsJsonImplUJson.parse(aJsonStr: string): igsJson;
var
  trimmed : string;
  c : char;
begin
  result := self;
  safeFreeJson(FJson, FOwned);

  trimmed := Trim(aJsonStr);
  if trimmed = '' then
    raise Exception.Create('Empty JSON string');

  c := firstNonWhitespace(trimmed);
  case c of
    '{' : FJson := TJSONObject.Create(trimmed);
    '[' : FJson := TJSONArray.Create(trimmed);
  else
    // Bare value: try to parse as a wrapped value and extract
    // Wrap in array to parse, then extract the single value
    var wrapped := '[' + trimmed + ']';
    var arr := TJSONArray.Create(wrapped);
    try
      if arr.length = 1 then begin
        var item := arr.get(0);
        if item <> nil then begin
          if isSingleton(item) then
            // Clone singletons since arr destructor won't free them
            // but we need an owned copy
            FJson := item.Clone
          else begin
            // Steal item from array by replacing with nil before array is freed
            // Unfortunately TJSONArray doesn't expose removal, so clone it
            FJson := item.Clone;
          end;
        end else
          raise Exception.Create('JSON parse error: ' + aJsonStr);
      end else
        raise Exception.Create('JSON parse error: ' + aJsonStr);
    finally
      arr.Free;
    end;
  end;

  if FJson = nil then
    raise Exception.Create('JSON parse error: ' + aJsonStr);
  FOwned := true;
end;

function TgsJsonImplUJson.put(name: string; val: double): igsJson;
begin
  result := self;
  var obj := getAsObj(FJson, FOwned);
  obj.put(name, val);
end;

function TgsJsonImplUJson.put(name, val: string): igsJson;
begin
  result := self;
  var obj := getAsObj(FJson, FOwned);
  obj.put(name, val);
end;

function TgsJsonImplUJson.put(name: string; val: boolean): igsJson;
begin
  result := self;
  var obj := getAsObj(FJson, FOwned);
  obj.put(name, val);
end;

function TgsJsonImplUJson.put(vals: array of const): igsJson;
begin
  result := self;
  var arr := getAsArr(FJson, FOwned);
  addToArray(arr, vals);
end;

function TgsJsonImplUJson.put(name: string; vals: array of const): igsJson;
begin
  result := self;
  var obj := getAsObj(FJson, FOwned);
  var arr := TJSONArray.Create;
  addToArray(arr, vals);
  obj.put(name, arr);
end;

function TgsJsonImplUJson.put(name: string; val: igsJson): igsJson;
begin
  result := self;
  var obj := getAsObj(FJson, FOwned);
  var s := val.stringify;
  var c := firstNonWhitespace(s);
  case c of
    '{' : obj.put(name, TJSONObject.Create(s));
    '[' : obj.put(name, TJSONArray.Create(s) as TZAbstractObject);
  else
    // Should not happen for a valid igsJson, but handle gracefully
    obj.put(name, TJSONString.Create(s));
  end;
end;

function TgsJsonImplUJson.put(val: igsJson): igsJson;
begin
  result := self;
  var arr := getAsArr(FJson, FOwned);
  var s := val.stringify;
  var c := firstNonWhitespace(s);
  case c of
    '{' : arr.put(TJSONObject.Create(s));
    '[' : arr.put(TJSONArray.Create(s) as TZAbstractObject);
  else
    arr.put(TJSONString.Create(s));
  end;
end;

function TgsJsonImplUJson.stringify(var aStr: string): igsJson;
begin
  result := self;
  if FJson <> nil then
    aStr := TJSONObject.valueToString(FJson)
  else
    aStr := 'null';
end;

function TgsJsonImplUJson.stringify: string;
begin
  if FJson <> nil then
    result := TJSONObject.valueToString(FJson)
  else
    result := 'null';
end;

function TgsJsonImplUJson.get(name: string; var value: string): igsJson;
begin
  result := self;
  if FJson is TJSONObject then begin
    var o := TJSONObject(FJson).opt(name);
    if o <> nil then
      value := o.toString
    else
      raise Exception.Create('TgsJsonImplUJson.get: Key not found: ' + name);
  end
  else
    raise Exception.Create('TgsJsonImplUJson.get: Not an object');
end;

function TgsJsonImplUJson.get(index: integer; var value: string): igsJson;
begin
  result := self;
  if FJson is TJSONObject then begin
    var obj := TJSONObject(FJson);
    var k := obj.keys;
    try
      assert(index < k.Count);
      var o := obj.opt(k[index]);
      if o <> nil then
        value := o.toString
      else
        value := '';
    finally
      k.Free;
    end;
  end
  else if FJson is TJSONArray then begin
    var arr := TJSONArray(FJson);
    assert(index < arr.length);
    value := arr.getString(index);
  end;
end;

function TgsJsonImplUJson.get(name: string; var value: integer): igsJson;
begin
  result := self;
  if FJson is TJSONObject then begin
    value := TJSONObject(FJson).getInt(name);
  end
  else
    raise Exception.Create('TgsJsonImplUJson.get: Not an object');
end;

function TgsJsonImplUJson.get(index: integer; var value: integer): igsJson;
begin
  result := self;
  if FJson is TJSONObject then begin
    var obj := TJSONObject(FJson);
    var k := obj.keys;
    try
      assert(index < k.Count);
      value := obj.getInt(k[index]);
    finally
      k.Free;
    end;
  end
  else if FJson is TJSONArray then begin
    assert(index < TJSONArray(FJson).length);
    value := TJSONArray(FJson).getInt(index);
  end;
end;

function TgsJsonImplUJson.get(name: string; var value: Double): igsJson;
begin
  result := self;
  if FJson is TJSONObject then begin
    value := TJSONObject(FJson).getDouble(name);
  end
  else
    raise Exception.Create('TgsJsonImplUJson.get: Not an object');
end;

function TgsJsonImplUJson.get(index: integer; var value: Double): igsJson;
begin
  result := self;
  if FJson is TJSONObject then begin
    var obj := TJSONObject(FJson);
    var k := obj.keys;
    try
      assert(index < k.Count);
      value := obj.getDouble(k[index]);
    finally
      k.Free;
    end;
  end
  else if FJson is TJSONArray then begin
    assert(index < TJSONArray(FJson).length);
    value := TJSONArray(FJson).getDouble(index);
  end;
end;

function TgsJsonImplUJson.get(name: string; var value: Boolean): igsJson;
begin
  result := self;
  if FJson is TJSONObject then begin
    value := TJSONObject(FJson).getBoolean(name);
  end
  else
    raise Exception.Create('TgsJsonImplUJson.get: Not an object');
end;

function TgsJsonImplUJson.get(index: integer; var value: Boolean): igsJson;
begin
  result := self;
  if FJson is TJSONObject then begin
    var obj := TJSONObject(FJson);
    var k := obj.keys;
    try
      assert(index < k.Count);
      value := obj.getBoolean(k[index]);
    finally
      k.Free;
    end;
  end
  else if FJson is TJSONArray then begin
    assert(index < TJSONArray(FJson).length);
    value := TJSONArray(FJson).getBoolean(index);
  end;
end;

function TgsJsonImplUJson.get(name: string; var value: igsJson): igsJson;
begin
  result := self;
  if FJson is TJSONObject then begin
    var o := TJSONObject(FJson).opt(name);
    if o <> nil then
      extractValue(o, value)
    else
      raise Exception.Create('TgsJsonImplUJson.get: Key not found: ' + name);
  end
  else
    raise Exception.Create('TgsJsonImplUJson.get: Not an object');
end;

function TgsJsonImplUJson.get(index: integer; var value: igsJson): igsJson;
begin
  result := self;
  if FJson is TJSONObject then begin
    var obj := TJSONObject(FJson);
    var k := obj.keys;
    try
      assert(index < k.Count);
      var o := obj.opt(k[index]);
      extractValue(o, value);
    finally
      k.Free;
    end;
  end
  else if FJson is TJSONArray then begin
    assert(index < TJSONArray(FJson).length);
    extractValue(TJSONArray(FJson).get(index), value);
  end;
end;

function TgsJsonImplUJson.jsonElementCount: integer;
begin
  if FJson is TJSONObject then
    result := TJSONObject(FJson).length
  else if FJson is TJSONArray then
    result := TJSONArray(FJson).length
  else
    result := -1;
end;

function TgsJsonImplUJson.jsonElementType(index: integer): TgsJsonElementType;
begin
  result := TgsJsonElementType.etEmpty;
  if FJson is TJSONObject then begin
    var obj := TJSONObject(FJson);
    var k := obj.keys;
    try
      if (index >= 0) and (index < k.Count) then
        result := itemToElementType(obj.opt(k[index]));
    finally
      k.Free;
    end;
  end
  else if FJson is TJSONArray then begin
    var arr := TJSONArray(FJson);
    if (index >= 0) and (index < arr.length) then
      result := itemToElementType(arr.opt(index));
  end;
end;

function TgsJsonImplUJson.jsonType: TgsJsonElementType;
begin
  result := itemToElementType(FJson);
end;

function TgsJsonImplUJson.jsonElementName(index: integer): string;
begin
  result := '';
  if FJson is TJSONObject then begin
    var obj := TJSONObject(FJson);
    var k := obj.keys;
    try
      assert(index < k.Count);
      result := k[index];
    finally
      k.Free;
    end;
  end
  else
    raise Exception.Create('TgsJsonImplUJson.jsonElementName: Not an object');
end;

function TgsJsonImplUJson.clear: igsJson;
begin
  result := self;
  safeFreeJson(FJson, FOwned);
  FJson := nil;
  FOwned := true;
end;

function TgsJsonImplUJson.asString(name: String): string;
begin
  get(name, result);
end;

function TgsJsonImplUJson.asInteger(name: String): integer;
begin
  get(name, result);
end;

function TgsJsonImplUJson.asNumber(name: String): double;
begin
  get(name, result);
end;

function TgsJsonImplUJson.asBoolean(name: String): Boolean;
begin
  get(name, result);
end;

function TgsJsonImplUJson.asObj(name: String): igsJson;
begin
  get(name, result);
end;

function TgsJsonImplUJson.asObj(index: integer): igsJson;
begin
  get(index, result);
end;

function TgsJsonImplUJson.add(val: igsJson): igsJson;
begin
  result := self;
  var arr := getAsArr(FJson, FOwned);
  var s := val.stringify;
  var c := firstNonWhitespace(s);
  case c of
    '{' : arr.put(TJSONObject.Create(s));
    '[' : arr.put(TJSONArray.Create(s) as TZAbstractObject);
  else
    arr.put(TJSONString.Create(s));
  end;
end;

function TgsJsonImplUJson.add(val: double): igsJson;
begin
  result := self;
  var arr := getAsArr(FJson, FOwned);
  arr.put(TJSONDouble.Create(val));
end;

function TgsJsonImplUJson.add(val: integer): igsJson;
begin
  result := self;
  var arr := getAsArr(FJson, FOwned);
  arr.put(TJSONInteger.Create(val));
end;

function TgsJsonImplUJson.add(val: string): igsJson;
begin
  result := self;
  var arr := getAsArr(FJson, FOwned);
  arr.put(TJSONString.Create(val));
end;

function TgsJsonImplUJson.add(val: byte): igsJson;
begin
  result := self;
  var arr := getAsArr(FJson, FOwned);
  arr.put(TJSONInteger.Create(Integer(val)));
end;

function TgsJsonImplUJson.add(val: boolean): igsJson;
begin
  result := self;
  var arr := getAsArr(FJson, FOwned);
  arr.put(TJSONBool.valueOf(val));
end;

function TgsJsonImplUJson.isNameExists(name: String): boolean;
begin
  result := false;
  if FJson is TJSONObject then
    result := TJSONObject(FJson).has(name);
end;

function TgsJsonImplUJson.ToObj: igsJson;
begin
  result := self;
  if not (FJson is TJSONObject) then begin
    safeFreeJson(FJson, FOwned);
    FJson := TJSONObject.Create;
    FOwned := true;
  end;
end;

function TgsJsonImplUJson.ToArray: igsJson;
begin
  result := self;
  if not (FJson is TJSONArray) then begin
    safeFreeJson(FJson, FOwned);
    FJson := TJSONArray.Create;
    FOwned := true;
  end;
end;

{ TgsJsonImplUJsonFactory }

function TgsJsonImplUJsonFactory.getAuthor: string;
begin
  result := 'Fabio Almeida';
end;

function TgsJsonImplUJsonFactory.getTitle: string;
begin
  result := 'uJSON';
end;

function TgsJsonImplUJsonFactory.getDesc: string;
begin
  result := 'uJSON - Delphi port of Java JSON library';
end;

function TgsJsonImplUJsonFactory.getId: string;
begin
  result := 'ujson';
end;

function TgsJsonImplUJsonFactory.getJson: igsJson;
begin
  result := TgsJsonImplUJson.Create;
end;

initialization

addImplementation(TgsJsonImplUJsonFactory.Create);

end.
