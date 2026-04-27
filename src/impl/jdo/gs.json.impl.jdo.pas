///*******************************************************
///
/// JsonLibsTests
///
/// 2026-2027 Grid System SAS
///
///
///*******************************************************

unit gs.json.impl.jdo;

interface

uses sysutils,
     classes,
     gs.Json,
     JsonDataObjects;

type

TgsJsonImplJdo = class(TInterfacedObject, igsJson)
private
protected
  FJson : TJsonBaseObject;
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

TgsJsonImplJdoFactory = class(TInterfacedObject, igsJsonFactory)
  function getAuthor : string;
  function getTitle : string;
  function getDesc : string;
  function getId : string;
  function getJson : igsJson;
end;

implementation

function jdoTypeToElementType(aType : TJsonDataType) : TgsJsonElementType;
begin
  case aType of
    jdtNone :     result := TgsJsonElementType.etNull;
    jdtString :   result := TgsJsonElementType.etString;
    jdtInt,
    jdtLong,
    jdtULong,
    jdtFloat,
    jdtDateTime,
    jdtUtcDateTime : result := TgsJsonElementType.etNumber;
    jdtBool :     result := TgsJsonElementType.etBoolean;
    jdtObject :   result := TgsJsonElementType.etJson;
    jdtArray :    result := TgsJsonElementType.etJsonArray;
  else
    result := TgsJsonElementType.etEmpty;
  end;
end;

function jdoBaseToElementType(aObj : TJsonBaseObject) : TgsJsonElementType;
begin
  result := TgsJsonElementType.etEmpty;
  if aObj = nil then
    exit;
  if aObj is TJsonObject then
    result := TgsJsonElementType.etJson
  else if aObj is TJsonArray then
    result := TgsJsonElementType.etJsonArray;
end;

procedure extractValue(source : TJsonBaseObject; var value : igsJson);
begin
  if not assigned(value) then
    value := TgsJsonImplJdo.Create;

  if TgsJsonImplJdo(value).FOwned and (TgsJsonImplJdo(value).FJson <> nil) then
    TgsJsonImplJdo(value).FJson.Free;
  TgsJsonImplJdo(value).FJson := source;
  TgsJsonImplJdo(value).FOwned := false;
end;

function getAsObj(var FJson : TJsonBaseObject; var FOwned : boolean) : TJsonObject;
begin
  if not (FJson is TJsonObject) then begin
    if FOwned and (FJson <> nil) then
      FJson.Free;
    FJson := TJsonObject.Create;
    FOwned := true;
  end;
  result := TJsonObject(FJson);
end;

function getAsArr(var FJson : TJsonBaseObject; var FOwned : boolean) : TJsonArray;
begin
  if not (FJson is TJsonArray) then begin
    if FOwned and (FJson <> nil) then
      FJson.Free;
    FJson := TJsonArray.Create;
    FOwned := true;
  end;
  result := TJsonArray(FJson);
end;

procedure addToArray(arr : TJsonArray; const vals : array of const);
begin
  for var i := Low(vals) to High(vals) do begin
    case vals[i].VType of
      vtString : arr.Add(String(vals[i].VString^));
      vtWideString : arr.Add(String(vals[i].VWideString));
      vtUnicodeString : arr.Add(UnicodeString(vals[i].VUnicodeString));
      vtInteger : arr.Add(vals[i].VInteger);
      vtBoolean : arr.Add(vals[i].VBoolean);
      vtExtended : arr.Add(Double(vals[i].VExtended^));
    end;
  end;
end;

{ TgsJsonImplJdo }

constructor TgsJsonImplJdo.Create;
begin
  FJson := nil;
  FOwned := true;
end;

destructor TgsJsonImplJdo.Destroy;
begin
  if FOwned and (FJson <> nil) then
    FreeAndNil(FJson);
  inherited;
end;

function TgsJsonImplJdo.parse(aJsonStr: string): igsJson;
begin
  result := self;
  if FOwned and (FJson <> nil) then
    FreeAndNil(FJson);
  var trimmed := aJsonStr.Trim;
  if trimmed = '' then
    raise JsonException.Create('Empty JSON string');
  FJson := TJsonBaseObject.Parse(trimmed);
  if FJson = nil then
    raise Exception.Create('JSON parse error: ' + aJsonStr);
  FOwned := true;
end;

function TgsJsonImplJdo.put(name: string; val: double): igsJson;
begin
  result := self;
  var obj := getAsObj(FJson, FOwned);
  if obj.Contains(name) then
    obj.Remove(name);
  obj.F[name] := val;
end;

function TgsJsonImplJdo.put(name, val: string): igsJson;
begin
  result := self;
  var obj := getAsObj(FJson, FOwned);
  if obj.Contains(name) then
    obj.Remove(name);
  obj.S[name] := val;
end;

function TgsJsonImplJdo.put(name: string; val: boolean): igsJson;
begin
  result := self;
  var obj := getAsObj(FJson, FOwned);
  if obj.Contains(name) then
    obj.Remove(name);
  obj.B[name] := val;
end;

function TgsJsonImplJdo.put(vals: array of const): igsJson;
begin
  result := self;
  var arr := getAsArr(FJson, FOwned);
  addToArray(arr, vals);
end;

function TgsJsonImplJdo.put(name: string; vals: array of const): igsJson;
begin
  result := self;
  var obj := getAsObj(FJson, FOwned);
  if obj.Contains(name) then
    obj.Remove(name);
  var arr := obj.A[name]; // auto-creates TJsonArray
  addToArray(arr, vals);
end;

function TgsJsonImplJdo.put(name: string; val: igsJson): igsJson;
begin
  result := self;
  var obj := getAsObj(FJson, FOwned);
  if obj.Contains(name) then
    obj.Remove(name);
  var parsed := TJsonBaseObject.Parse(val.stringify);
  if parsed <> nil then begin
    if parsed is TJsonObject then
      obj.O[name] := TJsonObject(parsed)
    else if parsed is TJsonArray then
      obj.A[name] := TJsonArray(parsed)
    else
      parsed.Free;
  end;
end;

function TgsJsonImplJdo.put(val: igsJson): igsJson;
begin
  result := self;
  var arr := getAsArr(FJson, FOwned);
  var parsed := TJsonBaseObject.Parse(val.stringify);
  if parsed <> nil then begin
    if parsed is TJsonObject then
      arr.Add(TJsonObject(parsed))
    else if parsed is TJsonArray then
      arr.Add(TJsonArray(parsed))
    else
      parsed.Free;
  end;
end;

function TgsJsonImplJdo.stringify(var aStr: string): igsJson;
begin
  result := self;
  if FJson <> nil then
    aStr := FJson.ToJSON(True)
  else
    aStr := 'null';
end;

function TgsJsonImplJdo.stringify: string;
begin
  if FJson <> nil then
    result := FJson.ToJSON(True)
  else
    result := 'null';
end;

function TgsJsonImplJdo.get(name: string; var value: string): igsJson;
begin
  result := self;
  if FJson is TJsonObject then begin
    if not TJsonObject(FJson).Contains(name) then
      raise Exception.Create('TgsJsonImplJdo.get: Key not found: ' + name);
    value := TJsonObject(FJson).S[name];
  end
  else
    raise Exception.Create('TgsJsonImplJdo.get: Not an object');
end;

function TgsJsonImplJdo.get(index: integer; var value: string): igsJson;
begin
  result := self;
  if FJson is TJsonObject then begin
    assert(index < TJsonObject(FJson).Count);
    value := TJsonObject(FJson).Items[index].Value;
  end
  else if FJson is TJsonArray then begin
    assert(index < TJsonArray(FJson).Count);
    value := TJsonArray(FJson).S[index];
  end;
end;

function TgsJsonImplJdo.get(name: string; var value: integer): igsJson;
begin
  result := self;
  if FJson is TJsonObject then begin
    value := TJsonObject(FJson).I[name];
  end
  else
    raise Exception.Create('TgsJsonImplJdo.get: Not an object');
end;

function TgsJsonImplJdo.get(index: integer; var value: integer): igsJson;
begin
  result := self;
  if FJson is TJsonObject then begin
    assert(index < TJsonObject(FJson).Count);
    value := TJsonObject(FJson).Items[index].IntValue;
  end
  else if FJson is TJsonArray then begin
    assert(index < TJsonArray(FJson).Count);
    value := TJsonArray(FJson).I[index];
  end;
end;

function TgsJsonImplJdo.get(name: string; var value: Double): igsJson;
begin
  result := self;
  if FJson is TJsonObject then begin
    value := TJsonObject(FJson).F[name];
  end
  else
    raise Exception.Create('TgsJsonImplJdo.get: Not an object');
end;

function TgsJsonImplJdo.get(index: integer; var value: Double): igsJson;
begin
  result := self;
  if FJson is TJsonObject then begin
    assert(index < TJsonObject(FJson).Count);
    value := TJsonObject(FJson).Items[index].FloatValue;
  end
  else if FJson is TJsonArray then begin
    assert(index < TJsonArray(FJson).Count);
    value := TJsonArray(FJson).F[index];
  end;
end;

function TgsJsonImplJdo.get(name: string; var value: Boolean): igsJson;
begin
  result := self;
  if FJson is TJsonObject then begin
    value := TJsonObject(FJson).B[name];
  end
  else
    raise Exception.Create('TgsJsonImplJdo.get: Not an object');
end;

function TgsJsonImplJdo.get(index: integer; var value: Boolean): igsJson;
begin
  result := self;
  if FJson is TJsonObject then begin
    assert(index < TJsonObject(FJson).Count);
    value := TJsonObject(FJson).Items[index].BoolValue;
  end
  else if FJson is TJsonArray then begin
    assert(index < TJsonArray(FJson).Count);
    value := TJsonArray(FJson).B[index];
  end;
end;

function TgsJsonImplJdo.get(name: string; var value: igsJson): igsJson;
begin
  result := self;
  if FJson is TJsonObject then begin
    if not TJsonObject(FJson).Contains(name) then
      raise Exception.Create('TgsJsonImplJdo.get: Key not found: ' + name);
    var dt := TJsonObject(FJson).Types[name];
    if dt = jdtObject then
      extractValue(TJsonObject(FJson).O[name], value)
    else if dt = jdtArray then
      extractValue(TJsonObject(FJson).A[name], value)
    else
      raise Exception.Create('TgsJsonImplJdo.get: Value is not an object or array');
  end
  else
    raise Exception.Create('TgsJsonImplJdo.get: Not an object');
end;

function TgsJsonImplJdo.get(index: integer; var value: igsJson): igsJson;
begin
  result := self;
  if FJson is TJsonObject then begin
    assert(index < TJsonObject(FJson).Count);
    var item := TJsonObject(FJson).Items[index];
    if item.Typ = jdtObject then
      extractValue(item.ObjectValue, value)
    else if item.Typ = jdtArray then
      extractValue(item.ArrayValue, value)
    else
      raise Exception.Create('TgsJsonImplJdo.get: Value at index is not an object or array');
  end
  else if FJson is TJsonArray then begin
    assert(index < TJsonArray(FJson).Count);
    var item := TJsonArray(FJson).Items[index];
    if item.Typ = jdtObject then
      extractValue(item.ObjectValue, value)
    else if item.Typ = jdtArray then
      extractValue(item.ArrayValue, value)
    else
      raise Exception.Create('TgsJsonImplJdo.get: Value at index is not an object or array');
  end;
end;

function TgsJsonImplJdo.jsonElementCount: integer;
begin
  if FJson is TJsonObject then
    result := TJsonObject(FJson).Count
  else if FJson is TJsonArray then
    result := TJsonArray(FJson).Count
  else
    result := -1;
end;

function TgsJsonImplJdo.jsonElementType(index: integer): TgsJsonElementType;
begin
  result := TgsJsonElementType.etEmpty;
  if FJson is TJsonObject then
    result := jdoTypeToElementType(TJsonObject(FJson).Items[index].Typ)
  else if FJson is TJsonArray then
    result := jdoTypeToElementType(TJsonArray(FJson).Types[index]);
end;

function TgsJsonImplJdo.jsonType: TgsJsonElementType;
begin
  result := jdoBaseToElementType(FJson);
end;

function TgsJsonImplJdo.jsonElementName(index: integer): string;
begin
  result := '';
  if FJson is TJsonObject then begin
    assert(index < TJsonObject(FJson).Count);
    result := TJsonObject(FJson).Names[index];
  end
  else
    raise Exception.Create('TgsJsonImplJdo.jsonElementName: Not an object');
end;

function TgsJsonImplJdo.clear: igsJson;
begin
  result := self;
  if FOwned and (FJson <> nil) then
    FreeAndNil(FJson);
  FJson := nil;
  FOwned := true;
end;

function TgsJsonImplJdo.asString(name: String): string;
begin
  get(name, result);
end;

function TgsJsonImplJdo.asInteger(name: String): integer;
begin
  get(name, result);
end;

function TgsJsonImplJdo.asNumber(name: String): double;
begin
  get(name, result);
end;

function TgsJsonImplJdo.asBoolean(name: String): Boolean;
begin
  get(name, result);
end;

function TgsJsonImplJdo.asObj(name: String): igsJson;
begin
  get(name, result);
end;

function TgsJsonImplJdo.asObj(index: integer): igsJson;
begin
  get(index, result);
end;

function TgsJsonImplJdo.add(val: igsJson): igsJson;
begin
  result := self;
  var arr := getAsArr(FJson, FOwned);
  var parsed := TJsonBaseObject.Parse(val.stringify);
  if parsed <> nil then begin
    if parsed is TJsonObject then
      arr.Add(TJsonObject(parsed))
    else if parsed is TJsonArray then
      arr.Add(TJsonArray(parsed))
    else
      parsed.Free;
  end;
end;

function TgsJsonImplJdo.add(val: double): igsJson;
begin
  result := self;
  var arr := getAsArr(FJson, FOwned);
  arr.Add(val);
end;

function TgsJsonImplJdo.add(val: integer): igsJson;
begin
  result := self;
  var arr := getAsArr(FJson, FOwned);
  arr.Add(val);
end;

function TgsJsonImplJdo.add(val: string): igsJson;
begin
  result := self;
  var arr := getAsArr(FJson, FOwned);
  arr.Add(val);
end;

function TgsJsonImplJdo.add(val: byte): igsJson;
begin
  result := self;
  var arr := getAsArr(FJson, FOwned);
  arr.Add(Integer(val));
end;

function TgsJsonImplJdo.add(val: boolean): igsJson;
begin
  result := self;
  var arr := getAsArr(FJson, FOwned);
  arr.Add(val);
end;

function TgsJsonImplJdo.isNameExists(name: String): boolean;
begin
  result := false;
  if FJson is TJsonObject then
    result := TJsonObject(FJson).Contains(name);
end;

function TgsJsonImplJdo.ToObj: igsJson;
begin
  result := self;
  if not (FJson is TJsonObject) then begin
    if FOwned and (FJson <> nil) then FJson.Free;
    FJson := TJsonObject.Create;
    FOwned := true;
  end;
end;

function TgsJsonImplJdo.ToArray: igsJson;
begin
  result := self;
  if not (FJson is TJsonArray) then begin
    if FOwned and (FJson <> nil) then FJson.Free;
    FJson := TJsonArray.Create;
    FOwned := true;
  end;
end;

{ TgsJsonImplJdoFactory }

function TgsJsonImplJdoFactory.getAuthor: string;
begin
  result := 'Andreas Hausladen';
end;

function TgsJsonImplJdoFactory.getTitle: string;
begin
  result := 'JsonDataObjects';
end;

function TgsJsonImplJdoFactory.getDesc: string;
begin
  result := '';
end;

function TgsJsonImplJdoFactory.getId: string;
begin
  result := 'jdo';
end;

function TgsJsonImplJdoFactory.getJson: igsJson;
begin
  result := TgsJsonImplJdo.Create;
end;

initialization

addImplementation(TgsJsonImplJdoFactory.Create);

end.
