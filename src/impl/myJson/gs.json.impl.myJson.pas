///*******************************************************
///
/// JsonLibsTests
///
/// 2026-2027 Grid System SAS
///
///
///*******************************************************

unit gs.json.impl.myJson;

interface

uses sysutils,
     classes,
     gs.Json,
     uJSON;

type

TgsJsonImplMyJson = class(TInterfacedObject, igsJson)
private
protected
  FJson : myJSONItem;
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

TgsJsonImplMyJsonFactory = class(TInterfacedObject, igsJsonFactory)
  function getAuthor : string;
  function getTitle : string;
  function getDesc : string;
  function getId : string;
  function getJson : igsJson;
end;

implementation

// Convert myJSONItem type info to TgsJsonElementType.
// Since fValType is private in myJSONItem, we deduce the value sub-type
// from the serialized output of getJSON:
//   vtText    -> "value"  (starts with '"')
//   vtNumber  -> 42 / 3.14 (starts with digit or sign)
//   vtBoolean -> true / false (starts with 't' or 'f')
//   vtNull    -> null (starts with 'n')
function itemToElementType(aItem : myJSONItem) : TgsJsonElementType;
var
  s : string;
begin
  result := TgsJsonElementType.etEmpty;
  if aItem = nil then
    exit;
  case aItem.getType of
    dtUnset : result := TgsJsonElementType.etEmpty;
    dtObject : result := TgsJsonElementType.etJson;
    dtArray : result := TgsJsonElementType.etJsonArray;
    dtValue : begin
      if aItem.isNull then
        result := TgsJsonElementType.etNull
      else begin
        // Use getJSON to inspect serialized form and deduce sub-type
        s := aItem.getJSON;
        if Length(s) = 0 then
          result := TgsJsonElementType.etEmpty
        else if s[1] = '"' then
          result := TgsJsonElementType.etString
        else if (s = 'true') or (s = 'false') then
          result := TgsJsonElementType.etBoolean
        else if (s = 'null') then
          result := TgsJsonElementType.etNull
        else
          // Must be a number (digits, sign, decimal)
          result := TgsJsonElementType.etNumber;
      end;
    end;
  end;
end;

// Extract a child myJSONItem into an igsJson wrapper without taking ownership.
// The child remains owned by its parent myJSONItem.
procedure extractValue(source : myJSONItem; var value : igsJson);
begin
  if not assigned(value) then
    value := TgsJsonImplMyJson.Create;

  // If the wrapper currently owns its FJson, free it before replacing
  if TgsJsonImplMyJson(value).FOwned and (TgsJsonImplMyJson(value).FJson <> nil) then
    TgsJsonImplMyJson(value).FJson.Free;
  TgsJsonImplMyJson(value).FJson := source;
  TgsJsonImplMyJson(value).FOwned := false;
end;

// Ensure the internal item is an object; if not, replace it.
procedure ensureObject(var FJson : myJSONItem; var FOwned : boolean);
begin
  if FJson.getType <> dtObject then begin
    if FOwned and (FJson <> nil) then
      FJson.Free;
    FJson := myJSONItem.Create;
    FJson.setType(dtObject);
    FOwned := true;
  end;
end;

// Ensure the internal item is an array; if not, replace it.
procedure ensureArray(var FJson : myJSONItem; var FOwned : boolean);
begin
  if FJson.getType <> dtArray then begin
    if FOwned and (FJson <> nil) then
      FJson.Free;
    FJson := myJSONItem.Create;
    FJson.setType(dtArray);
    FOwned := true;
  end;
end;

// Add array-of-const values to a myJSONItem that is already an array.
procedure addArrayValues(arr : myJSONItem; const vals : array of const);
var
  idx : integer;
begin
  idx := arr.Count;
  for var i := Low(vals) to High(vals) do begin
    case vals[i].VType of
      System.vtString : arr.Value[idx].setStr(String(vals[i].VString^));
      System.vtWideString : arr.Value[idx].setStr(String(vals[i].VWideString));
      System.vtUnicodeString : arr.Value[idx].setStr(UnicodeString(vals[i].VUnicodeString));
      System.vtInteger : arr.Value[idx].setInt(vals[i].VInteger);
      System.vtBoolean : arr.Value[idx].setBool(vals[i].VBoolean);
      System.vtExtended : arr.Value[idx].setNum(vals[i].VExtended^);
    end;
    Inc(idx);
  end;
end;

{ TgsJsonImplMyJson }

constructor TgsJsonImplMyJson.Create;
begin
  FJson := myJSONItem.Create;
  FOwned := true;
end;

destructor TgsJsonImplMyJson.Destroy;
begin
  if FOwned and (FJson <> nil) then
    FreeAndNil(FJson);
  inherited;
end;

function TgsJsonImplMyJson.parse(aJsonStr: string): igsJson;
begin
  result := self;
  if FOwned and (FJson <> nil) then
    FreeAndNil(FJson);
  FJson := myJSONItem.Create;
  FOwned := true;
  var trimmed := aJsonStr.Trim;
  if trimmed = '' then
    raise JsonException.Create('Empty JSON string');
  FJson.Code := trimmed;
end;

function TgsJsonImplMyJson.put(name: string; val: double): igsJson;
begin
  result := self;
  ensureObject(FJson, FOwned);
  // myJSONItem['key'] auto-creates child and forces dtObject on parent
  FJson[name].setNum(val);
end;

function TgsJsonImplMyJson.put(name, val: string): igsJson;
begin
  result := self;
  ensureObject(FJson, FOwned);
  FJson[name].setStr(val);
end;

function TgsJsonImplMyJson.put(name: string; val: boolean): igsJson;
begin
  result := self;
  ensureObject(FJson, FOwned);
  FJson[name].setBool(val);
end;

function TgsJsonImplMyJson.put(vals: array of const): igsJson;
begin
  result := self;
  ensureArray(FJson, FOwned);
  addArrayValues(FJson, vals);
end;

function TgsJsonImplMyJson.put(name: string; vals: array of const): igsJson;
begin
  result := self;
  ensureObject(FJson, FOwned);
  // Create a child array under the given key
  var child := FJson[name];
  child.setType(dtArray);
  addArrayValues(child, vals);
end;

function TgsJsonImplMyJson.put(name: string; val: igsJson): igsJson;
begin
  result := self;
  ensureObject(FJson, FOwned);
  // Re-parse the stringified JSON into a child under the given key
  FJson[name].Code := val.stringify;
end;

function TgsJsonImplMyJson.put(val: igsJson): igsJson;
begin
  result := self;
  ensureArray(FJson, FOwned);
  var idx := FJson.Count;
  FJson.Value[idx].Code := val.stringify;
end;

function TgsJsonImplMyJson.stringify(var aStr: string): igsJson;
begin
  result := self;
  if FJson <> nil then
    aStr := FJson.getJSON
  else
    aStr := 'null';
end;

function TgsJsonImplMyJson.stringify: string;
begin
  if FJson <> nil then
    result := FJson.getJSON
  else
    result := 'null';
end;

function TgsJsonImplMyJson.get(name: string; var value: string): igsJson;
begin
  result := self;
  if FJson.getType = dtObject then begin
    if not FJson.Has[name] then
      raise JsonException.Create('TgsJsonImplMyJson.get: Key not found: ' + name);
    value := FJson[name].getStr;
  end
  else
    raise Exception.Create('TgsJsonImplMyJson.get: Not an object');
end;

function TgsJsonImplMyJson.get(index: integer; var value: string): igsJson;
begin
  result := self;
  if FJson.getType = dtObject then begin
    assert(index < FJson.Count);
    value := FJson.Value[index].getStr;
  end
  else if FJson.getType = dtArray then begin
    assert(index < FJson.Count);
    value := FJson.Value[index].getStr;
  end;
end;

function TgsJsonImplMyJson.get(name: string; var value: integer): igsJson;
begin
  result := self;
  if FJson.getType = dtObject then begin
    if not FJson.Has[name] then
      raise JsonException.Create('TgsJsonImplMyJson.get: Key not found: ' + name);
    value := FJson[name].getInt;
  end
  else
    raise JsonException.Create('TgsJsonImplMyJson.get: Not an object');
end;

function TgsJsonImplMyJson.get(index: integer; var value: integer): igsJson;
begin
  result := self;
  if FJson.getType = dtObject then begin
    assert(index < FJson.Count);
    value := FJson.Value[index].getInt;
  end
  else if FJson.getType = dtArray then begin
    assert(index < FJson.Count);
    value := FJson.Value[index].getInt;
  end;
end;

function TgsJsonImplMyJson.get(name: string; var value: Double): igsJson;
begin
  result := self;
  if FJson.getType = dtObject then begin
    if not FJson.Has[name] then
      raise JsonException.Create('TgsJsonImplMyJson.get: Key not found: ' + name);
    value := FJson[name].getNum;
  end
  else
    raise JsonException.Create('TgsJsonImplMyJson.get: Not an object');
end;

function TgsJsonImplMyJson.get(index: integer; var value: Double): igsJson;
begin
  result := self;
  if FJson.getType = dtObject then begin
    assert(index < FJson.Count);
    value := FJson.Value[index].getNum;
  end
  else if FJson.getType = dtArray then begin
    assert(index < FJson.Count);
    value := FJson.Value[index].getNum;
  end;
end;

function TgsJsonImplMyJson.get(name: string; var value: Boolean): igsJson;
begin
  result := self;
  if FJson.getType = dtObject then begin
    if not FJson.Has[name] then
      raise JsonException.Create('TgsJsonImplMyJson.get: Key not found: ' + name);
    value := FJson[name].getBool;
  end
  else
    raise JsonException.Create('TgsJsonImplMyJson.get: Not an object');
end;

function TgsJsonImplMyJson.get(index: integer; var value: Boolean): igsJson;
begin
  result := self;
  if FJson.getType = dtObject then begin
    assert(index < FJson.Count);
    value := FJson.Value[index].getBool;
  end
  else if FJson.getType = dtArray then begin
    assert(index < FJson.Count);
    value := FJson.Value[index].getBool;
  end;
end;

function TgsJsonImplMyJson.get(name: string; var value: igsJson): igsJson;
begin
  result := self;
  if FJson.getType = dtObject then begin
    if not FJson.Has[name] then
      raise JsonException.Create('TgsJsonImplMyJson.get: Key not found: ' + name);
    var child := FJson[name]; // child is owned by FJson
    extractValue(child, value);
  end
  else
    raise JsonException.Create('TgsJsonImplMyJson.get: Not an object');
end;

function TgsJsonImplMyJson.get(index: integer; var value: igsJson): igsJson;
begin
  result := self;
  if FJson.getType = dtObject then begin
    assert(index < FJson.Count);
    extractValue(FJson.Value[index], value);
  end
  else if FJson.getType = dtArray then begin
    assert(index < FJson.Count);
    extractValue(FJson.Value[index], value);
  end;
end;

function TgsJsonImplMyJson.jsonElementCount: integer;
begin
  if (FJson.getType = dtObject) or (FJson.getType = dtArray) then
    result := FJson.Count
  else
    result := -1;
end;

function TgsJsonImplMyJson.jsonElementType(index: integer): TgsJsonElementType;
begin
  result := TgsJsonElementType.etEmpty;
  if (FJson.getType = dtObject) or (FJson.getType = dtArray) then begin
    var child := FJson.Value[index];
    result := itemToElementType(child);
  end;
end;

function TgsJsonImplMyJson.jsonType: TgsJsonElementType;
begin
  result := itemToElementType(FJson);
end;

function TgsJsonImplMyJson.jsonElementName(index: integer): string;
begin
  result := '';
  if FJson.getType = dtObject then begin
    assert(index < FJson.Count);
    result := FJson.Key[index];
  end
  else
    raise JsonException.Create('TgsJsonImplMyJson.jsonElementName: Not an object');
end;

function TgsJsonImplMyJson.clear: igsJson;
begin
  result := self;
  if FOwned and (FJson <> nil) then
    FreeAndNil(FJson);
  FJson := myJSONItem.Create;
  FOwned := true;
end;

function TgsJsonImplMyJson.asString(name: String): string;
begin
  get(name, result);
end;

function TgsJsonImplMyJson.asInteger(name: String): integer;
begin
  get(name, result);
end;

function TgsJsonImplMyJson.asNumber(name: String): double;
begin
  get(name, result);
end;

function TgsJsonImplMyJson.asBoolean(name: String): Boolean;
begin
  get(name, result);
end;

function TgsJsonImplMyJson.asObj(name: String): igsJson;
begin
  get(name, result);
end;

function TgsJsonImplMyJson.asObj(index: integer): igsJson;
begin
  get(index, result);
end;

function TgsJsonImplMyJson.add(val: igsJson): igsJson;
begin
  result := self;
  ensureArray(FJson, FOwned);
  var idx := FJson.Count;
  FJson.Value[idx].Code := val.stringify;
end;

function TgsJsonImplMyJson.add(val: double): igsJson;
begin
  result := self;
  ensureArray(FJson, FOwned);
  var idx := FJson.Count;
  FJson.Value[idx].setNum(val);
end;

function TgsJsonImplMyJson.add(val: integer): igsJson;
begin
  result := self;
  ensureArray(FJson, FOwned);
  var idx := FJson.Count;
  FJson.Value[idx].setInt(val);
end;

function TgsJsonImplMyJson.add(val: string): igsJson;
begin
  result := self;
  ensureArray(FJson, FOwned);
  var idx := FJson.Count;
  FJson.Value[idx].setStr(val);
end;

function TgsJsonImplMyJson.add(val: byte): igsJson;
begin
  result := self;
  ensureArray(FJson, FOwned);
  var idx := FJson.Count;
  FJson.Value[idx].setInt(Integer(val));
end;

function TgsJsonImplMyJson.add(val: boolean): igsJson;
begin
  result := self;
  ensureArray(FJson, FOwned);
  var idx := FJson.Count;
  FJson.Value[idx].setBool(val);
end;

function TgsJsonImplMyJson.isNameExists(name: String): boolean;
begin
  result := false;
  if FJson.getType = dtObject then
    result := FJson.Has[name];
end;

function TgsJsonImplMyJson.ToObj: igsJson;
begin
  result := self;
  if FJson.getType <> dtObject then begin
    if FOwned and (FJson <> nil) then FJson.Free;
    FJson := myJSONItem.Create;
    FJson.setType(dtObject);
    FOwned := true;
  end;
end;

function TgsJsonImplMyJson.ToArray: igsJson;
begin
  result := self;
  if FJson.getType <> dtArray then begin
    if FOwned and (FJson <> nil) then FJson.Free;
    FJson := myJSONItem.Create;
    FJson.setType(dtArray);
    FOwned := true;
  end;
end;

{ TgsJsonImplMyJsonFactory }

function TgsJsonImplMyJsonFactory.getAuthor: string;
begin
  result := '';
end;

function TgsJsonImplMyJsonFactory.getTitle: string;
begin
  result := 'myJSON';
end;

function TgsJsonImplMyJsonFactory.getDesc: string;
begin
  result := 'Lightweight single-class JSON parser';
end;

function TgsJsonImplMyJsonFactory.getId: string;
begin
  result := 'myjson';
end;

function TgsJsonImplMyJsonFactory.getJson: igsJson;
begin
  result := TgsJsonImplMyJson.Create;
end;

initialization

addImplementation(TgsJsonImplMyJsonFactory.Create);

end.
