///*******************************************************
///
/// JsonLibsTests
///
/// 2026-2027 Grid System SAS
///
///
///*******************************************************

unit gs.json.impl.json4Delphi;

interface

uses sysutils,
     classes,
     gs.Json,
     Jsons;

type

TgsJsonImplJson4Delphi = class(TInterfacedObject, igsJson)
private
protected
  FJson : TJson;
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

TgsJsonImplJson4DelphiFactory = class(TInterfacedObject, igsJsonFactory)
  function getAuthor : string;
  function getTitle : string;
  function getDesc : string;
  function getId : string;
  function getJson : igsJson;
end;

implementation

// ---------------------------------------------------------------------------
// Helper : TJsonValueType -> TgsJsonElementType
// ---------------------------------------------------------------------------
function valueTypeToElementType(aType : TJsonValueType) : TgsJsonElementType;
begin
  case aType of
    jvNone    : result := TgsJsonElementType.etEmpty;
    jvNull    : result := TgsJsonElementType.etNull;
    jvString  : result := TgsJsonElementType.etString;
    jvNumber  : result := TgsJsonElementType.etNumber;
    jvBoolean : result := TgsJsonElementType.etBoolean;
    jvObject  : result := TgsJsonElementType.etJson;
    jvArray   : result := TgsJsonElementType.etJsonArray;
  else
    result := TgsJsonElementType.etEmpty;
  end;
end;

// ---------------------------------------------------------------------------
// Helper : TJsonStructType -> TgsJsonElementType
// ---------------------------------------------------------------------------
function structTypeToElementType(aJson : TJson) : TgsJsonElementType;
begin
  if aJson = nil then begin
    result := TgsJsonElementType.etEmpty;
    exit;
  end;
  case aJson.StructType of
    jsObject : result := TgsJsonElementType.etJson;
    jsArray  : result := TgsJsonElementType.etJsonArray;
  else
    result := TgsJsonElementType.etEmpty;
  end;
end;

// ---------------------------------------------------------------------------
// Helper : ensure FJson is in Object mode (jsObject)
// Uses TJson.CreateObjectIfNone logic by calling Put with a dummy then Delete.
// ---------------------------------------------------------------------------
procedure ensureObject(var FJson : TJson; var FOwned : boolean);
begin
  if FJson = nil then begin
    FJson := TJson.Create;
    FOwned := true;
  end;
  if FJson.StructType = jsObject then
    exit;
  if FJson.StructType = jsNone then begin
    // Force object mode by inserting then deleting a dummy pair
    FJson.Put('__init__', Integer(0));
    FJson.Delete('__init__');
    exit;
  end;
  // Was an array — replace entirely
  if FOwned then
    FJson.Free;
  FJson := TJson.Create;
  FJson.Put('__init__', Integer(0));
  FJson.Delete('__init__');
  FOwned := true;
end;

// ---------------------------------------------------------------------------
// Helper : ensure FJson is in Array mode (jsArray)
// ---------------------------------------------------------------------------
procedure ensureArray(var FJson : TJson; var FOwned : boolean);
begin
  if FJson = nil then begin
    FJson := TJson.Create;
    FOwned := true;
  end;
  if FJson.StructType = jsArray then
    exit;
  if FJson.StructType = jsNone then begin
    // Force array mode: put a value then delete it
    FJson.Put(Integer(0));
    FJson.Delete(0);
    exit;
  end;
  // Was an object — replace entirely
  if FOwned then
    FJson.Free;
  FJson := TJson.Create;
  FJson.Put(Integer(0));
  FJson.Delete(0);
  FOwned := true;
end;

// ---------------------------------------------------------------------------
// Helper : delete a key from a JsonObject if it already exists (avoid dups)
// ---------------------------------------------------------------------------
procedure deleteIfExists(FJson : TJson; const name : string);
var
  idx : integer;
begin
  if (FJson <> nil) and (FJson.StructType = jsObject) then begin
    idx := FJson.JsonObject.Find(name);
    if idx >= 0 then
      FJson.Delete(idx);
  end;
end;

// ---------------------------------------------------------------------------
// Helper : add array-of-const elements to a TJsonArray
// Note: json4delphi TJsonArray.Put accepts Integer, Extended, Boolean, String,
//       TJsonObject, TJsonArray, TJsonValue — no Int64 overload.
//       Int64 values are cast to Integer (truncated if > MaxInt).
// ---------------------------------------------------------------------------
procedure addConstToArray(arr : TJsonArray; const vals : array of const);
var
  i : integer;
begin
  for i := Low(vals) to High(vals) do begin
    case vals[i].VType of
      vtString        : arr.Put(String(vals[i].VString^));
      vtWideString    : arr.Put(String(vals[i].VWideString));
      vtUnicodeString : arr.Put(UnicodeString(vals[i].VUnicodeString));
      vtAnsiString    : arr.Put(String(AnsiString(vals[i].VAnsiString)));
      vtInteger       : arr.Put(vals[i].VInteger);
      System.vtBoolean: arr.Put(vals[i].VBoolean);
      vtExtended      : arr.Put(Extended(vals[i].VExtended^));
      vtInt64         : arr.Put(Integer(vals[i].VInt64^));  // no Int64 overload
      vtCurrency      : arr.Put(Extended(vals[i].VCurrency^));
    end;
  end;
end;

// ---------------------------------------------------------------------------
// Helper : same but targeting TJson in array mode
// ---------------------------------------------------------------------------
procedure addConstToJson(FJson : TJson; const vals : array of const);
var
  i : integer;
begin
  for i := Low(vals) to High(vals) do begin
    case vals[i].VType of
      vtString        : FJson.Put(String(vals[i].VString^));
      vtWideString    : FJson.Put(String(vals[i].VWideString));
      vtUnicodeString : FJson.Put(UnicodeString(vals[i].VUnicodeString));
      vtAnsiString    : FJson.Put(String(AnsiString(vals[i].VAnsiString)));
      vtInteger       : FJson.Put(vals[i].VInteger);
      System.vtBoolean: FJson.Put(vals[i].VBoolean);
      vtExtended      : FJson.Put(Extended(vals[i].VExtended^));
      vtInt64         : FJson.Put(Integer(vals[i].VInt64^));
      vtCurrency      : FJson.Put(Extended(vals[i].VCurrency^));
    end;
  end;
end;

// ---------------------------------------------------------------------------
// Helper : assign a parsed TJson sub-value into an igsJson wrapper (owned)
// ---------------------------------------------------------------------------
procedure wrapSubJson(const jsonStr : string; var value : igsJson);
var
  wrapper : TJson;
begin
  wrapper := TJson.Create;
  try
    wrapper.Parse(jsonStr);
  except
    wrapper.Free;
    raise;
  end;
  if not assigned(value) then
    value := TgsJsonImplJson4Delphi.Create;
  if TgsJsonImplJson4Delphi(value).FOwned and
     (TgsJsonImplJson4Delphi(value).FJson <> nil) then
    TgsJsonImplJson4Delphi(value).FJson.Free;
  TgsJsonImplJson4Delphi(value).FJson  := wrapper;
  TgsJsonImplJson4Delphi(value).FOwned := true;
end;

{ TgsJsonImplJson4Delphi }

constructor TgsJsonImplJson4Delphi.Create;
begin
  FJson := nil;
  FOwned := true;
end;

destructor TgsJsonImplJson4Delphi.Destroy;
begin
  if FOwned and (FJson <> nil) then
    FreeAndNil(FJson);
  inherited;
end;

function TgsJsonImplJson4Delphi.parse(aJsonStr: string): igsJson;
var
  trimmed : string;
begin
  result := self;
  if FOwned and (FJson <> nil) then
    FreeAndNil(FJson);
  trimmed := Trim(aJsonStr);
  if trimmed = '' then
    raise JsonException.Create('Empty JSON string');
  // TJson.Parse only accepts object {} or array []
  if (trimmed[1] <> '{') and (trimmed[1] <> '[') then
    raise JsonException.Create('json4Delphi: only object or array root supported, got: ' + trimmed);
  FJson := TJson.Create;
  try
    FJson.Parse(trimmed);
  except
    on E: Exception do begin
      FreeAndNil(FJson);
      raise JsonException.Create('json4Delphi parse error: ' + E.Message);
    end;
  end;
  FOwned := true;
end;

function TgsJsonImplJson4Delphi.put(name: string; val: double): igsJson;
begin
  result := self;
  ensureObject(FJson, FOwned);
  deleteIfExists(FJson, name);
  FJson.Put(name, Extended(val));
end;

function TgsJsonImplJson4Delphi.put(name, val: string): igsJson;
begin
  result := self;
  ensureObject(FJson, FOwned);
  deleteIfExists(FJson, name);
  FJson.Put(name, val);
end;

function TgsJsonImplJson4Delphi.put(name: string; val: boolean): igsJson;
begin
  result := self;
  ensureObject(FJson, FOwned);
  deleteIfExists(FJson, name);
  FJson.Put(name, val);
end;

function TgsJsonImplJson4Delphi.put(vals: array of const): igsJson;
begin
  result := self;
  ensureArray(FJson, FOwned);
  addConstToJson(FJson, vals);
end;

function TgsJsonImplJson4Delphi.put(name: string; vals: array of const): igsJson;
var
  subArr : TJsonArray;
begin
  result := self;
  ensureObject(FJson, FOwned);
  deleteIfExists(FJson, name);
  // Build a TJsonArray, fill it, then assign via Put(name, TJsonArray)
  subArr := TJsonArray.Create(nil);
  try
    addConstToArray(subArr, vals);
    FJson.Put(name, subArr);
  finally
    subArr.Free;
  end;
end;

function TgsJsonImplJson4Delphi.put(name: string; val: igsJson): igsJson;
var
  sub : TJson;
  js  : string;
begin
  result := self;
  ensureObject(FJson, FOwned);
  deleteIfExists(FJson, name);
  js := val.stringify;
  sub := TJson.Create;
  try
    sub.Parse(js);
    FJson.Put(name, sub);
  finally
    sub.Free;
  end;
end;

function TgsJsonImplJson4Delphi.put(val: igsJson): igsJson;
var
  sub : TJson;
  js  : string;
begin
  result := self;
  ensureArray(FJson, FOwned);
  js := val.stringify;
  sub := TJson.Create;
  try
    sub.Parse(js);
    FJson.Put(sub);
  finally
    sub.Free;
  end;
end;

function TgsJsonImplJson4Delphi.stringify(var aStr: string): igsJson;
begin
  result := self;
  if FJson <> nil then
    aStr := FJson.Stringify
  else
    aStr := 'null';
end;

function TgsJsonImplJson4Delphi.stringify: string;
begin
  if FJson <> nil then
    result := FJson.Stringify
  else
    result := 'null';
end;

function TgsJsonImplJson4Delphi.get(name: string; var value: string): igsJson;
begin
  result := self;
  if (FJson = nil) or (FJson.StructType <> jsObject) then
    raise JsonException.Create('TgsJsonImplJson4Delphi.get: Not an object');
  if FJson.JsonObject.Find(name) < 0 then
    raise JsonException.Create('TgsJsonImplJson4Delphi.get: Key not found: ' + name);
  value := FJson.Get(name).AsString;
end;

function TgsJsonImplJson4Delphi.get(index: integer; var value: string): igsJson;
begin
  result := self;
  if FJson = nil then
    raise JsonException.Create('TgsJsonImplJson4Delphi.get: JSON is nil');
  assert(index < FJson.Count);
  value := FJson.Get(index).AsString;
end;

function TgsJsonImplJson4Delphi.get(name: string; var value: integer): igsJson;
begin
  result := self;
  if (FJson = nil) or (FJson.StructType <> jsObject) then
    raise JsonException.Create('TgsJsonImplJson4Delphi.get: Not an object');
  value := FJson.Get(name).AsInteger;
end;

function TgsJsonImplJson4Delphi.get(index: integer; var value: integer): igsJson;
begin
  result := self;
  if FJson = nil then
    raise JsonException.Create('TgsJsonImplJson4Delphi.get: JSON is nil');
  assert(index < FJson.Count);
  value := FJson.Get(index).AsInteger;
end;

function TgsJsonImplJson4Delphi.get(name: string; var value: Double): igsJson;
begin
  result := self;
  if (FJson = nil) or (FJson.StructType <> jsObject) then
    raise JsonException.Create('TgsJsonImplJson4Delphi.get: Not an object');
  value := Double(FJson.Get(name).AsNumber);
end;

function TgsJsonImplJson4Delphi.get(index: integer; var value: Double): igsJson;
begin
  result := self;
  if FJson = nil then
    raise JsonException.Create('TgsJsonImplJson4Delphi.get: JSON is nil');
  assert(index < FJson.Count);
  value := Double(FJson.Get(index).AsNumber);
end;

function TgsJsonImplJson4Delphi.get(name: string; var value: Boolean): igsJson;
begin
  result := self;
  if (FJson = nil) or (FJson.StructType <> jsObject) then
    raise JsonException.Create('TgsJsonImplJson4Delphi.get: Not an object');
  value := FJson.Get(name).AsBoolean;
end;

function TgsJsonImplJson4Delphi.get(index: integer; var value: Boolean): igsJson;
begin
  result := self;
  if FJson = nil then
    raise JsonException.Create('TgsJsonImplJson4Delphi.get: JSON is nil');
  assert(index < FJson.Count);
  value := FJson.Get(index).AsBoolean;
end;

function TgsJsonImplJson4Delphi.get(name: string; var value: igsJson): igsJson;
var
  v : TJsonValue;
begin
  result := self;
  if (FJson = nil) or (FJson.StructType <> jsObject) then
    raise JsonException.Create('TgsJsonImplJson4Delphi.get: Not an object');
  if FJson.JsonObject.Find(name) < 0 then
    raise JsonException.Create('TgsJsonImplJson4Delphi.get: Key not found: ' + name);
  v := FJson.Get(name);
  if not (v.ValueType in [jvObject, jvArray]) then
    raise JsonException.Create('TgsJsonImplJson4Delphi.get: Value is not object/array for key: ' + name);
  wrapSubJson(v.Stringify, value);
end;

function TgsJsonImplJson4Delphi.get(index: integer; var value: igsJson): igsJson;
var
  v : TJsonValue;
begin
  result := self;
  if FJson = nil then
    raise JsonException.Create('TgsJsonImplJson4Delphi.get: JSON is nil');
  assert(index < FJson.Count);
  v := FJson.Get(index);
  if not (v.ValueType in [jvObject, jvArray]) then
    raise JsonException.Create('TgsJsonImplJson4Delphi.get: Value at index ' + IntToStr(index) + ' is not object/array');
  wrapSubJson(v.Stringify, value);
end;

function TgsJsonImplJson4Delphi.jsonElementCount: integer;
begin
  if FJson <> nil then
    result := FJson.Count
  else
    result := -1;
end;

function TgsJsonImplJson4Delphi.jsonElementType(index: integer): TgsJsonElementType;
begin
  result := TgsJsonElementType.etEmpty;
  if FJson = nil then
    exit;
  if index >= FJson.Count then
    exit;
  result := valueTypeToElementType(FJson.Get(index).ValueType);
end;

function TgsJsonImplJson4Delphi.jsonType: TgsJsonElementType;
begin
  result := structTypeToElementType(FJson);
end;

function TgsJsonImplJson4Delphi.jsonElementName(index: integer): string;
begin
  result := '';
  if (FJson = nil) or (FJson.StructType <> jsObject) then
    raise JsonException.Create('TgsJsonImplJson4Delphi.jsonElementName: Not an object');
  assert(index < FJson.JsonObject.Count);
  result := FJson.JsonObject.Items[index].Name;
end;

function TgsJsonImplJson4Delphi.clear: igsJson;
begin
  result := self;
  if FOwned and (FJson <> nil) then
    FreeAndNil(FJson);
  FJson := nil;
  FOwned := true;
end;

function TgsJsonImplJson4Delphi.asString(name: String): string;
begin
  get(name, result);
end;

function TgsJsonImplJson4Delphi.asInteger(name: String): integer;
begin
  get(name, result);
end;

function TgsJsonImplJson4Delphi.asNumber(name: String): double;
begin
  get(name, result);
end;

function TgsJsonImplJson4Delphi.asBoolean(name: String): Boolean;
begin
  get(name, result);
end;

function TgsJsonImplJson4Delphi.asObj(name: String): igsJson;
begin
  result := nil;
  get(name, result);
end;

function TgsJsonImplJson4Delphi.asObj(index: integer): igsJson;
begin
  result := nil;
  get(index, result);
end;

function TgsJsonImplJson4Delphi.add(val: igsJson): igsJson;
var
  sub : TJson;
  js  : string;
begin
  result := self;
  ensureArray(FJson, FOwned);
  js := val.stringify;
  sub := TJson.Create;
  try
    sub.Parse(js);
    FJson.Put(sub);
  finally
    sub.Free;
  end;
end;

function TgsJsonImplJson4Delphi.add(val: double): igsJson;
begin
  result := self;
  ensureArray(FJson, FOwned);
  FJson.Put(Extended(val));
end;

function TgsJsonImplJson4Delphi.add(val: integer): igsJson;
begin
  result := self;
  ensureArray(FJson, FOwned);
  FJson.Put(val);
end;

function TgsJsonImplJson4Delphi.add(val: string): igsJson;
begin
  result := self;
  ensureArray(FJson, FOwned);
  FJson.Put(val);
end;

function TgsJsonImplJson4Delphi.add(val: byte): igsJson;
begin
  result := self;
  ensureArray(FJson, FOwned);
  FJson.Put(Integer(val));
end;

function TgsJsonImplJson4Delphi.add(val: boolean): igsJson;
begin
  result := self;
  ensureArray(FJson, FOwned);
  FJson.Put(val);
end;

function TgsJsonImplJson4Delphi.isNameExists(name: String): boolean;
begin
  result := false;
  if (FJson <> nil) and (FJson.StructType = jsObject) then
    result := FJson.JsonObject.Find(name) >= 0;
end;

function TgsJsonImplJson4Delphi.ToObj: igsJson;
begin
  result := self;
  ensureObject(FJson, FOwned);
end;

function TgsJsonImplJson4Delphi.ToArray: igsJson;
begin
  result := self;
  ensureArray(FJson, FOwned);
end;

{ TgsJsonImplJson4DelphiFactory }

function TgsJsonImplJson4DelphiFactory.getAuthor: string;
begin
  result := 'Randolph (json4delphi)';
end;

function TgsJsonImplJson4DelphiFactory.getTitle: string;
begin
  result := 'json4delphi (Jsons)';
end;

function TgsJsonImplJson4DelphiFactory.getDesc: string;
begin
  result := 'json4delphi wrapper - TJson based implementation';
end;

function TgsJsonImplJson4DelphiFactory.getId: string;
begin
  result := 'json4delphi';
end;

function TgsJsonImplJson4DelphiFactory.getJson: igsJson;
begin
  result := TgsJsonImplJson4Delphi.Create;
end;

initialization

addImplementation(TgsJsonImplJson4DelphiFactory.Create);

end.
