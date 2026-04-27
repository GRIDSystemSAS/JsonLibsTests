///*******************************************************
///
/// JsonLibsTests
///
/// 2026-2027 Grid System SAS
///
///
///*******************************************************

unit gs.json.impl.dwsJson;

interface

uses sysutils,
     classes,
     gs.Json,
     dwsJSON;

type

TgsJsonImplDwsJson = class(TInterfacedObject, igsJson)
private
protected
  FJson : TdwsJSONValue;
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

TgsJsonImplDwsJsonFactory = class(TInterfacedObject, igsJsonFactory)
  function getAuthor : string;
  function getTitle : string;
  function getDesc : string;
  function getId : string;
  function getJson : igsJson;
end;

implementation

function valueToElementType(aValue : TdwsJSONValue) : TgsJsonElementType;
begin
  result := TgsJsonElementType.etEmpty;
  if aValue = nil then
    exit;
  case aValue.ValueType of
    TdwsJSONValueType.jvtUndefined : result := TgsJsonElementType.etEmpty;
    TdwsJSONValueType.jvtNull      : result := TgsJsonElementType.etNull;
    TdwsJSONValueType.jvtObject    : result := TgsJsonElementType.etJson;
    TdwsJSONValueType.jvtArray     : result := TgsJsonElementType.etJsonArray;
    TdwsJSONValueType.jvtString    : result := TgsJsonElementType.etString;
    TdwsJSONValueType.jvtNumber    : result := TgsJsonElementType.etNumber;
    TdwsJSONValueType.jvtBoolean   : result := TgsJsonElementType.etBoolean;
  end;
end;

procedure extractValue(source : TdwsJSONValue; var value : igsJson);
begin
  if not assigned(value) then
    value := TgsJsonImplDwsJson.Create;

  if TgsJsonImplDwsJson(value).FOwned and (TgsJsonImplDwsJson(value).FJson <> nil) then
    TgsJsonImplDwsJson(value).FJson.Free;
  TgsJsonImplDwsJson(value).FJson := source;
  TgsJsonImplDwsJson(value).FOwned := false;
end;

function getAsObj(var FJson : TdwsJSONValue; var FOwned : boolean) : TdwsJSONObject;
begin
  if not (FJson is TdwsJSONObject) then begin
    if FOwned and (FJson <> nil) then
      FJson.Free;
    FJson := TdwsJSONObject.Create;
    FOwned := true;
  end;
  result := TdwsJSONObject(FJson);
end;

function getAsArr(var FJson : TdwsJSONValue; var FOwned : boolean) : TdwsJSONArray;
begin
  if not (FJson is TdwsJSONArray) then begin
    if FOwned and (FJson <> nil) then
      FJson.Free;
    FJson := TdwsJSONArray.Create;
    FOwned := true;
  end;
  result := TdwsJSONArray(FJson);
end;

procedure addToArray(arr : TdwsJSONArray; const vals : array of const);
begin
  for var i := Low(vals) to High(vals) do begin
    case vals[i].VType of
      vtString      : arr.Add(UnicodeString(String(vals[i].VString^)));
      vtWideString  : arr.Add(UnicodeString(vals[i].VWideString));
      vtUnicodeString : arr.Add(UnicodeString(vals[i].VUnicodeString));
      vtInteger     : arr.Add(Int64(vals[i].VInteger));
      vtBoolean     : arr.Add(vals[i].VBoolean);
      vtExtended    : arr.Add(Double(vals[i].VExtended^));
    end;
  end;
end;

{ TgsJsonImplDwsJson }

constructor TgsJsonImplDwsJson.Create;
begin
  FJson := nil;
  FOwned := true;
end;

destructor TgsJsonImplDwsJson.Destroy;
begin
  if FOwned and (FJson <> nil) then
    FreeAndNil(FJson);
  inherited;
end;

function TgsJsonImplDwsJson.parse(aJsonStr: string): igsJson;
begin
  result := self;
  if FOwned and (FJson <> nil) then
    FreeAndNil(FJson);
  var trimmed := aJsonStr.Trim;
  if trimmed = '' then
    raise JsonException.Create('Empty JSON string');
  FJson := TdwsJSONValue.ParseString(trimmed);
  if FJson = nil then
    raise Exception.Create('JSON parse error: ' + aJsonStr);
  FOwned := true;
end;

function TgsJsonImplDwsJson.put(name: string; val: double): igsJson;
begin
  result := self;
  var obj := getAsObj(FJson, FOwned);
  // Delete existing key if present (Items[] returns nil if not found)
  if obj.Items[name] <> nil then
    obj.Delete(name);
  obj.AddValue(name, val);
end;

function TgsJsonImplDwsJson.put(name, val: string): igsJson;
begin
  result := self;
  var obj := getAsObj(FJson, FOwned);
  if obj.Items[name] <> nil then
    obj.Delete(name);
  obj.AddValue(name, UnicodeString(val));
end;

function TgsJsonImplDwsJson.put(name: string; val: boolean): igsJson;
begin
  result := self;
  var obj := getAsObj(FJson, FOwned);
  if obj.Items[name] <> nil then
    obj.Delete(name);
  obj.AddValue(name, val);
end;

function TgsJsonImplDwsJson.put(vals: array of const): igsJson;
begin
  result := self;
  var arr := getAsArr(FJson, FOwned);
  addToArray(arr, vals);
end;

function TgsJsonImplDwsJson.put(name: string; vals: array of const): igsJson;
begin
  result := self;
  var obj := getAsObj(FJson, FOwned);
  if obj.Items[name] <> nil then
    obj.Delete(name);
  var arr := obj.AddArray(name);
  addToArray(arr, vals);
end;

function TgsJsonImplDwsJson.put(name: string; val: igsJson): igsJson;
begin
  result := self;
  var obj := getAsObj(FJson, FOwned);
  if obj.Items[name] <> nil then
    obj.Delete(name);
  var parsed := TdwsJSONValue.ParseString(val.stringify);
  if parsed <> nil then
    obj.Add(name, parsed);
end;

function TgsJsonImplDwsJson.put(val: igsJson): igsJson;
begin
  result := self;
  var arr := getAsArr(FJson, FOwned);
  var parsed := TdwsJSONValue.ParseString(val.stringify);
  if parsed <> nil then
    arr.Add(parsed);
end;

function TgsJsonImplDwsJson.stringify(var aStr: string): igsJson;
begin
  result := self;
  if FJson <> nil then
    aStr := FJson.ToString
  else
    aStr := 'null';
end;

function TgsJsonImplDwsJson.stringify: string;
begin
  if FJson <> nil then
    result := FJson.ToString
  else
    result := 'null';
end;

function TgsJsonImplDwsJson.get(name: string; var value: string): igsJson;
begin
  result := self;
  if FJson is TdwsJSONObject then begin
    var v := TdwsJSONObject(FJson).Items[name];
    if (v <> nil) and v.IsDefined then
      value := v.AsString
    else
      raise Exception.Create('TgsJsonImplDwsJson.get: Key not found: ' + name);
  end
  else
    raise Exception.Create('TgsJsonImplDwsJson.get: Not an object');
end;

function TgsJsonImplDwsJson.get(index: integer; var value: string): igsJson;
begin
  result := self;
  if FJson is TdwsJSONObject then begin
    assert(index < TdwsJSONObject(FJson).ElementCount);
    value := TdwsJSONObject(FJson).Elements[index].AsString;
  end
  else if FJson is TdwsJSONArray then begin
    assert(index < TdwsJSONArray(FJson).ElementCount);
    value := TdwsJSONArray(FJson).Elements[index].AsString;
  end;
end;

function TgsJsonImplDwsJson.get(name: string; var value: integer): igsJson;
begin
  result := self;
  if FJson is TdwsJSONObject then begin
    var v := TdwsJSONObject(FJson).Items[name];
    if (v <> nil) and v.IsDefined then
      value := Integer(v.AsInteger)
    else
      raise Exception.Create('TgsJsonImplDwsJson.get: Key not found: ' + name);
  end
  else
    raise Exception.Create('TgsJsonImplDwsJson.get: Not an object');
end;

function TgsJsonImplDwsJson.get(index: integer; var value: integer): igsJson;
begin
  result := self;
  if FJson is TdwsJSONObject then begin
    assert(index < TdwsJSONObject(FJson).ElementCount);
    value := Integer(TdwsJSONObject(FJson).Elements[index].AsInteger);
  end
  else if FJson is TdwsJSONArray then begin
    assert(index < TdwsJSONArray(FJson).ElementCount);
    value := Integer(TdwsJSONArray(FJson).Elements[index].AsInteger);
  end;
end;

function TgsJsonImplDwsJson.get(name: string; var value: Double): igsJson;
begin
  result := self;
  if FJson is TdwsJSONObject then begin
    var v := TdwsJSONObject(FJson).Items[name];
    if (v <> nil) and v.IsDefined then
      value := v.AsNumber
    else
      raise Exception.Create('TgsJsonImplDwsJson.get: Key not found: ' + name);
  end
  else
    raise Exception.Create('TgsJsonImplDwsJson.get: Not an object');
end;

function TgsJsonImplDwsJson.get(index: integer; var value: Double): igsJson;
begin
  result := self;
  if FJson is TdwsJSONObject then begin
    assert(index < TdwsJSONObject(FJson).ElementCount);
    value := TdwsJSONObject(FJson).Elements[index].AsNumber;
  end
  else if FJson is TdwsJSONArray then begin
    assert(index < TdwsJSONArray(FJson).ElementCount);
    value := TdwsJSONArray(FJson).Elements[index].AsNumber;
  end;
end;

function TgsJsonImplDwsJson.get(name: string; var value: Boolean): igsJson;
begin
  result := self;
  if FJson is TdwsJSONObject then begin
    var v := TdwsJSONObject(FJson).Items[name];
    if (v <> nil) and v.IsDefined then
      value := v.AsBoolean
    else
      raise Exception.Create('TgsJsonImplDwsJson.get: Key not found: ' + name);
  end
  else
    raise Exception.Create('TgsJsonImplDwsJson.get: Not an object');
end;

function TgsJsonImplDwsJson.get(index: integer; var value: Boolean): igsJson;
begin
  result := self;
  if FJson is TdwsJSONObject then begin
    assert(index < TdwsJSONObject(FJson).ElementCount);
    value := TdwsJSONObject(FJson).Elements[index].AsBoolean;
  end
  else if FJson is TdwsJSONArray then begin
    assert(index < TdwsJSONArray(FJson).ElementCount);
    value := TdwsJSONArray(FJson).Elements[index].AsBoolean;
  end;
end;

function TgsJsonImplDwsJson.get(name: string; var value: igsJson): igsJson;
begin
  result := self;
  if FJson is TdwsJSONObject then begin
    var v := TdwsJSONObject(FJson).Items[name];
    if (v <> nil) and v.IsDefined then
      extractValue(v, value)
    else
      raise Exception.Create('TgsJsonImplDwsJson.get: Key not found: ' + name);
  end
  else
    raise Exception.Create('TgsJsonImplDwsJson.get: Not an object');
end;

function TgsJsonImplDwsJson.get(index: integer; var value: igsJson): igsJson;
begin
  result := self;
  if FJson is TdwsJSONObject then begin
    assert(index < TdwsJSONObject(FJson).ElementCount);
    extractValue(TdwsJSONObject(FJson).Elements[index], value);
  end
  else if FJson is TdwsJSONArray then begin
    assert(index < TdwsJSONArray(FJson).ElementCount);
    extractValue(TdwsJSONArray(FJson).Elements[index], value);
  end;
end;

function TgsJsonImplDwsJson.jsonElementCount: integer;
begin
  if FJson is TdwsJSONObject then
    result := TdwsJSONObject(FJson).ElementCount
  else if FJson is TdwsJSONArray then
    result := TdwsJSONArray(FJson).ElementCount
  else
    result := -1;
end;

function TgsJsonImplDwsJson.jsonElementType(index: integer): TgsJsonElementType;
begin
  result := TgsJsonElementType.etEmpty;
  if FJson is TdwsJSONObject then
    result := valueToElementType(TdwsJSONObject(FJson).Elements[index])
  else if FJson is TdwsJSONArray then
    result := valueToElementType(TdwsJSONArray(FJson).Elements[index]);
end;

function TgsJsonImplDwsJson.jsonType: TgsJsonElementType;
begin
  result := valueToElementType(FJson);
end;

function TgsJsonImplDwsJson.jsonElementName(index: integer): string;
begin
  result := '';
  if FJson is TdwsJSONObject then begin
    assert(index < TdwsJSONObject(FJson).ElementCount);
    result := TdwsJSONObject(FJson).Names[index];
  end
  else
    raise Exception.Create('TgsJsonImplDwsJson.jsonElementName: Not an object');
end;

function TgsJsonImplDwsJson.clear: igsJson;
begin
  result := self;
  if FOwned and (FJson <> nil) then
    FreeAndNil(FJson);
  FJson := nil;
  FOwned := true;
end;

function TgsJsonImplDwsJson.asString(name: String): string;
begin
  get(name, result);
end;

function TgsJsonImplDwsJson.asInteger(name: String): integer;
begin
  get(name, result);
end;

function TgsJsonImplDwsJson.asNumber(name: String): double;
begin
  get(name, result);
end;

function TgsJsonImplDwsJson.asBoolean(name: String): Boolean;
begin
  get(name, result);
end;

function TgsJsonImplDwsJson.asObj(name: String): igsJson;
begin
  get(name, result);
end;

function TgsJsonImplDwsJson.asObj(index: integer): igsJson;
begin
  get(index, result);
end;

function TgsJsonImplDwsJson.add(val: igsJson): igsJson;
begin
  result := self;
  var arr := getAsArr(FJson, FOwned);
  var parsed := TdwsJSONValue.ParseString(val.stringify);
  if parsed <> nil then
    arr.Add(parsed);
end;

function TgsJsonImplDwsJson.add(val: double): igsJson;
begin
  result := self;
  var arr := getAsArr(FJson, FOwned);
  arr.Add(val);
end;

function TgsJsonImplDwsJson.add(val: integer): igsJson;
begin
  result := self;
  var arr := getAsArr(FJson, FOwned);
  arr.Add(Int64(val));
end;

function TgsJsonImplDwsJson.add(val: string): igsJson;
begin
  result := self;
  var arr := getAsArr(FJson, FOwned);
  arr.Add(UnicodeString(val));
end;

function TgsJsonImplDwsJson.add(val: byte): igsJson;
begin
  result := self;
  var arr := getAsArr(FJson, FOwned);
  arr.Add(Int64(val));
end;

function TgsJsonImplDwsJson.add(val: boolean): igsJson;
begin
  result := self;
  var arr := getAsArr(FJson, FOwned);
  arr.Add(val);
end;

function TgsJsonImplDwsJson.isNameExists(name: String): boolean;
begin
  result := false;
  if FJson is TdwsJSONObject then
    result := TdwsJSONObject(FJson).Items[name] <> nil;
end;

function TgsJsonImplDwsJson.ToObj: igsJson;
begin
  result := self;
  if not (FJson is TdwsJSONObject) then begin
    if FOwned and (FJson <> nil) then FJson.Free;
    FJson := TdwsJSONObject.Create;
    FOwned := true;
  end;
end;

function TgsJsonImplDwsJson.ToArray: igsJson;
begin
  result := self;
  if not (FJson is TdwsJSONArray) then begin
    if FOwned and (FJson <> nil) then FJson.Free;
    FJson := TdwsJSONArray.Create;
    FOwned := true;
  end;
end;

{ TgsJsonImplDwsJsonFactory }

function TgsJsonImplDwsJsonFactory.getAuthor: string;
begin
  result := 'Eric Grange (DWScript)';
end;

function TgsJsonImplDwsJsonFactory.getTitle: string;
begin
  result := 'dwsJSON';
end;

function TgsJsonImplDwsJsonFactory.getDesc: string;
begin
  result := '';
end;

function TgsJsonImplDwsJsonFactory.getId: string;
begin
  result := 'dwsjson';
end;

function TgsJsonImplDwsJsonFactory.getJson: igsJson;
begin
  result := TgsJsonImplDwsJson.Create;
end;

initialization

addImplementation(TgsJsonImplDwsJsonFactory.Create);

end.
